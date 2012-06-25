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

class Group < ActiveRecord::Base
  include Context
  include Workflow
  include CustomValidations
  include UserFollow::FollowedItem

  attr_accessible :name, :context, :max_membership, :group_category, :join_level, :default_view, :description, :is_public, :avatar_attachment
  validates_allowed_transitions :is_public, false => true

  has_many :group_memberships, :dependent => :destroy, :conditions => ['group_memberships.workflow_state != ?', 'deleted']
  has_many :users, :through => :group_memberships, :conditions => ['users.workflow_state != ?', 'deleted']
  has_many :participating_group_memberships, :class_name => "GroupMembership", :conditions => ['group_memberships.workflow_state = ?', 'accepted']
  has_many :participating_users, :source => :user, :through => :participating_group_memberships
  belongs_to :context, :polymorphic => true
  belongs_to :group_category
  belongs_to :account
  belongs_to :root_account, :class_name => "Account"
  has_many :calendar_events, :as => :context, :dependent => :destroy
  has_many :discussion_topics, :as => :context, :conditions => ['discussion_topics.workflow_state != ?', 'deleted'], :include => :user, :dependent => :destroy, :order => 'discussion_topics.position DESC, discussion_topics.created_at DESC'
  has_many :active_discussion_topics, :as => :context, :class_name => 'DiscussionTopic', :conditions => ['discussion_topics.workflow_state != ?', 'deleted'], :include => :user
  has_many :all_discussion_topics, :as => :context, :class_name => "DiscussionTopic", :include => :user, :dependent => :destroy
  has_many :discussion_entries, :through => :discussion_topics, :include => [:discussion_topic, :user], :dependent => :destroy
  has_many :announcements, :as => :context, :class_name => 'Announcement', :dependent => :destroy
  has_many :active_announcements, :as => :context, :class_name => 'Announcement', :conditions => ['discussion_topics.workflow_state != ?', 'deleted']
  has_many :attachments, :as => :context, :dependent => :destroy, :extend => Attachment::FindInContextAssociation
  has_many :active_images, :as => :context, :class_name => 'Attachment', :conditions => ["attachments.file_state != ? AND attachments.content_type LIKE 'image%'", 'deleted'], :order => 'attachments.display_name', :include => :thumbnail
  has_many :active_assignments, :as => :context, :class_name => 'Assignment', :conditions => ['assignments.workflow_state != ?', 'deleted']
  has_many :all_attachments, :as => 'context', :class_name => 'Attachment'
  has_many :folders, :as => :context, :dependent => :destroy, :order => 'folders.name'
  has_many :active_folders, :class_name => 'Folder', :as => :context, :conditions => ['folders.workflow_state != ?', 'deleted'], :order => 'folders.name'
  has_many :active_folders_with_sub_folders, :class_name => 'Folder', :as => :context, :include => [:active_sub_folders], :conditions => ['folders.workflow_state != ?', 'deleted'], :order => 'folders.name'
  has_many :active_folders_detailed, :class_name => 'Folder', :as => :context, :include => [:active_sub_folders, :active_file_attachments], :conditions => ['folders.workflow_state != ?', 'deleted'], :order => 'folders.name'
  has_many :external_feeds, :as => :context, :dependent => :destroy
  has_many :messages, :as => :context, :dependent => :destroy
  belongs_to :wiki
  has_many :default_wiki_wiki_pages, :class_name => 'WikiPage', :through => :wiki, :source => :wiki_pages
  has_many :active_default_wiki_wiki_pages, :class_name => 'WikiPage', :through => :wiki, :source => :wiki_pages, :conditions => ['wiki_pages.workflow_state = ?', 'active']
  has_many :wiki_namespaces, :as => :context, :dependent => :destroy
  has_many :web_conferences, :as => :context, :dependent => :destroy
  has_many :collaborations, :as => :context, :order => 'title, created_at', :dependent => :destroy
  has_one :scribd_account, :as => :scribdable
  has_many :short_message_associations, :as => :context, :include => :short_message, :dependent => :destroy
  has_many :short_messages, :through => :short_message_associations, :dependent => :destroy
  has_many :media_objects, :as => :context
  has_many :zip_file_imports, :as => :context
  has_many :collections, :as => :context
  belongs_to :avatar_attachment, :class_name => "Attachment"
  has_many :following_user_follows, :class_name => 'UserFollow', :as => :followed_item
  has_many :user_follows, :foreign_key => 'following_user_id'

  before_save :ensure_defaults, :maintain_category_attribute
  after_save :close_memberships_if_deleted

  include StickySisFields
  are_sis_sticky :name

  alias_method :participating_users_association, :participating_users

  def participating_users(user_ids = nil)
    user_ids ?
      participating_users_association.scoped(:conditions => {:id => user_ids}) :
      participating_users_association
  end

  def wiki
    res = self.wiki_id && Wiki.find_by_id(self.wiki_id)
    unless res
      res = WikiNamespace.default_for_context(self).wiki
      self.wiki_id = res.id if res
      self.save
    end
    res
  end

  def auto_accept?(user)
    self.group_category && 
    self.group_category.available_for?(user) &&
    self.group_category.allows_multiple_memberships? &&
    self.join_level == 'parent_context_auto_join'
  end

  def allow_join_request?(user)
    self.group_category && 
    self.group_category.available_for?(user) &&
    self.group_category.allows_multiple_memberships? &&
    ['parent_context_auto_join', 'parent_context_request'].include?(self.join_level)
  end

  def allow_self_signup?(user)
    self.context && 
    self.context.grants_right?(user, :participate_in_groups) &&
    self.group_category &&
    (self.group_category.unrestricted_self_signup? ||
      (self.group_category.restricted_self_signup? && self.has_common_section_with_user?(user)))
  end

  def can_join?(user)
    auto_accept?(user) || allow_join_request?(user) || allow_self_signup?(user)
  end

  def can_leave?(user)
    self.group_category.try(:allows_multiple_memberships?) || self.allow_self_signup?(user)
  end

  def participants(include_observers=false)
    # argument needed because #participants is polymorphic for contexts
    participating_users.uniq
  end

  def context_code
    raise "DONT USE THIS, use .short_name instead" unless ENV['RAILS_ENV'] == "production"
  end

  def appointment_context_codes
    {:primary => [context_string], :secondary => [group_category.asset_string]}
  end

  def membership_for_user(user)
    self.group_memberships.find_by_user_id(user && user.id)
  end

  def has_member?(user)
    self.participating_group_memberships.find_by_user_id(user && user.id)
  end

  def has_moderator?(user)
    self.participating_group_memberships.moderators.find_by_user_id(user && user.id)
  end

  def should_add_creator?
    self.group_category && (self.group_category.communities? || self.group_category.student_organized?)
  end

  def short_name
    name
  end

  def self.find_all_by_context_code(codes)
    ids = codes.map{|c| c.match(/\Agroup_(\d+)\z/)[1] rescue nil }.compact
    Group.find(ids)
  end

  workflow do
    state :available do
      event :complete, :transitions_to => :completed
      event :close, :transitions_to => :closed
    end

    # Closed to new entrants
    state :closed do
      event :complete, :transitions_to => :completed
      event :open, :transitions_to => :available
    end

    state :completed
    state :deleted
  end

  def active?
    self.available? || self.closed?
  end

  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.deleted_at = Time.now
    self.save
  end

  def close_memberships_if_deleted
    return unless self.deleted?
    memberships = self.group_memberships
    User.update_all({:updated_at => Time.now.utc}, {:id => memberships.map(&:user_id).uniq})
    GroupMembership.update_all({:workflow_state => 'deleted'}, {:id => memberships.map(&:id).uniq})
  end

  named_scope :active, :conditions => ['groups.workflow_state != ?', 'deleted']

  def full_name
    res = before_label(self.name) + " "
    res += (self.context.course_code rescue self.context.name) if self.context
  end

  def to_atom
    Atom::Entry.new do |entry|
      entry.title     = self.name
      entry.updated   = self.updated_at
      entry.published = self.created_at
      entry.links    << Atom::Link.new(:rel => 'alternate',
                                    :href => "/groups/#{self.id}")
    end
  end

  # this method is idempotent
  def add_user(user, new_record_state=nil, moderator=nil)
    return nil if !user
    attrs = { :user => user, :moderator => !!moderator }
    new_record_state ||= case self.join_level
      when 'invitation_only'          then 'invited'
      when 'parent_context_request'   then 'requested'
      when 'parent_context_auto_join' then 'accepted'
      end
    attrs[:workflow_state] = new_record_state if new_record_state
    if member = self.group_memberships.find_by_user_id(user.id)
      member.workflow_state = new_record_state unless member.active?
      # only update moderator if true/false is explicitly passed in
      member.moderator = moderator unless moderator.nil?
      member.save if member.changed?
    else
      member = self.group_memberships.create(attrs)
    end
    return member
  end

  def invite_user(user)
    self.add_user(user, 'invited')
  end

  def request_user(user)
    self.add_user(user, 'requested')
  end

  def invitees=(params)
    invitees = []
    (params || {}).each do |key, val|
      if self.context
        invitees << self.context.users.find_by_id(key.to_i) if val != '0'
      else
        invitees << User.find_by_id(key.to_i) if val != '0'
      end
    end
    invitees.compact.map{|i| self.invite_user(i) }.compact
  end

  def peer_groups
    return [] if !self.context || !self.group_category || self.group_category.allows_multiple_memberships?
    self.group_category.groups.find(:all, :conditions => ["id != ?", self.id])
  end

  def migrate_content_links(html, from_course)
    Course.migrate_content_links(html, from_course, self)
  end

  attr_accessor :merge_mappings
  attr_accessor :merge_results
  def merge_mapped_id(*args)
    nil
  end

  def map_merge(*args)
  end
  def log_merge_result(text)
    @merge_results ||= []
    @merge_results << text
  end
  def warn_merge_result(text)
    record_merge_result(text)
  end

  def student_organized?
    self.group_category && self.group_category.student_organized?
  end

  def ensure_defaults
    self.name ||= AutoHandle.generate_securish_uuid
    self.uuid ||= AutoHandle.generate_securish_uuid
    self.group_category ||= GroupCategory.student_organized_for(self.context)
    self.join_level ||= 'invitation_only'
    self.is_public ||= false
    self.is_public = false unless self.group_category.try(:communities?)
    if self.context && self.context.is_a?(Course)
      self.account = self.context.account
    elsif self.context && self.context.is_a?(Account)
      self.account = self.context
    end
  end
  private :ensure_defaults

  # update root account when account changes
  def account=(new_account)
    self.account_id = new_account.id
  end
  def account_id=(new_account_id)
    write_attribute(:account_id, new_account_id)
    if self.account_id_changed?
      self.root_account = self.account(true).try(:root_account)
    end
  end

  # if you modify this set_policy block, note that we've denormalized this
  # permission check for efficiency -- see User#cached_contexts
  set_policy do
    given { |user| user && self.has_member?(user) }
    can :create_collaborations and
    can :create_conferences and
    can :manage_calendar and
    can :manage_content and 
    can :manage_files and
    can :manage_wiki and
    can :post_to_forum and
    can :read and 
    can :read_roster and
    can :send_messages and
    can :follow

    # if I am a member of this group and I can moderate_forum in the group's context
    # (makes it so group members cant edit each other's discussion entries)
    given { |user, session| user && self.has_member?(user) && (!self.context || self.context.grants_right?(user, session, :moderate_forum)) }
    can :moderate_forum

    given { |user| user && self.has_moderator?(user) }
    can :delete and
    can :manage and
    can :manage_admin_users and
    can :manage_students and 
    can :moderate_forum and
    can :update

    given { |user| self.group_category.try(:communities?) }
    can :create

    given { |user, session| self.context && self.context.grants_right?(user, session, :participate_as_student) && self.context.allow_student_organized_groups }
    can :create

    given { |user, session| self.context && self.context.grants_right?(user, session, :manage_groups) }
    can :create and
    can :create_conferences and
    can :delete and
    can :manage and
    can :manage_admin_users and
    can :manage_content and
    can :manage_files and
    can :manage_students and
    can :manage_wiki and
    can :moderate_forum and
    can :post_to_forum and
    can :read and
    can :read_roster and
    can :update

    given { |user, session| self.context && self.context.grants_right?(user, session, :view_group_pages) }
    can :read and can :read_roster

    given { |user| user && self.can_join?(user) }
    can :read_roster

    given { |user| user && self.is_public? }
    can :follow
  end

  def file_structure_for(user)
    User.file_structure_for(self, user)
  end

  def is_a_context?
    true
  end

  def members_json_cached
    Rails.cache.fetch(['group_members_json', self].cache_key) do
      self.users.map{ |u| u.group_member_json(self.context) }
    end
  end

  def members_count_cached
    Rails.cache.fetch(['group_members_count', self].cache_key) do
      self.members_json_cached.length
    end
  end

  def members_count
    self.participating_group_memberships.count
  end

  def quota
    self.storage_quota || Setting.get_cached('group_default_quota', 50.megabytes.to_s).to_i
  end

  TAB_HOME = 0
  TAB_PAGES = 1
  TAB_PEOPLE = 2
  TAB_DISCUSSIONS = 3
  TAB_CHAT = 4
  TAB_FILES = 5
  TAB_CONFERENCES = 6
  TAB_ANNOUNCEMENTS = 7
  def tabs_available(user=nil, opts={})
    available_tabs = [
      { :id => TAB_HOME,          :label => t("#group.tabs.home", "Home"), :css_class => 'home', :href => :group_path },
      { :id => TAB_ANNOUNCEMENTS, :label => t('#tabs.announcements', "Announcements"), :css_class => 'announcements', :href => :group_announcements_path },
      { :id => TAB_PAGES,         :label => t("#group.tabs.pages", "Pages"), :css_class => 'pages', :href => :group_wiki_pages_path },
      { :id => TAB_PEOPLE,        :label => t("#group.tabs.people", "People"), :css_class => 'peopel', :href => :group_users_path },
      { :id => TAB_DISCUSSIONS,   :label => t("#group.tabs.discussions", "Discussions"), :css_class => 'discussions', :href => :group_discussion_topics_path },
      { :id => TAB_CHAT,          :label => t("#group.tabs.chat", "Chat"), :css_class => 'chat', :href => :group_chat_path },
      { :id => TAB_FILES,         :label => t("#group.tabs.files", "Files"), :css_class => 'files', :href => :group_files_path }
    ]
    available_tabs << { :id => TAB_CONFERENCES, :label => t('#tabs.conferences', "Conferences"), :css_class => 'conferences', :href => :group_conferences_path } if user && self.grants_right?(user, nil, :read)
    available_tabs
  end

  def self.serialization_excludes; [:uuid]; end

  def self.process_migration(data, migration)
    groups = data['groups'] || []
    groups.each do |group|
      if migration.import_object?("groups", group['migration_id'])
        begin
          import_from_migration(group, migration.context)
        rescue
          migration.add_warning("Couldn't import group \"#{group[:title]}\"", $!)
        end
      end
    end
  end

  def self.import_from_migration(hash, context, item=nil)
    hash = hash.with_indifferent_access
    return nil if hash[:migration_id] && hash[:groups_to_import] && !hash[:groups_to_import][hash[:migration_id]]
    item ||= find_by_context_id_and_context_type_and_id(context.id, context.class.to_s, hash[:id])
    item ||= find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, hash[:migration_id]) if hash[:migration_id]
    item ||= context.groups.new
    context.imported_migration_items << item if context.imported_migration_items && item.new_record?
    item.migration_id = hash[:migration_id]
    item.name = hash[:title]
    item.group_category = hash[:group_category].present? ?
      context.group_categories.find_or_initialize_by_name(hash[:group_category]) :
      GroupCategory.imported_for(context)

    item.save!
    context.imported_migration_items << item
    item
  end

  def allow_media_comments?
    true
  end

  def group_category_name
    self.read_attribute(:category)
  end

  def maintain_category_attribute
    # keep this field up to date even though it's not used (group_category_name
    # exists solely for the migration that introduces the GroupCategory model).
    # this way group_category_name is correct if someone mistakenly uses it
    # (modulo category renaming in the GroupCategory model).
    self.write_attribute(:category, self.group_category && self.group_category.name)
  end

  def as_json(options=nil)
    json = super(options)
    if json && json['group']
      # remove anything coming automatically from deprecated db column
      json['group'].delete('category')
      if self.group_category
        # put back version from association
        json['group']['group_category'] = self.group_category.name
      end
    end
    json
  end

  def has_common_section?
    self.context && self.context.is_a?(Course) &&
    self.context.course_sections.active.any?{ |section| section.common_to_users?(self.users) }
  end

  def has_common_section_with_user?(user)
    return false unless self.context && self.context.is_a?(Course)
    users = self.users + [user]
    self.context.course_sections.active.any?{ |section| section.common_to_users?(users) }
  end

  def default_collection_name
    t "#group.default_collection_name", "%{group_name}'s Collection", :group_name => self.name
  end
end
