#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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

  attr_accessible :name, :context, :max_membership, :group_category, :join_level, :default_view, :description, :is_public, :avatar_attachment, :storage_quota_mb, :leader
  validates_presence_of :context_id, :context_type, :account_id, :root_account_id, :workflow_state
  validates_allowed_transitions :is_public, false => true

  # use to skip queries in can_participate?, called by policy block
  attr_accessor :can_participate

  has_many :group_memberships, :dependent => :destroy, :conditions => ['group_memberships.workflow_state != ?', 'deleted']
  has_many :users, :through => :group_memberships, :conditions => ['users.workflow_state != ?', 'deleted']
  has_many :participating_group_memberships, :class_name => "GroupMembership", :conditions => ['group_memberships.workflow_state = ?', 'accepted']
  has_many :participating_users, :source => :user, :through => :participating_group_memberships
  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Course', 'Account']
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
  has_many :collaborators
  has_many :external_feeds, :as => :context, :dependent => :destroy
  has_many :messages, :as => :context, :dependent => :destroy
  belongs_to :wiki
  has_many :web_conferences, :as => :context, :dependent => :destroy
  has_many :collaborations, :as => :context, :order => 'title, created_at', :dependent => :destroy
  has_many :media_objects, :as => :context
  has_many :zip_file_imports, :as => :context
  has_many :content_migrations, :as => :context
  belongs_to :avatar_attachment, :class_name => "Attachment"
  belongs_to :leader, :class_name => "User"

  EXPORTABLE_ATTRIBUTES = [
    :id, :name, :workflow_state, :created_at, :updated_at, :context_id, :context_type, :category, :max_membership, :hashtag, :show_public_context_messages, :is_public,
    :account_id, :default_wiki_editing_roles, :wiki_id, :deleted_at, :join_level, :default_view, :storage_quota, :uuid, :root_account_id, :sis_source_id, :sis_batch_id,
    :group_category_id, :description, :avatar_attachment_id
  ]

  EXPORTABLE_ASSOCIATIONS = [
    :users, :group_memberships, :users, :context, :group_category, :account, :root_account, :calendar_events, :discussion_topics, :discussion_entries, :announcements,
    :attachments, :folders, :collaborators, :wiki, :web_conferences, :collaborations, :media_objects, :avatar_attachment
  ]

  before_validation :ensure_defaults
  before_save :maintain_category_attribute
  after_save :close_memberships_if_deleted
  after_save :update_max_membership_from_group_category

  delegate :time_zone, :to => :context

  include StickySisFields
  are_sis_sticky :name

  validates_each :name do |record, attr, value|
    if value.blank?
      record.errors.add attr, t(:name_required, "Name is required")
    elsif value.length > maximum_string_length
      record.errors.add attr, t(:name_too_long, "Enter a shorter group name")
    end
  end

  validates_each :max_membership do |record, attr, value|
    next if value.nil?
    record.errors.add attr, t(:greater_than_1, "Must be greater than 1") unless value.to_i > 1
  end

  alias_method :participating_users_association, :participating_users

  def participating_users(user_ids = nil)
    user_ids ?
      participating_users_association.where(:id =>user_ids) :
      participating_users_association
  end

  def wiki_with_create
    Wiki.wiki_for_context(self)
  end
  alias_method_chain :wiki, :create

  def auto_accept?
    self.group_category &&
    self.group_category.allows_multiple_memberships? &&
    self.join_level == 'parent_context_auto_join'
  end

  def allow_join_request?
    self.group_category &&
    self.group_category.allows_multiple_memberships? &&
    ['parent_context_auto_join', 'parent_context_request'].include?(self.join_level)
  end

  def allow_self_signup?(user)
    self.group_category &&
    (self.group_category.unrestricted_self_signup? ||
      (self.group_category.restricted_self_signup? && self.has_common_section_with_user?(user)))
  end

  def full?
    !student_organized? && ((!max_membership && group_category_limit_met?) || (max_membership && participating_users.size >= max_membership))
  end

  def group_category_limit_met?
    group_category && group_category.group_limit && participating_users.size >= group_category.group_limit
  end
  private :group_category_limit_met?

  def student_organized?
    group_category && group_category.student_organized?
  end

  def update_max_membership_from_group_category
    if group_category && group_category.group_limit && (!max_membership || max_membership == 0)
      self.max_membership = group_category.group_limit
      self.save
    end
  end

  def free_association?(user)
    auto_accept? || allow_join_request? || allow_self_signup?(user)
  end

  def allow_student_forum_attachments
    context.respond_to?(:allow_student_forum_attachments) && context.allow_student_forum_attachments
  end

  def participants(include_observers=false)
    # argument needed because #participants is polymorphic for contexts
    participating_users.uniq
  end

  def context_code
    raise "DONT USE THIS, use .short_name instead" unless Rails.env.production?
  end

  def appointment_context_codes
    {:primary => [context_string], :secondary => [group_category.asset_string]}
  end

  def membership_for_user(user)
    return nil unless user.present?
    self.shard.activate { self.group_memberships.find_by_user_id(user.id) }
  end

  def has_member?(user)
    return nil unless user.present?
    if self.group_memberships.loaded?
      return self.group_memberships.to_a.find { |gm| gm.accepted? && gm.user_id == user.id }
    else
      self.shard.activate { self.participating_group_memberships.find_by_user_id(user.id) }
    end
  end

  def has_moderator?(user)
    return nil unless user.present?
    if self.group_memberships.loaded?
      return self.group_memberships.to_a.find { |gm| gm.accepted? && gm.user_id == user.id && gm.moderator }
    end
    self.shard.activate { self.participating_group_memberships.moderators.find_by_user_id(user.id) }
  end

  def should_add_creator?(creator)
    self.group_category &&
      (self.group_category.communities? || (self.group_category.student_organized? && self.context.user_is_student?(creator)))
  end

  def short_name
    name
  end

  def self.find_all_by_context_code(codes)
    ids = codes.map{|c| c.match(/\Agroup_(\d+)\z/)[1] rescue nil }.compact
    Group.find(ids)
  end

  def self.not_in_group_sql_fragment(groups)
    return nil if groups.empty?
    sanitize_sql([<<-SQL, groups])
      NOT EXISTS (SELECT * FROM group_memberships gm
      WHERE gm.user_id = users.id AND
      gm.workflow_state != 'deleted' AND
      gm.group_id IN (?))
    SQL
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
    self.deleted_at = Time.now.utc
    self.save
  end

  def close_memberships_if_deleted
    return unless self.deleted?
    User.where(:id => group_memberships.pluck(:user_id)).update_all(:updated_at => Time.now.utc)
    group_memberships.update_all(:workflow_state => 'deleted')
  end

  Bookmarker = BookmarkedCollection::SimpleBookmarker.new(Group, :name, :id)

  scope :active, where("groups.workflow_state<>'deleted'")
  scope :by_name, lambda { order(Bookmarker.order_by) }
  scope :uncategorized, where("groups.group_category_id IS NULL")

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
    # permissions for this user in the group are probably different now
    Rails.cache.delete(permission_cache_key_for(user))
    return member
  end

  def bulk_add_users_to_group(users, options = {})
    return if users.empty?
    user_ids = users.map(&:id)
    old_group_memberships = self.group_memberships.where("user_id IN (?)", user_ids).all
    bulk_insert_group_memberships(users, options)
    all_group_memberships = self.group_memberships.where("user_id IN (?)", user_ids)
    new_group_memberships = all_group_memberships - old_group_memberships
    new_group_memberships.sort_by!(&:user_id)
    users.sort_by!(&:id)
    notification_name = options[:notification_name] || "New Context Group Membership"
    notification = Notification.by_name(notification_name)
    users.each {|user| Rails.cache.delete(permission_cache_key_for(user))}

    users.each_with_index do |user, index|
      Instructure::BroadcastPolicy::NotificationPolicy.send_later_enqueue_args(:send_notification,
                                                                               {:priority => Delayed::LOW_PRIORITY},
                                                                               new_group_memberships[index],
                                                                               notification_name.parameterize.underscore.to_sym,
                                                                               notification,
                                                                               [user])
    end
    new_group_memberships
  end

  def bulk_insert_group_memberships(users, options = {})
    current_time = Time.now
    options = {
        :group_id => self.id,
        :workflow_state => 'accepted',
        :moderator => false,
        :created_at => current_time,
        :updated_at => current_time
    }.merge(options)
    GroupMembership.bulk_insert(users.map{ |user|
      options.merge({:user_id => user.id, :uuid => CanvasUuid::Uuid.generate_securish_uuid})
    })
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
    self.group_category.groups.where("id<>?", self).all
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
    self.name ||= CanvasUuid::Uuid.generate_securish_uuid
    self.uuid ||= CanvasUuid::Uuid.generate_securish_uuid
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
    can :send_messages_all and
    can :view_unpublished_items

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

    given { |user| user && self.leader == user }
    can :update

    given { |user| self.group_category.try(:communities?) }
    can :create

    given { |user, session| self.context && self.context.grants_right?(user, session, :participate_as_student) && self.context.allow_student_organized_groups }
    can :create

    given { |user, session| self.context && self.context.grants_right?(user, session, :manage_groups) }
    can :create and
    can :create_collaborations and
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
    can :update and
    can :view_unpublished_items

    given { |user, session| self.context && self.context.grants_right?(user, session, :view_group_pages) }
    can :read and can :read_roster

    # Participate means the user is connected to the group somehow and can be
    given { |user| user && can_participate?(user) }
    can :participate

    # Join is participate + the group being in a state that allows joining directly (free_association)
    given { |user| user && can_participate?(user) && free_association?(user)}
    can :join and can :read_roster

    given { |user| user && (self.group_category.try(:allows_multiple_memberships?) || allow_self_signup?(user)) }
    can :leave
  end

  def users_visible_to(user)
    grants_rights?(user, :read) ? users : users.none
  end

  # Helper needed by several permissions, use grants_right?(user, :participate)
  def can_participate?(user)
    return true if can_participate
    return false unless user.present? && self.context.present?
    return true if self.group_category.try(:communities?)
    if self.context.is_a?(Course)
      return self.context.enrollments.not_fake.except(:includes).where(:user_id => user.id).exists?
    elsif self.context.is_a?(Account)
      return self.context.user_account_associations.where(:user_id => user.id).exists?
    end
    return false
  end
  private :can_participate?

  # courses lock this down a bit, but in a group, the fact that you are a
  # member is good enough
  def user_can_manage_own_discussion_posts?(user)
    true
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
    return self.storage_quota || self.account.default_group_storage_quota || self.class.default_storage_quota
  end

  def self.default_storage_quota
    Setting.get('group_default_quota', 50.megabytes.to_s).to_i
  end

  def storage_quota_mb
    quota / 1.megabyte
  end

  def storage_quota_mb=(val)
    self.storage_quota = val.try(:to_i).try(:megabytes)
  end

  TAB_HOME, TAB_PAGES, TAB_PEOPLE, TAB_DISCUSSIONS, TAB_FILES,
    TAB_CONFERENCES, TAB_ANNOUNCEMENTS, TAB_PROFILE, TAB_SETTINGS, TAB_COLLABORATIONS = *1..20
  def tabs_available(user=nil, opts={})
    available_tabs = [
      { :id => TAB_HOME,          :label => t("#group.tabs.home", "Home"), :css_class => 'home', :href => :group_path },
      { :id => TAB_ANNOUNCEMENTS, :label => t('#tabs.announcements', "Announcements"), :css_class => 'announcements', :href => :group_announcements_path },
      { :id => TAB_PAGES,         :label => t("#group.tabs.pages", "Pages"), :css_class => 'pages', :href => :group_wiki_pages_path },
      { :id => TAB_PEOPLE,        :label => t("#group.tabs.people", "People"), :css_class => 'people', :href => :group_users_path },
      { :id => TAB_DISCUSSIONS,   :label => t("#group.tabs.discussions", "Discussions"), :css_class => 'discussions', :href => :group_discussion_topics_path },
      { :id => TAB_FILES,         :label => t("#group.tabs.files", "Files"), :css_class => 'files', :href => :group_files_path },
    ]

    if root_account.try :canvas_network_enabled?
      available_tabs << {:id => TAB_PROFILE, :label => t('#tabs.profile', 'Profile'), :css_class => 'profile', :href => :group_profile_path}
    end
    available_tabs << { :id => TAB_CONFERENCES, :label => t('#tabs.conferences', "Conferences"), :css_class => 'conferences', :href => :group_conferences_path } if user && self.grants_right?(user, nil, :read)
    available_tabs << { :id => TAB_COLLABORATIONS, :label => t('#tabs.collaborations', "Collaborations"), :css_class => 'collaborations', :href => :group_collaborations_path } if user && self.grants_right?(user, nil, :read)
    if root_account.try(:canvas_network_enabled?) && user && grants_right?(user, nil, :manage)
      available_tabs << { :id => TAB_SETTINGS, :label => t('#tabs.settings', 'Settings'), :css_class => 'settings', :href => :edit_group_path }
    end
    available_tabs
  end

  def self.serialization_excludes; [:uuid]; end

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

  def self.join_levels
    [
      ["invitation_only", "Invite only"],
      ["parent_context_auto_join", "Auto join"],
      ["parent_context_request", "Request to join"]
    ]
  end

  def associated_shards
    [Shard.default]
  end

  # Public: Determine whether a feature is enabled, deferring to the group's context.
  #
  # Returns a boolean.
  def feature_enabled?(feature)
    # shouldn't matter, but most specs create anonymous (contextless) groups :(
    return false if context.nil?
    context.feature_enabled?(feature)
  end

  def serialize_permissions(permissions_hash, user, session)
    permissions_hash.merge(
      create_discussion_topic: DiscussionTopic.context_allows_user_to_create?(self, user, session)
    )
  end
end
