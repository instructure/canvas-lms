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
  attr_accessible :title, :body, :url, :user_id, :editing_roles, :notify_of_update
  attr_readonly :wiki_id, :hide_from_students
  validates_length_of :body, :maximum => maximum_long_text_length, :allow_nil => true, :allow_blank => true
  validates_presence_of :wiki_id
  include Workflow
  include HasContentTags
  include CopyAuthorizedLinks
  include ContextModuleItem

  include SearchTermHelper

  belongs_to :wiki, :touch => true
  belongs_to :user
  acts_as_url :title, :scope => [:wiki_id, :not_deleted], :sync_url => true

  validate :validate_front_page_visibility

  before_save :set_revised_at
  before_validation :ensure_unique_title
  after_save :touch_wiki_context

  TITLE_LENGTH = WikiPage.columns_hash['title'].limit rescue 255
  SIMPLY_VERSIONED_EXCLUDE_FIELDS = [:workflow_state, :hide_from_students, :editing_roles, :notify_of_update]

  def touch_wiki_context
    self.wiki.touch_context if self.wiki && self.wiki.context
  end

  def validate_front_page_visibility
    if !published? && self.is_front_page?
      self.errors.add(:hide_from_students, t(:cannot_hide_page, "cannot hide front page"))
    end
  end

  def ensure_unique_title
    return if deleted?
    to_cased_title = ->(string) { string.gsub(/[^\w]+/, " ").gsub(/\b('?[a-z])/){$1.capitalize}.strip }
    self.title ||= to_cased_title.call(self.url || "page")
    return unless self.wiki
    # TODO i18n (see wiki.rb)
    if self.title == "Front Page" && self.new_record?
      baddies = self.wiki.wiki_pages.not_deleted.find_all_by_title("Front Page").select{|p| p.url != "front-page" }
      baddies.each{|p| p.title = to_cased_title.call(p.url); p.save_without_broadcasting! }
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

  def normalize_hide_from_students
    workflow_state = self.read_attribute('workflow_state')
    hide_from_students = self.read_attribute('hide_from_students')
    if !workflow_state.nil? && !hide_from_students.nil?
      self.workflow_state = 'unpublished' if hide_from_students && workflow_state == 'active'
      self.write_attribute('hide_from_students', nil)
    end
  end
  if CANVAS_RAILS2
    alias_method :after_find, :normalize_hide_from_students
  else
    after_find :normalize_hide_from_students
  end
  private :normalize_hide_from_students

  def hide_from_students
    self.workflow_state == 'unpublished'
  end

  def hide_from_students=(v)
    self.workflow_state = 'unpublished' if v && self.workflow_state == 'active'
    self.workflow_state = 'active' if !v && self.workflow_state = 'unpublished'
    hide_from_students
  end

  def self.title_order_by_clause
    best_unicode_collation_key('wiki_pages.title')
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
    # less scopeds. note that there needs to be an instance_method of
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
    url_owners = base_scope.where(conditions).all
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

  sanitize_field :body, CanvasSanitize::SANITIZE
  copy_authorized_links(:body) { [self.context, self.user] }

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
  simply_versioned :exclude => SIMPLY_VERSIONED_EXCLUDE_FIELDS, :when => Proc.new { |wp|
    # :user_id and :updated_at do not merit creating a version, but should be saved
    exclude_fields = [:user_id, :updated_at].concat(SIMPLY_VERSIONED_EXCLUDE_FIELDS).map(&:to_s)
    (wp.changes.keys.map(&:to_s) - exclude_fields).present?
  }
  after_save :remove_changed_flag


  workflow do
    state :active do
      event :unpublish, :transitions_to => :unpublished
    end
    state :unpublished do
      event :publish, :transitions_to => :active
    end
    state :post_delayed do
      event :delayed_post, :transitions_to => :active
    end
    state :deleted
  end
  alias_method :published?, :active?

  def restore
    self.workflow_state = context.feature_enabled?(:draft_state) ? 'unpublished' : 'active'
    self.save
  end

  def set_revised_at
    self.revised_at ||= Time.now
    self.revised_at = Time.now if self.body_changed?
    @page_changed = self.body_changed? || self.title_changed?
    true
  end

  def notify_of_update=(val)
    @wiki_page_changed = Canvas::Plugin.value_to_boolean(val)
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

  scope :active, where(:workflow_state => 'active')

  scope :deleted_last, order("workflow_state='deleted'")

  scope :not_deleted, where("wiki_pages.workflow_state<>'deleted'")

  scope :published, where("wiki_pages.workflow_state='active' AND (wiki_pages.hide_from_students=? OR wiki_pages.hide_from_students IS NULL)", false)
  scope :unpublished, where("wiki_pages.workflow_state='unpublished' OR (wiki_pages.hide_from_students=? AND wiki_pages.workflow_state<>'deleted')", true)

  # needed for ensure_unique_url
  def not_deleted
    !deleted?
  end

  scope :order_by_id, order(:id)

  def locked_for?(user, opts={})
    return false unless self.could_be_locked
    Rails.cache.fetch(locked_cache_key(user), :expires_in => 1.minute) do
      locked = false
      if item = locked_by_module_item?(user, opts[:deep_check_if_needed])
        locked = {:asset_string => self.asset_string, :context_module => item.context_module.attributes}
        locked[:unlock_at] = locked[:context_module]["unlock_at"] if locked[:context_module]["unlock_at"]
      end
      locked
    end
  end

  def is_front_page?
    return false if self.deleted?
    self.url == self.wiki.get_front_page_url # wiki.get_front_page_url checks has_front_page? and context.feature_enabled?(:draft_state)
  end

  def set_as_front_page!
    can_set_front_page = true
    if self.unpublished?
      self.errors.add(:front_page, t(:cannot_set_unpublished_front_page, 'could not set as front page because it is unpublished'))
      can_set_front_page = false
    end
    if self.hide_from_students
      self.errors.add(:front_page, t(:cannot_set_hidden_front_page, 'could not set as front page because it is hidden'))
      can_set_front_page = false
    end
    return false unless can_set_front_page

    self.wiki.set_front_page_url!(self.url)
  end

  def context_module_tag_for(context)
    @tag ||= self.context_module_tags.where(context_id: context, context_type: context.class.base_ar_class.name).first
  end

  def context_module_action(user, context, action)
    self.context_module_tags.where(context_id: context, context_type: context.class.base_ar_class.name).each do |tag|
      tag.context_module_action(user, action)
    end
  end

  set_policy do
    given {|user, session| self.can_read_page?(user, session)}
    can :read

    given {|user, session| self.can_edit_page?(user)}
    can :read

    given {|user, session| user && self.can_edit_page?(user)}
    can :update_content and can :read_revisions

    given {|user, session| user && self.can_edit_page?(user) && self.wiki.grants_right?(user, session, :create_page)}
    can :create

    given {|user, session| user && self.can_edit_page?(user) && self.wiki.grants_right?(user, session, :update_page)}
    can :update and can :read_revisions

    given {|user, session| user && self.can_edit_page?(user) && self.published? && self.wiki.grants_right?(user, session, :update_page_content)}
    can :update_content and can :read_revisions

    given {|user, session| user && self.can_edit_page?(user) && self.published? && self.wiki.grants_right?(user, session, :delete_page)}
    can :delete

    given {|user, session| user && self.can_edit_page?(user) && self.unpublished? && self.wiki.grants_right?(user, session, :delete_unpublished_page)}
    can :delete
  end

  def can_read_page?(user, session=nil)
    return true if self.wiki.grants_right?(user, session, :manage)
    return true if self.unpublished? && self.wiki.grants_right?(user, session, :view_unpublished_items)
    self.published? && self.wiki.grants_right?(user, session, :read)
  end

  def can_edit_page?(user, session=nil)
    # wiki managers are always allowed to edit
    return true if wiki.grants_right?(user, session, :manage)

    roles = effective_roles
    # teachers implies all course admins (teachers, TAs, etc)
    return true if roles.include?('teachers') && context.respond_to?(:admins) && context.admins.include?(user)

    # the page must be available for users of the following roles
    return false unless available_for?(user, session)
    return true if roles.include?('students') && context.respond_to?(:students) && context.includes_student?(user)
    return true if roles.include?('members') && context.respond_to?(:users) && context.users.include?(user)
    return true if roles.include?('public')
    false
  end

  def effective_roles
    context_roles = context.default_wiki_editing_roles rescue nil
    roles = (editing_roles || context_roles || default_roles).split(',')
    roles == %w(teachers) ? [] : roles # "Only teachers" option doesn't grant rights excluded by RoleOverrides
  end

  def available_for?(user, session=nil)
    return true if wiki.grants_right?(user, session, :manage)

    return false unless published? || (unpublished? && wiki.grants_right?(user, session, :view_unpublished_items))
    return false if locked_for?(user)

    true
  end

  def default_roles
    if context.is_a?(Group)
      'members'
    elsif context.is_a?(Course)
      'teachers'
    else
      'members'
    end
  end

  set_broadcast_policy do |p|
    p.dispatch :updated_wiki_page
    p.to { participants }
    p.whenever do |record|
      return false unless record.created_at < Time.now - 30.minutes
      (record.published? && @wiki_page_changed && record.prior_version) || record.changed_state(:active)
    end
  end

  def context(user=nil)
    shard.activate do
      @context ||= Course.find_by_wiki_id(self.wiki_id) || Group.find_by_wiki_id(self.wiki_id)
    end
  end

  def participants
    res = []
    if context && context.available?
      if !self.active?
        res += context.participating_admins
      else
        res += context.participants
      end
    end
    res.flatten.uniq
  end

  def to_atom(opts={})
    context = opts[:context]
    Atom::Entry.new do |entry|
      entry.title     = t(:atom_entry_title, "Wiki Page, %{course_or_group_name}: %{page_title}", :course_or_group_name => context.name, :page_title => self.title)
      entry.authors  << Atom::Person.new(:name => t(:atom_author, "Wiki Page"))
      entry.updated   = self.updated_at
      entry.published = self.created_at
      entry.id        = "tag:#{HostUrl.default_host},#{self.created_at.strftime("%Y-%m-%d")}:/wiki_pages/#{self.feed_code}_#{self.updated_at.strftime("%Y-%m-%d")}"
      entry.links    << Atom::Link.new(:rel => 'alternate', 
                                    :href => "http://#{HostUrl.context_host(context)}/#{self.context.class.to_s.downcase.pluralize}/#{self.context.id}/wiki/#{self.url}")
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
      next unless migration.import_object?("wiki_pages", wiki['migration_id']) || migration.import_object?("wikis", wiki['migration_id'])
      begin
        import_from_migration(wiki, migration.context) if wiki
      rescue
        migration.add_import_warning(t('#migration.wiki_page_type', "Wiki Page"), wiki[:title], $!)
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
      front_page = context.wiki.front_page
      if front_page.id
        hash[:root_folder] = false
      else
        # If there is no id there isn't a front page yet
        item = front_page
      end
    end
    hide_from_students = hash[:hide_from_students] if !hash[:hide_from_students].nil?
    state = hash[:workflow_state]
    if state || !hide_from_students.nil?
      if state == 'active' && Canvas::Plugin.value_to_boolean(hide_from_students) == false
        item.workflow_state = 'active'
      else
        item.workflow_state = 'unpublished'
      end
    end
    item.set_as_front_page! if !!hash[:front_page]
    context.imported_migration_items << item if context.imported_migration_items && item.new_record?
    item.migration_id = hash[:migration_id]
    (hash[:contents] || []).each do |sub_item|
      next if sub_item[:type] == 'embedded_content'
      WikiPage.import_from_migration(sub_item.merge({
        :outline_folders_to_import => hash[:outline_folders_to_import]
      }), context)
    end
    return if hash[:type] && ['folder', 'FOLDER_TYPE'].member?(hash[:type]) && hash[:linked_resource_id]
    hash[:missing_links] = {}
    allow_save = true
    if hash[:type] == 'linked_resource' || hash[:type] == "URL_TYPE"
      allow_save = false
    elsif ['folder', 'FOLDER_TYPE'].member? hash[:type]
      item.title = hash[:title] unless hash[:root_folder]
      description = ""
      if hash[:header]
        hash[:missing_links][:field] = []
        description += hash[:header][:is_html] ? ImportedHtmlConverter.convert(hash[:header][:body] || "", context, {:missing_links => hash[:missing_links][:header]}) : ImportedHtmlConverter.convert_text(hash[:header][:body] || [""], context)
      end
      hash[:missing_links][:description] = []
      description += ImportedHtmlConverter.convert(hash[:description], context, {:missing_links => hash[:missing_links][:description]}) if hash[:description]
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
          hash[:missing_links][:sub_item] = []
          description += ImportedHtmlConverter.convert(sub_item[:description], context, {:missing_links => hash[:missing_links][:sub_item]}) if sub_item[:description]
        elsif sub_item[:type] == 'linked_resource'
          case sub_item[:linked_resource_type]
          when 'TOC_TYPE'
            obj = context.context_modules.not_deleted.find_by_migration_id(sub_item[:linked_resource_id])
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
        hash[:missing_links][:footer] = []
        description += hash[:footer][:is_html] ? ImportedHtmlConverter.convert(hash[:footer][:body] || "", context, {:missing_links => hash[:missing_links][:footer]}) : ImportedHtmlConverter.convert_text(hash[:footer][:body] || [""], context)
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
        topic = Importers::DiscussionTopic.import_from_migration(topic.merge({
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
        if context.respond_to?(:content_migration) && context.content_migration
          context.content_migration.add_warning(t('warnings.truncated_wiki_title', "The title of the following wiki page was truncated: %{title}", :title => item.title))
        end
        item.title.splice!(0...TITLE_LENGTH) # truncate too-long titles
      end
      hash[:missing_links][:body] = []
      item.body = ImportedHtmlConverter.convert(hash[:text] || "", context, {:missing_links => hash[:missing_links][:body]})
      item.editing_roles = hash[:editing_roles] if hash[:editing_roles].present?
      item.notify_of_update = hash[:notify_of_update] if !hash[:notify_of_update].nil?
    else
      allow_save = false
    end
    if allow_save && hash[:migration_id]
      item.save_without_broadcasting!
      context.imported_migration_items << item if context.imported_migration_items
      if context.respond_to?(:content_migration) && context.content_migration
        hash[:missing_links].each do |field, missing_links|
          context.content_migration.add_missing_content_links(:class => item.class.to_s,
            :id => item.id, :field => field, :missing_links => missing_links,
            :url => "/#{context.class.to_s.underscore.pluralize}/#{context.id}/wiki/#{item.url}")
        end
      end
      return item
    end
  end

  def increment_view_count(user, context = nil)
    unless self.new_record?
      self.with_versioning(false) do |p|
        context ||= p.context
        WikiPage.where(id: p).update_all("view_count=COALESCE(view_count, 0) + 1")
        p.context_module_action(user, context, :read)
      end
    end
  end

  def can_unpublish?
    !is_front_page?
  end

  def initialize_wiki_page(user)
    is_privileged_user = wiki.grants_right?(user, :manage)
    if is_privileged_user && context.feature_enabled?(:draft_state) && !context.is_a?(Group)
      self.workflow_state = 'unpublished'
    else
      self.workflow_state = 'active'
    end

    self.editing_roles = (context.default_wiki_editing_roles rescue nil) || default_roles

    if is_front_page?
      self.body = t "#application.wiki_front_page_default_content_course", "Welcome to your new course wiki!" if context.is_a?(Course)
      self.body = t "#application.wiki_front_page_default_content_group", "Welcome to your new group wiki!" if context.is_a?(Group)
      self.workflow_state = 'active'
    end
  end
end
