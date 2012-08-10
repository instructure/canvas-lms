#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class WikiPage < ActiveRecord::Base
  attr_accessible :title, :body, :url, :user_id, :hide_from_students, :editing_roles, :notify_of_update
  attr_readonly :wiki_id
  validates_length_of :body, :maximum => maximum_long_text_length, :allow_nil => true, :allow_blank => true
  validates_presence_of :wiki_id
  include Workflow
  include HasContentTags
  include CopyAuthorizedLinks
  include ContextModuleItem
  
  belongs_to :wiki, :touch => true
  belongs_to :wiki_with_participants, :class_name => 'Wiki', :foreign_key => 'wiki_id', :include => {:wiki_namespaces => :context }
  belongs_to :cloned_item
  belongs_to :user
  has_many :wiki_page_comments, :order => "created_at DESC"
  acts_as_url :title, :scope => [:wiki_id, :not_deleted], :sync_url => true
  
  before_save :set_revised_at
  before_validation :ensure_unique_title
  
  TITLE_LENGTH = WikiPage.columns_hash['title'].limit rescue 255
  
  def ensure_unique_title
    return if deleted?
    self.title ||= (self.url || "page").to_cased_title
    return unless self.wiki
    # TODO i18n (see wiki.rb)
    if self.title == "Front Page" && self.new_record?
      baddies = self.wiki.wiki_pages.not_deleted.find_all_by_title("Front Page").select{|p| p.url != "front-page" }
      baddies.each{|p| p.title = p.url.to_cased_title; p.save_without_broadcasting! }
    end
    if existing = self.wiki.wiki_pages.not_deleted.find_by_title(self.title)
      return if existing == self
      real_title = self.title.gsub(/-(\d*)\z/, '') # remove any "-#" at the end
      n = $1 ? $1.to_i + 1 : 2
      begin
        mod = "-#{n}"
        new_title = real_title[0...(TITLE_LENGTH - mod.length)] + mod
        n = n.succ
      end while self.wiki.wiki_pages.not_deleted.find_by_title(new_title)
      
      self.title = new_title
    end
  end
  
  def ensure_unique_url
    url_attribute = self.class.url_attribute
    base_url = self.send(url_attribute)
    base_url = self.send(self.class.attribute_to_urlify).to_s.to_url if base_url.blank? || !self.only_when_blank
    conditions = [wildcard("#{url_attribute}", base_url, :type => :right)]
    unless new_record?
      conditions.first << " and id != ?"
      conditions << id
    end
    # make stringex scoping a little more useful/flexible... in addition to
    # the normal constructed attribute scope(s), it also supports paramater-
    # less named_scopeds. note that there needs to be an instance_method of
    # the same name for this to work
    scopes = self.class.scope_for_url ? Array(self.class.scope_for_url) : []
    base_scope = self.class
    scopes.each do |scope|
      next unless self.respond_to?(scope)
      if base_scope.respond_to?(scope)
        return unless send(scope)
        base_scope = base_scope.send(scope)
      else
        conditions.first << " and #{connection.quote_column_name(scope)} = ?"
        conditions << send(scope)
      end
    end
    url_owners = base_scope.find(:all, :conditions => conditions)
    # This is the part in stringex that messed us up, since it will never allow
    # a url of "front-page" once "front-page-1" or "front-page-2" is created
    # We modify it to allow "front-page" and start the indexing at "front-page-2"
    # instead of "front-page-1"
    if url_owners.size > 0 && url_owners.detect{|u| u.send(url_attribute) == base_url}
      n = 2
      while url_owners.detect{|u| u.send(url_attribute) == "#{base_url}-#{n}"}
        n = n.succ
      end
      write_attribute url_attribute, "#{base_url}-#{n}"
    else
      write_attribute url_attribute, base_url
    end
  end

  sanitize_field :body, Instructure::SanitizeField::SANITIZE
  copy_authorized_links(:body) { [self.current_namespace(self.user).context, self.user] }
  
  validates_each :title do |record, attr, value|
    if value.blank?
      record.errors.add(attr, t('errors.blank_title', "Title can't be blank"))
    elsif value.size > maximum_string_length
      record.errors.add(attr, t('errors.title_too_long', "Title can't exceed %{max_characters} characters", :max_characters => maximum_string_length))
    elsif value.to_url.blank?
      record.errors.add(attr, t('errors.title_characters', "Title must contain at least one letter or number")) # it's a bit more liberal than this, but let's not complicate things
    end
  end
  
  has_a_broadcast_policy
  simply_versioned
  after_save :remove_changed_flag
  
  workflow do
    state :active
    state :post_delayed do
      event :delayed_post, :transitions_to => :active
    end
    
    state :deleted
    
  end
  
  def restore
    self.workflow_state = 'active'
    self.save
  end
  
  def set_revised_at
    self.revised_at ||= Time.now
    self.revised_at = Time.now if self.body_changed?
    @page_changed = self.body_changed? || self.title_changed?
    true
  end
  
  def notify_of_update=(val)
    @wiki_page_changed = (val == '1' || val == true)
  end
  
  def notify_of_update
    false
  end
  
  def remove_changed_flag
    @wiki_page_changed = false
  end
  
  def version_history
    self.versions.map(&:model)
  end
  
  named_scope :active, lambda{
    {:conditions => ['wiki_pages.workflow_state = ?', 'active'] }
  }
  
  named_scope :deleted_last, lambda{
    {:order => "workflow_state = 'deleted'" }
  }

  named_scope :not_deleted, lambda{
    {:conditions => ['wiki_pages.workflow_state <> ?', 'deleted'] }
  }
  def not_deleted
    !deleted?
  end

  attr_writer :current_namespace
  
  def current_namespace(user=nil)
    @current_namespace ||= self.default_namespace_for(user) || self.wiki.wiki_namespaces.first
  end
  
  def default_namespace_for(user)
    return nil unless user
    namespaces = self.wiki.wiki_namespaces.to_a
    res = namespaces.find do |n|
      n.context.teachers.include?(user) rescue false
    end
    res ||= namespaces.find do |n|
      n.context.students.include?(user) rescue false
    end
    res ||= namespaces.find do |n|
      n.context.users.include?(user) rescue false
    end
    res
  end
  
  def locked_for?(context, user, opts={})
    return false unless self.could_be_locked
    Rails.cache.fetch(locked_cache_key(user), :expires_in => 1.minute) do
      m = context_module_tag_for(context, user).context_module rescue nil
      locked = false
      if (m && !m.available_for?(user))
        locked = {:asset_string => self.asset_string, :context_module => m.attributes}
      end
      locked
    end
  end
  
  def context_module_tag_for(context, user)
    @tags ||= {}
    user_id = user ? user.id : 0
    # for wiki_pages, context_module_association_id should be the wiki_namespace_id to use
    if context
      @tags[user_id] ||= self.context_module_tags.find_by_context_id_and_context_type(context.id, context.class.to_s) #module_association_id(current_namespace(user).id)
    elsif user
      @tags[user_id] ||= self.context_module_tags.find_by_context_module_association_id(current_namespace(user).id)
    end
  end
  
  def context_module_action(user, context, action)
    tag = self.context_module_tags.find_by_context_id_and_context_type(context.id, context.class.to_s)
    tag.context_module_action(user, action) if tag
  end
  
  set_policy do
    given {|user, session| self.current_namespace(user).grants_right?(user, session, :read) && can_read_page?(user) }
    can :read
    
    given {|user, session| self.current_namespace(user).grants_right?(user, session, :contribute) && can_read_page?(user) }
    can :read

    given {|user, session| self.editing_role?(user) && !self.locked_for?(nil, user) }
    can :read and can :update_content and can :create
    
    given {|user, session| self.current_namespace(user).grants_right?(user, session, :manage) }
    can :create and can :read and can :update and can :delete and can :update_content
    
    given {|user, session| self.current_namespace(user).grants_right?(user, session, :manage_content) }
    can :create and can :read and can :update and can :delete and can :update_content
    
  end
  
  def can_read_page?(user)
    namespace = self.current_namespace(user)
    context = namespace.context
    !hide_from_students || (context.respond_to?(:admins) && context.admins.include?(user))
  end
  
  def editing_role?(user)
    namespace = self.current_namespace(user)
    context = namespace.context
    context_roles = context.default_wiki_editing_roles rescue nil
    roles = (self.editing_roles || context_roles || default_roles).split(",")
    return true if roles.include?('teachers') && context.respond_to?(:teachers) && context.teachers.include?(user)
    return true if !hide_from_students && roles.include?('students') && context.respond_to?(:students) && context.students.include?(user)
    return true if !hide_from_students && roles.include?('members') && context.respond_to?(:users) && context.users.include?(user)
    return true if !hide_from_students && roles.include?('public')
    false
  end
  
  def default_roles
    namespace = self.current_namespace
    if namespace.context.is_a?(Group)
      'members'
    elsif namespace.context.is_a?(Course)
      'teachers'
    else
      'members'
    end
  end
  
  def roles_for_namespace(user)
    namespace = self.current_namespace(user)
    context_roles = namespace.context.default_wiki_editing_roles rescue nil
    (self.editing_roles || context_roles || default_roles).split(",")
  end

  set_broadcast_policy do |p|
    p.dispatch :updated_wiki_page
    p.to { participants }
    p.whenever { |record| 
      record.created_at < Time.now - (30*60) &&
        ((
          record.active? && @wiki_page_changed && record.prior_version
        ) || 
        (
          record.changed_state(:active)
        ))
    }
  end

  def context(user=nil)
    (@context_for_user ||= {})[user] ||= (find_namespace_for_user(user).context rescue nil)
  end
  
  def find_namespace_for_user(user=nil)
    @@namespaces_for_users ||= {}
    return @@namespaces_for_users[user.id] if user && @@namespaces_for_users[user.id]
    return self.wiki.wiki_namespaces.first if self.wiki.wiki_namespaces.count == 1
    res = nil
    self.wiki_with_participants.wiki_namespaces.sort {|a, b| a.id <=> b.id }.each do |n|
      if n.context && !res
        res = n if user && n.context.participants.include?(user)
        @@namespaces_for_users[user.id] = res if res
      end
    end
    res
  end
  
  def participants
    res = []
    self.wiki_with_participants.wiki_namespaces.each do |n|
      if n.context && n.context.available?
        if self.hide_from_students
          res += n.context.participating_admins
        else
          res += n.context.participants
        end
      end
    end
    res.flatten.uniq
  end
    
  def to_atom(opts={})
    context = opts[:context]
    namespace = self.wiki.wiki_namespaces.find_by_context_id(context && context.id) || self.wiki.wiki_namespaces.find(:first)
    prefix = namespace.context_prefix || ""
    Atom::Entry.new do |entry|
      entry.title     = t(:atom_entry_title, "Wiki Page, %{course_or_group_name}: %{page_title}", :course_or_group_name => namespace.context.name, :page_title => self.title)
      entry.authors  << Atom::Person.new(:name => t(:atom_author, "Wiki Page"))
      entry.updated   = self.updated_at
      entry.published = self.created_at
      entry.id        = "tag:#{HostUrl.default_host},#{self.created_at.strftime("%Y-%m-%d")}:/wiki_pages/#{self.feed_code}_#{self.updated_at.strftime("%Y-%m-%d")}"
      entry.links    << Atom::Link.new(:rel => 'alternate', 
                                    :href => "http://#{HostUrl.context_host(namespace.context)}/#{prefix}/wiki/#{self.url}")
      entry.content   = Atom::Content::Html.new(self.body || t('defaults.no_content', "no content"))
    end
  end
  
  def user_name
    (user && user.name) || t('unknown_user_name', "Unknown")
  end
  
  def to_param
    url
  end
  
  def last_revision_at
    res = self.revised_at || self.updated_at
    res = Time.now if res.is_a?(String)
    res
  end
  
  attr_accessor :clone_updated
  def clone_for(context, dup=nil, options={}) #migrate=true)
    options[:migrate] = true if options[:migrate] == nil
    if !self.cloned_item && !self.new_record?
      self.cloned_item ||= ClonedItem.create(:original_item => self)
      self.save!
    end
    existing = context.wiki.wiki_pages.active.find_by_id(self.id)
    existing ||= context.wiki.wiki_pages.active.find_by_cloned_item_id(self.cloned_item_id || 0)
    return existing if existing && !options[:overwrite]
    dup ||= WikiPage.new
    dup = existing if existing && options[:overwrite]
    self.attributes.delete_if{|k,v| [:id, :wiki_id].include?(k.to_sym) }.each do |key, val|
      dup.send("#{key}=", val)
    end
    dup.wiki = context.wiki
    dup.body = context.migrate_content_links(self.body, options[:old_context] || self.context) if options[:migrate]
    context.log_merge_result(t('notices.wiki_page_created', 'Wiki Page "%{title}" created', :title => dup.title))
    context.may_have_links_to_migrate(dup)
    dup.updated_at = Time.now
    dup.clone_updated = true
    dup
  end

  def self.process_migration_course_outline(data, migration)
    outline = data['course_outline'] ? data['course_outline']: nil
    return unless outline
    to_import = migration.to_import 'outline_folders'

    outline['root_folder'] = true
    begin
      import_from_migration(outline.merge({:outline_folders_to_import => to_import}), migration.context)
    rescue
      migration.add_warning("Error importing the course outline.", $!)
    end
  end

  def self.process_migration(data, migration)
    wikis = data['wikis'] ? data['wikis']: []
    wikis.each do |wiki|
      if !wiki
        ErrorReport.log_error(:content_migration, :message => "There was a nil wiki page imported for ContentMigration:#{migration.id}")
        next
      end
      next unless migration.import_object?("wikis", wiki['migration_id'])
      begin
        import_from_migration(wiki, migration.context) if wiki
      rescue
        migration.add_warning("Couldn't import the wiki page \"#{wiki[:title]}\"", $!)
      end
    end
  end
  
  def self.import_from_migration(hash, context, item=nil)
    hash = hash.with_indifferent_access
    item ||= find_by_wiki_id_and_id(context.wiki.id, hash[:id])
    item ||= find_by_wiki_id_and_migration_id(context.wiki.id, hash[:migration_id])
    item ||= context.wiki.wiki_pages.new
    # force the url to be the same as the url_name given, since there are
    # likely other resources in the import that link to that url
    if hash[:url_name].present?
      item.url = hash[:url_name]
      item.only_when_blank = true
    end
    if hash[:root_folder] && ['folder', 'FOLDER_TYPE'].member?(hash[:type])
      front_page = context.wiki.wiki_page
      if front_page.id
        hash[:root_folder] = false
      else
        # If there is no id there isn't a front page yet
        item = front_page
      end
    end
    context.imported_migration_items << item if context.imported_migration_items && item.new_record?
    item.migration_id = hash[:migration_id]
    (hash[:contents] || []).each do |sub_item|
      next if sub_item[:type] == 'embedded_content'
      WikiPage.import_from_migration(sub_item.merge({
        :outline_folders_to_import => hash[:outline_folders_to_import]
      }), context)
    end
    return if hash[:type] && ['folder', 'FOLDER_TYPE'].member?(hash[:type]) && hash[:linked_resource_id]
    allow_save = true
    if hash[:type] == 'linked_resource' || hash[:type] == "URL_TYPE"
      allow_save = false
    elsif ['folder', 'FOLDER_TYPE'].member? hash[:type]
      item.title = hash[:title] unless hash[:root_folder]
      description = ""
      if hash[:header]
        description += hash[:header][:is_html] ? ImportedHtmlConverter.convert(hash[:header][:body] || "", context) : ImportedHtmlConverter.convert_text(hash[:header][:body] || [""], context)
      end
      description += ImportedHtmlConverter.convert(hash[:description], context) if hash[:description]
      contents = ""
      allow_save = false if hash[:migration_id] && hash[:outline_folders_to_import] && !hash[:outline_folders_to_import][hash[:migration_id]]
      hash[:contents].each do |sub_item|
        sub_item = sub_item.with_indifferent_access
        if ['folder', 'FOLDER_TYPE'].member? sub_item[:type]
          obj = context.wiki.wiki_pages.find_by_migration_id(sub_item[:migration_id])
          contents += "  <li><a href='/courses/#{context.id}/wiki/#{obj.url}'>#{obj.title}</a></li>\n" if obj
        elsif sub_item[:type] == 'embedded_content'
          if contents && contents.length > 0
            description += "<ul>\n#{contents}\n</ul>"
            contents = ""
          end
          description += "\n<h2>#{sub_item[:title]}</h2>\n" if sub_item[:title]
          description += ImportedHtmlConverter.convert(sub_item[:description], context) if sub_item[:description]
        elsif sub_item[:type] == 'linked_resource'
          case sub_item[:linked_resource_type]
          when 'TOC_TYPE'
            obj = context.context_modules.find_by_migration_id(sub_item[:linked_resource_id])
            contents += "  <li><a href='/courses/#{context.id}/modules'>#{obj.name}</a></li>\n" if obj
          when 'ASSESSMENT_TYPE'
            obj = context.quizzes.find_by_migration_id(sub_item[:linked_resource_id])
            contents += "  <li><a href='/courses/#{context.id}/quizzes/#{obj.id}'>#{obj.title}</a></li>\n" if obj
          when /PAGE_TYPE|WIKI_TYPE/
            obj = context.wiki.wiki_pages.find_by_migration_id(sub_item[:linked_resource_id])
            contents += "  <li><a href='/courses/#{context.id}/wiki/#{obj.url}'>#{obj.title}</a></li>\n" if obj
          when 'FILE_TYPE'
            file = context.attachments.find_by_migration_id(sub_item[:linked_resource_id])
            if file
              name = sub_item[:linked_resource_title] || file.name
              contents += " <li><a href=\"/courses/#{context.id}/files/#{file.id}/download\">#{name}</a></li>"
            end
          when 'DISCUSSION_TOPIC_TYPE'
            obj = context.discussion_topics.find_by_migration_id(sub_item[:linked_resource_id])
            contents += "  <li><a href='/courses/#{context.id}/discussion_topics/#{obj.id}'>#{obj.title}</a></li>\n" if obj
          when 'URL_TYPE'
            if sub_item['title'] && sub_item['description'] && sub_item['title'] != '' && sub_item['description'] != ''
              contents += " <li><a href='#{sub_item['url']}'>#{sub_item['title']}</a><ul><li>#{sub_item['description']}</li></ul></li>\n"
            else
              contents += " <li><a href='#{sub_item['url']}'>#{sub_item['title'] || sub_item['description']}</a></li>\n"
            end
          end
        end
      end
      description += "<ul>\n#{contents}\n</ul>" if contents && contents.length > 0
      if hash[:footer]
        description += hash[:footer][:is_html] ? ImportedHtmlConverter.convert(hash[:footer][:body] || "", context) : ImportedHtmlConverter.convert_text(hash[:footer][:body] || [""], context)
      end
      item.body = description
      allow_save = false if !description || description.empty?
    elsif hash[:page_type] == 'module_toc'
    elsif hash[:topics]
      item.title = t('title_for_topics_category', '%{category} Topics', :category => hash[:category_name])
      description = "#{hash[:category_description]}"
      description += "\n\n<ul>\n"
      topic_count = 0
      hash[:topics].each do |topic|
        topic = DiscussionTopic.import_from_migration(topic.merge({
          :topics_to_import => hash[:topics_to_import],
          :topic_entries_to_import => hash[:topic_entries_to_import]
        }), context)
        if topic
          topic_count += 1
          description += "  <li><a href='/#{context.class.to_s.downcase.pluralize}/#{context.id}/discussion_topics/#{topic.id}'>#{topic.title}</a></li>\n"
        end
      end
      description += "</ul>"
      item.body = description
      return nil if topic_count == 0
    elsif hash[:title] and hash[:text]
      #it's an actual wiki page
      item.title = hash[:title].presence || item.url.presence || "unnamed page"
      if item.title.length > TITLE_LENGTH
        migration.add_warning(t('warnings.truncated_wiki_title', "The title of the following wiki page was truncated: %{title}", :title => item.title))
        item.title.splice!(0...TITLE_LENGTH) # truncate too-long titles
      end
      item.body = ImportedHtmlConverter.convert(hash[:text] || "", context)
      item.editing_roles = hash[:editing_roles] if hash[:editing_roles].present?
      item.hide_from_students = hash[:hide_from_students] if !hash[:hide_from_students].nil?
      item.notify_of_update = hash[:notify_of_update] if !hash[:notify_of_update].nil?
    else
      allow_save = false
    end
    if allow_save && hash[:migration_id]
      item.save_without_broadcasting!
      context.imported_migration_items << item if context.imported_migration_items
      return item
    end
  end
  
  def self.comments_enabled?
    ENV['RAILS_ENV'] != 'production'
  end

  def self.search(query)
    find(:all, :conditions => wildcard('title', 'body', query))
  end
  
end
