# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
  self.ignored_columns += ["category"]

  include Context
  include Workflow
  include CustomValidations

  validates :context_id, :context_type, :account_id, :root_account_id, :workflow_state, :uuid, presence: true
  validates_allowed_transitions :is_public, false => true

  validates :sis_source_id, uniqueness: { scope: :root_account }, allow_nil: true

  # use to skip queries in can_participate?, called by policy block
  attr_accessor :can_participate

  has_many :group_memberships, -> { where("group_memberships.workflow_state<>'deleted'") }, dependent: :destroy
  has_many :users, -> { where("users.workflow_state<>'deleted'") }, through: :group_memberships
  has_many :user_past_lti_ids, as: :context, inverse_of: :context
  has_many :participating_group_memberships, -> { where(workflow_state: "accepted") }, class_name: "GroupMembership"
  has_many :participating_users, source: :user, through: :participating_group_memberships
  belongs_to :context, polymorphic: [:course, { context_account: "Account" }]
  belongs_to :group_category
  belongs_to :account
  belongs_to :root_account, class_name: "Account", inverse_of: :all_groups
  has_many :calendar_events, as: :context, inverse_of: :context, dependent: :destroy
  has_many :discussion_topics, -> { where("discussion_topics.workflow_state<>'deleted'").preload(:user).order("discussion_topics.position DESC, discussion_topics.created_at DESC") }, dependent: :destroy, as: :context, inverse_of: :context
  has_many :active_discussion_topics, -> { where("discussion_topics.workflow_state<>'deleted'").preload(:user) }, as: :context, inverse_of: :context, class_name: "DiscussionTopic"
  has_many :all_discussion_topics, -> { preload(:user) }, as: :context, inverse_of: :context, class_name: "DiscussionTopic", dependent: :destroy
  has_many :discussion_entries, -> { preload(:discussion_topic, :user) }, through: :discussion_topics, dependent: :destroy
  has_many :announcements, as: :context, inverse_of: :context, class_name: "Announcement", dependent: :destroy
  has_many :active_announcements, -> { where("discussion_topics.workflow_state<>'deleted'") }, as: :context, inverse_of: :context, class_name: "Announcement"
  has_many :attachments, as: :context, inverse_of: :context, dependent: :destroy, extend: Attachment::FindInContextAssociation
  has_many :active_images, -> { where("attachments.file_state<>'deleted' AND attachments.content_type LIKE 'image%'").order("attachments.display_name").preload(:thumbnail) }, as: :context, inverse_of: :context, class_name: "Attachment"
  has_many :active_assignments, -> { where("assignments.workflow_state<>'deleted'") }, as: :context, inverse_of: :context, class_name: "Assignment"
  has_many :all_attachments, as: "context", class_name: "Attachment"
  has_many :folders, -> { order("folders.name") }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :active_folders, -> { where("folders.workflow_state<>'deleted'").order("folders.name") }, class_name: "Folder", as: :context, inverse_of: :context
  has_many :submissions_folders, -> { where.not(folders: { submission_context_code: nil }) }, as: :context, inverse_of: :context, class_name: "Folder"
  has_many :collaborators
  has_many :external_feeds, as: :context, inverse_of: :context, dependent: :destroy
  has_many :messages, as: :context, inverse_of: :context, dependent: :destroy
  belongs_to :wiki
  has_many :wiki_pages, as: :context, inverse_of: :context
  has_many :wiki_page_lookups, as: :context, inverse_of: :context
  has_many :web_conferences, as: :context, inverse_of: :context, dependent: :destroy
  has_many :collaborations, -> { order(Arel.sql("collaborations.title, collaborations.created_at")) }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :media_objects, as: :context, inverse_of: :context
  has_many :content_migrations, as: :context, inverse_of: :context
  has_many :content_exports, as: :context, inverse_of: :context
  has_many :usage_rights, as: :context, inverse_of: :context, class_name: "UsageRights", dependent: :destroy
  belongs_to :avatar_attachment, class_name: "Attachment"
  belongs_to :leader, class_name: "User"
  has_many :lti_resource_links,
           as: :context,
           inverse_of: :context,
           class_name: "Lti::ResourceLink",
           dependent: :destroy

  before_validation :ensure_defaults
  before_save :update_max_membership_from_group_category

  after_create :refresh_group_discussion_topics
  after_save :touch_context, if: :saved_change_to_workflow_state?

  after_update :clear_cached_short_name, if: :saved_change_to_name?

  delegate :time_zone, to: :context
  delegate :usage_rights_required?, to: :context
  delegate :allow_student_anonymous_discussion_topics, to: :context

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

  def refresh_group_discussion_topics
    if group_category
      group_category.discussion_topics.active.each(&:update_subtopics)
    end
  end

  def includes_user?(user, membership_scope = group_memberships)
    return false if user.nil? || user.new_record?

    membership_scope.where(user_id: user).exists?
  end

  alias_method :participating_users_association, :participating_users

  def participating_users(user_ids = nil)
    if user_ids
      participating_users_association.where(id: user_ids)
    else
      participating_users_association
    end
  end

  def participating_users_in_context(user_ids = nil, sort: false, include_inactive_users: false)
    users = participating_users(user_ids)
    users = users.order_by_sortable_name if sort
    return users unless !include_inactive_users && (context.is_a? Course)

    context.participating_users(users.pluck(:id))
  end

  def all_real_students
    return context.all_real_students.where(users: { id: group_memberships.select(:user_id) }) if context.respond_to? :all_real_students

    users
  end

  def all_real_student_enrollments
    return context.all_real_student_enrollments.where(user_id: group_memberships.select(:user_id)) if context.respond_to? :all_real_student_enrollments

    group_memberships
  end

  def wiki
    return super if wiki_id

    Wiki.wiki_for_context(self)
  end

  def auto_accept?
    group_category&.allows_multiple_memberships? &&
      join_level == "parent_context_auto_join"
  end

  def allow_join_request?
    group_category&.allows_multiple_memberships? &&
      ["parent_context_auto_join", "parent_context_request"].include?(join_level)
  end

  def allow_self_signup?(user)
    group_category &&
      (group_category.unrestricted_self_signup? ||
        (group_category.restricted_self_signup? && has_common_section_with_user?(user)))
  end

  def full?
    !student_organized? && ((!max_membership && group_category_limit_met?) || (max_membership && participating_users.size >= max_membership))
  end

  def group_category_limit_met?
    group_category&.group_limit && participating_users.size >= group_category.group_limit
  end

  def context_external_tools
    ContextExternalTool.none
  end

  private :group_category_limit_met?

  def student_organized?
    group_category&.student_organized?
  end

  def update_max_membership_from_group_category
    if (!max_membership || max_membership == 0) && group_category && group_category.group_limit
      self.max_membership = group_category.group_limit
    end
  end

  def free_association?(user)
    auto_accept? || allow_join_request? || allow_self_signup?(user)
  end

  def allow_student_forum_attachments
    context.respond_to?(:allow_student_forum_attachments) && context.allow_student_forum_attachments
  end

  def participants(opts = {})
    users = participating_users.distinct.all
    if opts[:include_observers] && context.is_a?(Course)
      (users + User.observing_students_in_course(users, context)).flatten.uniq
    else
      users
    end
  end

  def context_code
    raise "DONT USE THIS, use .short_name instead" unless Rails.env.production?
  end

  def inactive?
    context.deleted? || (context.is_a?(Course) && context.inactive?)
  end

  def context_available?
    return false unless context

    case context
    when Course
      context.available? && (!context.respond_to?(:concluded?) || !context.concluded?)
    else
      true
    end
  end

  def appointment_context_codes
    { primary: [context_string], secondary: [group_category.asset_string] }
  end

  def membership_for_user(user)
    group_memberships.where(user_id: user).first if user
  end

  def has_member?(user)
    return false unless user.present?

    if group_memberships.loaded?
      group_memberships.to_a.find { |gm| gm.accepted? && gm.user_id == user.id }
    else
      participating_group_memberships.where(user_id: user).first
    end
  end

  def has_moderator?(user)
    return false unless user.present?
    if group_memberships.loaded?
      return group_memberships.to_a.find { |gm| gm.accepted? && gm.user_id == user.id && gm.moderator }
    end

    participating_group_memberships.moderators.where(user_id: user).first
  end

  def should_add_creator?(creator)
    group_category &&
      (group_category.communities? || (group_category.student_organized? && context.user_is_student?(creator)))
  end

  def submission?
    if context_type == "Course"
      assignments = Assignment.for_group_category(group_category_id).active
      return Submission.active.where(group_id: id, assignment_id: assignments).exists?
    end
    false
  end

  def short_name
    name
  end

  def self.find_all_by_context_code(codes)
    ids = codes.filter_map { |c| c.match(/\Agroup_(\d+)\z/)[1] rescue nil }
    Group.find(ids)
  end

  def self.not_in_group_sql_fragment(groups)
    return nil if groups.empty?

    sanitize_sql([<<~SQL.squish, groups])
      NOT EXISTS (SELECT * FROM #{GroupMembership.quoted_table_name} gm
      WHERE gm.user_id = users.id AND
      gm.workflow_state != 'deleted' AND
      gm.group_id IN (?))
    SQL
  end

  workflow do
    state :available
    state :deleted
  end

  def active?
    available?
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = "deleted"
    self.deleted_at = Time.now.utc
    save
  end

  def restore
    self.workflow_state = "available"
    self.deleted_at = nil
    save!
  end

  Bookmarker = BookmarkedCollection::SimpleBookmarker.new(Group, :name, :id)

  scope :active, -> { where("groups.workflow_state<>'deleted'") }
  scope :by_name, -> { order(Bookmarker.order_by) }
  scope :uncategorized, -> { where(groups: { group_category_id: nil }) }

  def potential_collaborators
    if context.is_a?(Course)
      # >99.9% of groups have fewer than 100 members
      User.where(id: participating_users_in_context.pluck(:id) + context.participating_admins.pluck(:id))
    else
      participating_users
    end
  end

  def full_name
    res = before_label(name) + " "
    res += (context.course_code rescue context.name) if context
    res
  end

  def to_atom
    {
      title: name,
      updated: updated_at,
      published: created_at,
      link: "/groups/#{id}"
    }
  end

  # this method is idempotent
  def add_user(user, new_record_state = nil, moderator = nil)
    return nil unless user

    attrs = { user:, moderator: !!moderator }
    new_record_state ||= { "invitation_only" => "invited",
                           "parent_context_request" => "requested",
                           "parent_context_auto_join" => "accepted" }[join_level]
    attrs[:workflow_state] = new_record_state if new_record_state

    member = nil
    GroupMembership.unique_constraint_retry do
      if (member = group_memberships.where(user_id: user).first)
        member.workflow_state = new_record_state unless member.active?
        # only update moderator if true/false is explicitly passed in
        member.moderator = moderator unless moderator.nil?
        member.save if member.changed?
      else
        member = group_memberships.create(attrs)
      end
    end
    # permissions for this user in the group are probably different now
    clear_permissions_cache(user)
    member
  end

  def set_users(users)
    user_ids = users.map(&:id)
    memberships = []
    transaction do
      group_memberships.where.not(user_id: user_ids).destroy_all
      users.each do |user|
        memberships << invite_user(user)
      end
    end
    memberships
  end

  def broadcast_data
    if context_type == "Course"
      { course_id: context_id, root_account_id: }
    else
      {}
    end
  end

  def bulk_add_users_to_group(users, options = {})
    return if users.empty?

    user_ids = users.map(&:id)
    old_group_memberships = group_memberships.where(user_id: user_ids).to_a
    bulk_insert_group_memberships(users, options)
    all_group_memberships = group_memberships.where(user_id: user_ids)
    new_group_memberships = all_group_memberships - old_group_memberships
    new_group_memberships.sort_by!(&:user_id)
    users.sort_by!(&:id)
    User.clear_cache_keys(user_ids, :groups)
    users.each { |user| clear_permissions_cache(user) }

    if context_available?
      notification_name = options[:notification_name] || "New Context Group Membership"
      notification = BroadcastPolicy.notification_finder.by_name(notification_name)

      users.each_with_index do |user, index|
        BroadcastPolicy.notifier.delay(priority: Delayed::LOW_PRIORITY)
                       .send_notification(
                         new_group_memberships[index],
                         notification_name.parameterize.underscore.to_sym,
                         notification,
                         [user],
                         broadcast_data
                       )
      end
    end
    new_group_memberships
  end

  def bulk_insert_group_memberships(users, options = {})
    current_time = Time.now
    options = {
      group_id: id,
      workflow_state: "accepted",
      moderator: false,
      created_at: current_time,
      updated_at: current_time,
      root_account_id:
    }.merge(options)
    GroupMembership.bulk_insert(users.map do |user|
      options.merge({ user_id: user.id, uuid: CanvasSlug.generate_securish_uuid })
    end)
  end

  def invite_user(user)
    add_user(user, "invited")
  end

  def request_user(user)
    add_user(user, "requested")
  end

  def invitees=(params)
    invitees = []
    (params || {}).each do |key, val|
      if context
        invitees << context.users.where(id: key.to_i).first if val != "0"
      elsif val != "0"
        invitees << User.where(id: key.to_i).first
      end
    end
    invitees.compact.filter_map { |i| invite_user(i) }
  end

  def peer_groups
    return [] if !context || !group_category || group_category.allows_multiple_memberships?

    group_category.groups.where("id<>?", self).to_a
  end

  def ensure_defaults
    self.name ||= CanvasSlug.generate_securish_uuid
    self.uuid ||= CanvasSlug.generate_securish_uuid
    self.group_category ||= GroupCategory.student_organized_for(context)
    self.join_level ||= "invitation_only"
    self.is_public ||= false
    self.is_public = false unless self.group_category.try(:communities?)
    set_default_account
  end
  private :ensure_defaults

  def set_default_account
    case context
    when Course
      self.account = context.account
    when Account
      self.account = context
    end
  end

  # update root account when account changes
  def account=(new_account)
    self.account_id = new_account.id
  end

  def account_id=(new_account_id)
    write_attribute(:account_id, new_account_id)
    if account_id_changed?
      self.root_account = reload_account&.root_account
    end
  end

  # if you modify this set_policy block, note that we've denormalized this
  # permission check for efficiency -- see User#cached_contexts
  set_policy do
    # Participate means the user is connected to the group somehow and can be
    given { |user| user && can_participate?(user) && has_member?(user) }
    can :participate and
      can :manage_calendar and
      can :manage_content and
      can :manage_course_content_add and
      can :manage_course_content_edit and
      can :manage_course_content_delete and
      can :manage_files_add and
      can :manage_files_edit and
      can :manage_files_delete and
      can :manage_wiki_create and
      can :manage_wiki_delete and
      can :manage_wiki_update and
      can :post_to_forum and
      can :create_collaborations and
      can :create_forum

    # Course-level groups don't grant any permissions besides :participate (because for a teacher to add a student to a
    # group, the student must be able to :participate, and the teacher should be able to add students while the course
    # is unpublished and therefore unreadable to said students) unless their containing context can be read by the user
    # in question
    given { |user, session| context.is_a?(Account) || context&.grants_right?(user, session, :read) || false }

    use_additional_policy do
      given { |user| user && has_member?(user) }
      can %i[
        read_forum
        read
        read_announcements
        read_roster
        view_unpublished_items
        read_files
      ]

      given do |user, session|
        user && has_member?(user) &&
          (!context || context.is_a?(Account) || context.grants_any_right?(user, session, :send_messages, :send_messages_all))
      end
      can :send_messages and can :send_messages_all

      # if I am a member of this group and I can moderate_forum in the group's context
      # (makes it so group members cant edit each other's discussion entries)
      given { |user, session| user && has_member?(user) && (!context || context.grants_right?(user, session, :moderate_forum)) }
      can :moderate_forum

      given { |user| user && has_moderator?(user) }
      can :delete and
        can :manage and
        can :manage_admin_users and
        can :allow_course_admin_actions and
        can :manage_students and
        can :moderate_forum and
        can :update

      given { |user| user && leader == user }
      can :update

      given { group_category.try(:communities?) }
      can :create

      given { |user, session| context&.grants_right?(user, session, :participate_as_student) }
      can :participate_as_student

      given { |user, session| grants_right?(user, session, :participate_as_student) && context.allow_student_organized_groups }
      can :create

      #################### Begin legacy permission block #########################

      given do |user, session|
        !context.root_account.feature_enabled?(:granular_permissions_manage_groups) &&
          context.grants_right?(user, session, :manage_groups)
      end
      can %i[
        create
        create_collaborations
        delete
        manage
        manage_admin_users
        allow_course_admin_actions
        manage_calendar
        manage_content
        manage_course_content_add
        manage_course_content_edit
        manage_course_content_delete
        manage_files_add
        manage_files_edit
        manage_files_delete
        manage_students
        manage_wiki_create
        manage_wiki_delete
        manage_wiki_update
        moderate_forum
        post_to_forum
        create_forum
        read
        read_forum
        read_announcements
        read_roster
        send_messages
        send_messages_all
        update
        view_unpublished_items
        read_files
      ]

      ##################### End legacy permission block ##########################

      given do |user, session|
        context.root_account.feature_enabled?(:granular_permissions_manage_groups) &&
          context.grants_right?(user, session, :manage_groups_add)
      end
      can %i[read read_files create]

      # permissions to update a group and manage actions within the context of a group
      given do |user, session|
        context.root_account.feature_enabled?(:granular_permissions_manage_groups) &&
          context.grants_right?(user, session, :manage_groups_manage)
      end
      can %i[
        read
        update
        create_collaborations
        manage
        manage_admin_users
        allow_course_admin_actions
        manage_calendar
        manage_content
        manage_course_content_add
        manage_course_content_edit
        manage_course_content_delete
        manage_files_add
        manage_files_edit
        manage_files_delete
        manage_students
        manage_wiki_create
        manage_wiki_delete
        manage_wiki_update
        moderate_forum
        post_to_forum
        create_forum
        read_forum
        read_announcements
        read_roster
        send_messages
        send_messages_all
        view_unpublished_items
        read_files
      ]

      given do |user, session|
        context.root_account.feature_enabled?(:granular_permissions_manage_groups) &&
          context.grants_right?(user, session, :manage_groups_delete)
      end
      can %i[read read_files delete]

      given { |user, session| context&.grants_all_rights?(user, session, :read_as_admin, :post_to_forum) }
      can :post_to_forum

      given { |user, session| context&.grants_all_rights?(user, session, :read_as_admin, :create_forum) }
      can :create_forum

      given { |user, session| context&.grants_right?(user, session, :view_group_pages) }
      can %i[read read_forum read_announcements read_roster read_files]

      # Join is participate + the group being in a state that allows joining directly (free_association)
      given { |user| user && can_participate?(user) && free_association?(user) }
      can :join and can :read_roster

      given { |user| user && (self.group_category.try(:allows_multiple_memberships?) || allow_self_signup?(user)) }
      can :leave

      #################### Begin legacy permission block #########################
      given do |user, session|
        !context.root_account.feature_enabled?(:granular_permissions_manage_course_content) &&
          grants_right?(user, session, :manage_content) && context &&
          context.grants_right?(user, session, :create_conferences)
      end
      can :create_conferences
      ##################### End legacy permission block ##########################

      given do |user, session|
        context.root_account.feature_enabled?(:granular_permissions_manage_course_content) &&
          grants_right?(user, session, :manage_course_content_add) && context &&
          context.grants_right?(user, session, :create_conferences)
      end
      can :create_conferences

      given { |user, session| context&.grants_right?(user, session, :read_as_admin) }
      can :read_as_admin

      given { |user, session| context&.grants_right?(user, session, :read_sis) }
      can :read_sis

      given { |user, session| context&.grants_right?(user, session, :view_user_logins) }
      can :view_user_logins

      given { |user, session| context&.grants_right?(user, session, :read_email_addresses) }
      can :read_email_addresses
    end
  end

  def users_visible_to(user, opts = {})
    return users.none unless grants_right?(user, :read)

    opts[:include_inactive] ? users : participating_users_in_context
  end

  # Helper needed by several permissions, use grants_right?(user, :participate)
  def can_participate?(user)
    return true if can_participate
    return false unless user.present? && context.present?
    return true if self.group_category.try(:communities?)

    case context
    when Course
      return context.enrollments.not_fake.where(user_id: user.id).active_by_date.exists?
    when Account
      return context.root_account.user_account_associations.where(user_id: user.id).exists?
    end

    false
  end

  def can_join?(user)
    if context.is_a?(Course)
      context.enrollments.not_fake.except(:preload).where(user_id: user.id).exists?
    else
      can_participate?(user)
    end
  end

  def user_can_manage_own_discussion_posts?(user)
    return true unless context.is_a?(Course)

    context.user_can_manage_own_discussion_posts?(user)
  end

  def is_a_context?
    true
  end

  def members_json_cached
    Rails.cache.fetch(["group_members_json", self].cache_key) do
      users.map { |u| u.group_member_json(context) }
    end
  end

  def members_count_cached
    Rails.cache.fetch(["group_members_count", self].cache_key) do
      members_json_cached.length
    end
  end

  def members_count
    participating_group_memberships.count
  end

  def quota
    storage_quota || account.default_group_storage_quota || self.class.default_storage_quota
  end

  def self.default_storage_quota
    Setting.get("group_default_quota", 50.megabytes.to_s).to_i
  end

  def storage_quota_mb
    quota / 1.megabyte
  end

  def storage_quota_mb=(val)
    self.storage_quota = val.try(:to_i).try(:megabytes)
  end

  TAB_HOME, TAB_PAGES, TAB_PEOPLE, TAB_DISCUSSIONS, TAB_FILES,
    TAB_CONFERENCES, TAB_ANNOUNCEMENTS, TAB_PROFILE, TAB_SETTINGS, TAB_COLLABORATIONS,
    TAB_COLLABORATIONS_NEW = *1..20
  def tabs_available(user = nil, *)
    available_tabs = [
      { id: TAB_HOME,          label: t("#group.tabs.home", "Home"), css_class: "home", href: :group_path },
      { id: TAB_ANNOUNCEMENTS, label: t("#tabs.announcements", "Announcements"), css_class: "announcements", href: :group_announcements_path },
      { id: TAB_PAGES,         label: t("#group.tabs.pages", "Pages"), css_class: "pages", href: :group_wiki_path },
      { id: TAB_PEOPLE,        label: t("#group.tabs.people", "People"), css_class: "people", href: :group_users_path },
      { id: TAB_DISCUSSIONS,   label: t("#group.tabs.discussions", "Discussions"), css_class: "discussions", href: :group_discussion_topics_path },
      { id: TAB_FILES,         label: t("#group.tabs.files", "Files"), css_class: "files", href: :group_files_path },
    ]

    if user && grants_right?(user, :read)
      available_tabs << { id: TAB_CONFERENCES, label: WebConference.conference_tab_name, css_class: "conferences", href: :group_conferences_path }
      available_tabs << { id: TAB_COLLABORATIONS, label: t("#tabs.collaborations", "Collaborations"), css_class: "collaborations", href: :group_collaborations_path }
      available_tabs << { id: TAB_COLLABORATIONS_NEW, label: t("#tabs.collaborations", "Collaborations"), css_class: "collaborations", href: :group_lti_collaborations_path }
    end

    available_tabs
  end

  def self.serialization_excludes
    [:uuid]
  end

  def allow_media_comments?
    true
  end

  def as_json(options = nil)
    json = super(options)
    if json && json["group"]
      # remove anything coming automatically from deprecated db column
      json["group"].delete("category")
      if self.group_category
        # put back version from association
        json["group"]["group_category"] = self.group_category.name
      end
    end
    json
  end

  def has_common_section?
    context.is_a?(Course) &&
      context.course_sections.active.any? { |section| section.common_to_users?(users) }
  end

  def has_common_section_with_user?(user)
    return false unless context.is_a?(Course)

    users = self.users.where(id: context.enrollments.active_or_pending.select(:user_id)) + [user]
    context.course_sections.active.any? { |section| section.common_to_users?(users) }
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

  def grading_periods?
    !!context.try(:grading_periods?)
  end

  def conditional_release?
    !!context.try(:conditional_release?)
  end

  def serialize_permissions(permissions_hash, user, session)
    permissions_hash.merge(
      create_discussion_topic: DiscussionTopic.context_allows_user_to_create?(self, user, session),
      create_announcement: Announcement.context_allows_user_to_create?(self, user, session)
    )
  end

  def content_exports_visible_to(user)
    content_exports.where(user_id: user)
  end

  def account_chain(include_site_admin: false, include_federated_parent: false)
    @account_chain ||= Account.account_chain(account_id).freeze

    # This implicitly includes add_federated_parent_to_chain
    if include_site_admin
      return @account_chain_with_site_admin ||= Account.add_site_admin_to_chain!(@account_chain.dup).freeze
    end

    if include_federated_parent
      return @account_chain_with_federated_parent ||= Account.add_federated_parent_to_chain!(@account_chain.dup).freeze
    end

    @account_chain
  end

  def sortable_name
    name
  end

  ##
  # Returns a boolean describing if the user passed in has marked this group
  # as a favorite.
  def favorite_for_user?(user)
    user.favorites.where(context_type: "Group", context_id: self).exists?
  end

  def submissions_folder(_course = nil)
    return @submissions_folder if @submissions_folder

    Folder.unique_constraint_retry do
      @submissions_folder = folders.where(parent_folder_id: Folder.root_folders(self).first, submission_context_code: "root")
                                   .first_or_create!(name: I18n.t("Submissions"))
    end
  end

  def grading_standard_or_default
    if context.respond_to?(:grading_standard_or_default)
      context.grading_standard_or_default
    else
      GradingStandard.default_instance
    end
  end
end
