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

class GroupCategory < ActiveRecord::Base
  attr_reader :create_group_count
  attr_accessor :assign_unassigned_members, :group_by_section

  belongs_to :context, polymorphic: [:course, :account]
  belongs_to :sis_batch
  belongs_to :root_account, class_name: 'Account', inverse_of: :all_group_categories
  has_many :groups, :dependent => :destroy
  has_many :progresses, :as => 'context', :dependent => :destroy
  has_one :current_progress, -> { where(workflow_state: ['queued', 'running']).order(:created_at) }, as: :context, inverse_of: :context, class_name: 'Progress'

  before_validation :set_root_account_id
  validates_uniqueness_of :sis_source_id, scope: [:root_account_id], conditions: -> { where.not(sis_source_id: nil) }

  after_save :auto_create_groups
  after_update :update_groups_max_membership

  delegate :time_zone, :to => :context

  validates_each :name do |record, attr, value|
    next unless record.name_changed? || value.blank?
    max_len = maximum_string_length
    max_len -= record.create_group_count.to_s.length + 1 if record.create_group_count

    if value.blank?
      record.errors.add attr, t(:name_required, "Name is required")
    elsif GroupCategory.protected_name_for_context?(value, record.context)
      record.errors.add attr, t(:name_reserved, "%{name} is a reserved name.", name: value)
    elsif record.context && record.context.group_categories.other_than(record).where(name: value).exists?
      record.errors.add attr, t(:name_unavailable, "%{name} is already in use.", name: value)
    elsif value.length > max_len
      record.errors.add attr, t(:name_too_long, "Enter a shorter category name")
    end
  end

  validates_each :group_limit do |record, attr, value|
    next if value.nil?
    record.errors.add attr, t(:greater_than_1, "Must be greater than 1") unless value.to_i > 1
  end

  validates_each :self_signup do |record, attr, value|
    next unless record.self_signup_changed?
    next if value.blank?
    if !record.context.is_a?(Course) && record != communities_for(record.context)
      record.errors.add :enable_self_signup, t(:self_signup_for_courses, "Self-signup may only be enabled for course groups or communities")
    elsif value != 'enabled' && value != 'restricted'
      record.errors.add attr, t(:invalid_self_signup, "Self-signup needs to be one of the following values: %{values}", values: "null, 'enabled', 'restricted'")
    elsif record.restricted_self_signup? && record.has_heterogenous_group?
      record.errors.add :restrict_self_signup, t(:cant_restrict_self_signup, "Can't restrict self-signup while a mixed-section group exists in the category")
    end
  end

  validates_each :auto_leader do |record, attr, value|
    next unless record.auto_leader_changed?
    next if value.blank?
    unless ['first', 'random'].include?(value)
      record.errors.add attr, t(:invalid_auto_leader, "AutoLeader type needs to be one of the following values: %{values}", values: "null, 'first', 'random'")
    end
  end

  validates :context_id, presence: { message: t(:empty_course_or_account_id, 'Must have an account or course ID') }

  validates_each :context_type do |record, attr, value|
    unless ['Account', 'Course'].include?(value)
      record.errors.add attr, t(:group_category_must_have_context, 'Must belong to an account or course')
    end
  end

  Bookmarker = BookmarkedCollection::SimpleBookmarker.new(GroupCategory, :name, :id)

  scope :by_name, -> { order(Bookmarker.order_by) }
  scope :active, -> { where(:deleted_at => nil) }
  scope :other_than, lambda { |cat| where("group_categories.id<>?", cat.id || 0) }

  class << self
    def protected_name_for_context?(name, context)
      protected_names_for_context(context).include?(name)
    end

    def student_organized_for(context)
      role_category_for_context('student_organized', context)
    end

    def imported_for(context)
      role_category_for_context('imported', context)
    end

    def communities_for(context)
      role_category_for_context('communities', context)
    end

    def uncategorized(context: nil)
      gc = GroupCategory.new(name: name_for_role('uncategorized'), role: 'uncategorized', context: context)
      gc.set_root_account_id
      gc
    end

    protected
    def name_for_role(role)
      case role
      when 'student_organized' then t('group_categories.student_organized', "Student Groups")
      when 'imported'          then t('group_categories.imported', "Imported Groups")
      when 'communities'       then t('group_categories.communities', "Communities")
      when 'uncategorized'     then t('group_categories.uncategorized', "Uncategorized")
      end
    end

    def protected_roles_for_context(context)
      case context
      when Course  then ['student_organized', 'imported']
      when Account then ['communities', 'imported']
      else              []
      end
    end

    def protected_role_for_context?(role, context)
      protected_roles_for_context(context).include?(role)
    end

    def protected_names_for_context(context)
      protected_roles_for_context(context).map{ |role| name_for_role(role) }
    end

    def role_category_for_context(role, context)
      return unless context and protected_role_for_context?(role, context)
      category = context.group_categories.where(role: role).first ||
                 context.group_categories.build(name: name_for_role(role),
                                                role: role,
                                                root_account: context.root_account)
      category.save({:validate => false}) if category.new_record?
      category
    end
  end

  def communities?
    self.role == 'communities'
  end

  def student_organized?
    self.role == 'student_organized'
  end

  def protected?
    self.role.present? && self.role != 'imported'
  end

  # Group categories generally restrict students to only be in one group per
  # category, but we sort of cheat and implement student organized groups and
  # communities as one big group category, and then relax that membership
  # restriction.
  def allows_multiple_memberships?
    self.student_organized? || self.communities?
  end

  # this is preferred over setting self_signup directly. know that if you set
  # self_signup directly to anything other than nil (or ''), 'restricted', or
  # 'enabled', it will behave as if you used 'enabled'.
  def configure_self_signup(enabled, restricted)
    args = {enable_self_signup: enabled, restrict_self_signup: restricted}
    self.self_signup = GroupCategories::Params.new(args).self_signup
    self.save!
  end

  def self_signup?
    self.self_signup.present?
  end

  def unrestricted_self_signup?
    self.self_signup.present? && self.self_signup != 'restricted'
  end

  def restricted_self_signup?
    self.self_signup.present? && self.self_signup == 'restricted'
  end

  def has_heterogenous_group?
    # if it's not a course, we want the answer to be false. but that same
    # condition would may any group in the category say has_common_section?
    # false, and force us true. so we special case it, and get the short
    # circuit as a bonus.
    return false unless self.context && self.context.is_a?(Course)
    self.groups.any?{ |group| !group.has_common_section? }
  end

  def group_for(user)
    shard.activate do
      groups.active.where("EXISTS (?)", GroupMembership.active.where("group_id=groups.id").where(user_id: user)).take
    end
  end

  def is_member?(user)
    shard.activate do
      groups.active.where("EXISTS (?)", GroupMembership.active.where("group_id=groups.id").where(user_id: user)).exists?
    end
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    # TODO: this is kinda redundant with the :dependent => :destroy on the
    # groups association, but that doesn't get called since we override
    # destroy. also, the group destroy happens to be "soft" as well, and I
    # double checked groups.destroy_all does the right thing. :)
    groups.destroy_all
    self.deleted_at = Time.now.utc
    self.save
  end

  # We can't reassign existing group members, groups can have different maximum limits, and we want
  # the groups to be as evenly sized as possible. Think of this like pouring water into an oddly
  # shaped glass. The shape of the glass is determined by existing members and max group sizes,
  # sorted by the current group sizes. New members should trickle down to the lowest points of the
  # glass, but not fill any part of the glass higher than its limit.
  #
  # X = existing memberships: the bottom of the glass
  # ----- = the max membership of the group: the top of the glass (might be open with no limit)
  # blank = open space that we can fill with new memberships
  #
  #                         -----
  #             ----- -----
  #       -----               X     X
  # -----               X     X     X
  #               X     X     X     X
  #   X     X     X     X     X     X
  #  grp6  grp3  grp4  grp1  grp5  grp2
  #
  def distribute_members_among_groups(members, groups)
    if groups.empty? || members.empty?
      complete_progress
      return []
    end
    members = members.to_a
    groups = groups.to_a
    ActiveRecord::Associations::Preloader.new.preload(groups, :context)
    water_allocation = reserve_space_for_members_in_groups(members.size, groups)
    new_memberships = randomly_add_allocated_members_to_groups(members, groups, water_allocation)
    finish_group_member_assignment
    complete_progress
    new_memberships
  end

  def reserve_space_for_members_in_groups(member_count, groups)
    available_groups = groups.sort_by { |g| g.users.size }
    water_allocation = {} # group.id => number of new members
    groups.each { |g| water_allocation[g.id] = 0 }
    remaining_member_count = member_count
    while remaining_member_count > 0
      next_watermark = get_next_rectangular_watermark(available_groups, water_allocation)
      break if next_watermark[:height] == 0 # no more space for remaining members
      remaining_member_count -= allocate_members_into_watermark(
        remaining_member_count,
        next_watermark,
        water_allocation,
      )
    end
    water_allocation
  end

  def get_next_rectangular_watermark(available_groups, water_allocation)
    remove_full_groups(available_groups, water_allocation)
    return {height: 0, groups: []} if available_groups.empty?

    water_levels = chunk_groups_by_allocated_members(available_groups, water_allocation)

    lowest_level = water_levels[0]
    next_level = water_levels[1] # possibly nil
    max_watermark_height = next_level_watermark_height(lowest_level, next_level, water_allocation)
    capped_height = cap_height_with_max_membership_of_groups(lowest_level, max_watermark_height, water_allocation)
    {groups: lowest_level, height: capped_height}
  end

  def remove_full_groups(available_groups, water_allocation)
    available_groups.reject! do |grp|
      grp.max_membership && members_allocated_to_group(grp, water_allocation) >= grp.max_membership
    end
  end

  def chunk_groups_by_allocated_members(available_groups, water_allocation)
    chunked = available_groups.chunk do |grp|
      members_allocated_to_group(grp, water_allocation)
    end
    chunked.map { |_chunk_value, chunk| chunk }.to_a
  end

  def next_level_watermark_height(lowest_level, next_level, water_allocation)
    if next_level
      lowest_level_height = members_allocated_to_group(lowest_level[0], water_allocation)
      next_level_height = members_allocated_to_group(next_level[0], water_allocation)
      next_level_height - lowest_level_height
    else
      Float::INFINITY
    end
  end

  def cap_height_with_max_membership_of_groups(groups, max_group_height, water_allocation)
    groups.reduce(max_group_height) do |current_cap, grp|
      if grp.max_membership
        remaining_space_in_capped_group = grp.max_membership - members_allocated_to_group(grp, water_allocation)
        [current_cap, remaining_space_in_capped_group].min
      else
        current_cap
      end
    end
  end

  def members_allocated_to_group(grp, water_allocation)
    grp.users.size + water_allocation[grp.id]
  end

  def allocate_members_into_watermark(remaining_member_count, watermark, water_allocation)
    watermark_volume = watermark[:groups].size * watermark[:height]
    if watermark_volume < remaining_member_count
      completely_fill_finite_volume_with_members(watermark, water_allocation)
    else
      partially_fill_large_volume_with_all_remaining_members(remaining_member_count, watermark, water_allocation)
    end
  end

  def completely_fill_finite_volume_with_members(watermark, water_allocation)
    watermark[:groups].each do |grp|
      water_allocation[grp.id] += watermark[:height]
    end
    watermark[:groups].size * watermark[:height]
  end

  def partially_fill_large_volume_with_all_remaining_members(remaining_member_count, watermark, water_allocation)
    base_member_height = remaining_member_count / watermark[:groups].size
    leftover_count = remaining_member_count % watermark[:groups].size
    watermark[:groups].each_with_index do |grp, grp_index|
      water_allocation[grp.id] += base_member_height
      water_allocation[grp.id] += 1 if grp_index < leftover_count
    end
    remaining_member_count
  end

  def randomly_add_allocated_members_to_groups(members, groups, water_allocation)
    shuffled_members = members.shuffle
    groups.each_with_object([]) do |grp, new_memberships|
      new_group_member_count = water_allocation[grp.id]
      next if new_group_member_count == 0
      new_members = shuffled_members.pop(new_group_member_count)
      memberships = grp.bulk_add_users_to_group(new_members)
      new_memberships.concat(memberships)
      update_progress(new_memberships.size, members.size)
    end
  end

  def finish_group_member_assignment
    return unless self.reload.groups.any?

    if self.auto_leader
      self.groups.each do |group|
        GroupLeadership.new(group).auto_assign!(auto_leader)
      end
    end
    Group.where(id: groups).touch_all
    if context_type == 'Course'
      opts = { assignments: Assignment.where(context_type: context_type, context_id: context_id, group_category_id: self).pluck(:id) }
      DueDateCacher.recompute_course(context_id, opts)
    end
  end

  def distribute_members_among_groups_by_section
    # trying to make this work for new group sets is hard enough - i'm not even going to bother with ones with existing stuff
    if GroupMembership.active.where(:group_id => groups.active).exists?
      self.errors.add(:group_by_section, t("Groups must be empty to assign by section")); return
    end
    if groups.active.where.not(:max_membership => nil).exists?
      self.errors.add(:group_by_section, t("Groups cannot have size restrictions to assign by section")); return
    end

    group_count = groups.active.count
    section_count = self.context.enrollments.active_or_pending.where(:type => "StudentEnrollment").distinct.count(:course_section_id)
    return unless group_count > 0 && section_count > 0

    if group_count < section_count
      self.errors.add(:create_group_count, t("Must have at least as many groups as sections to assign by section")); return
    end

    GroupBySectionCalculator.new(self).distribute_members
    true
  end

  def create_group_count=(num)
    @create_group_count = num && num > 0 ?
      [num, Setting.get('max_groups_in_new_category', '200').to_i].min :
      nil
  end

  def set_root_account_id
    # context might be nil since this runs before validations.
    if self.context&.root_account
      root_account_id = self.context.root_account.id
      self.root_account_id = root_account_id
    end
  end

  def auto_create_groups
    create_groups(@create_group_count) if @create_group_count
    if @assign_unassigned_members && @create_group_count
      by_section = @group_by_section && self.context.is_a?(Course)
      assign_unassigned_members(by_section)
    end
    @create_group_count = @assign_unassigned_members = nil
  end

  def create_groups(num)
    group_name = name
    # TODO i18n
    group_name = group_name.singularize if I18n.locale == :en
    num.times do |idx|
      groups.create(name: "#{group_name} #{idx + 1}", :context => context)
    end
  end

  def unassigned_users
    context.users_not_in_groups(allows_multiple_memberships? ? [] : groups.active)
  end

  def assign_unassigned_members(by_section=false, updating_user: nil)
    Delayed::Batch.serial_batch do
      DueDateCacher.with_executing_user(updating_user) do
        if by_section
          distribute_members_among_groups_by_section
          finish_group_member_assignment
          if current_progress
            if self.errors.any?
              current_progress.message = self.errors.full_messages
              current_progress.fail
            else
              complete_progress
            end
          end
        else
          distribute_members_among_groups(unassigned_users, groups.active)
        end
      end
    end
  rescue => e
    if current_progress
      current_progress.message = "Error assigning members: #{e.message}"
      current_progress.fail
    end
  end

  def assign_unassigned_members_in_background(by_section=false, updating_user: nil)
    start_progress
    send_later_enqueue_args(:assign_unassigned_members, {:priority => Delayed::LOW_PRIORITY}, by_section, updating_user: updating_user)
  end

  def clone_groups_and_memberships(new_group_category)
    groups.preload(:group_memberships).find_each do |group|
      new_group = group.dup
      new_group.group_category = new_group_category
      [:sis_batch_id, :sis_source_id, :uuid, :wiki_id].each do |attr|
        new_group[attr] = nil
      end
      new_group.save!

      group.group_memberships.find_each do |group_membership|
        new_group_membership = group_membership.dup
        new_group_membership.uuid = nil
        new_group_membership.group = new_group
        new_group_membership.save!
      end
    end
  end

  set_policy do
    given { |user, session| context.grants_right?(user, session, :read) }
    can :read
  end

  def discussion_topics
    self.shard.activate do
      DiscussionTopic.where(context_type: self.context_type, context_id: self.context_id, group_category_id: self)
    end
  end

  def submission_ids_by_user_id(user_ids=nil)
    self.shard.activate do
      assignments = Assignment.active.where(:context_type => self.context_type, :context_id => self.context_id, :group_category_id => self.id)
      submissions = Submission.active.where(assignment_id: assignments, workflow_state: 'submitted')
      submissions = submissions.where(:user_id => user_ids) if user_ids
      rows = submissions.pluck(:id, :user_id)
      rows.each_with_object({}) do |row, obj|
        id, user_id = row
        obj[user_id] = (obj[user_id] || []).push(id)
      end
    end
  end

  protected

  def start_progress
    self.current_progress ||= progresses.build(:tag => 'assign_unassigned_members', :completion => 0)
    current_progress.start
  end

  def update_progress(i, total)
    return unless current_progress
    current_progress.calculate_completion! i, total
  end

  def complete_progress
    return unless current_progress
    current_progress.complete
    current_progress.save!
    current_progress.reload
  end

  def update_groups_max_membership
    if saved_change_to_group_limit?
      groups.update_all(:max_membership => group_limit)
    end
  end

  class GroupBySectionCalculator
    # this got too big and I didn't feel like stuffing it into a giant method anymore
    def initialize(category)
      @category = category
    end

    attr_accessor :users_by_section_id, :user_count, :groups

    def distribute_members
      @groups = @category.groups.active.to_a

      get_users_by_section_id
      determine_group_distribution
      assign_students_to_groups
    end

    def get_users_by_section_id
      # fetch and group users by section_id
      id_pairs = User.joins(:not_ended_enrollments).where(enrollments: {course_id: @category.context, type: 'StudentEnrollment'}).
        pluck("users.id, enrollments.course_section_id").uniq(&:first) # not even going to try to deal with multi-section students

      @users_by_section_id = {}
      all_users = User.where(:id => id_pairs.map(&:first)).index_by(&:id)
      @user_count = all_users.count
      id_pairs.each do |user_id, section_id|
        @users_by_section_id[section_id] ||= []
        @users_by_section_id[section_id] << all_users[user_id]
      end
    end

    def determine_group_distribution
      # try to figure out how to best split up the groups
      goal_group_size = [@user_count / @groups.count, 1].max # try to get groups with at least this size

      num_groups_assigned = 0
      user_counts = {}
      group_counts = {}

      @users_by_section_id.each do |section_id, sect_users|
        # first pass - give each section a base-level number of groups
        user_count = sect_users.count
        user_counts[section_id] = user_count

        group_count = [user_count / goal_group_size, 1].max # at least one group
        num_groups_assigned += group_count
        group_counts[section_id] = group_count
      end

      extra_groups = {}
      while num_groups_assigned != @groups.count # keep going until we get the levels just right
        if num_groups_assigned > @groups.count
          # we over-assigned because of sections with too few people (only one group) - so we'll have to steal one from a big section
          # preferably one that can take the hit the best - i.e. has the most groups currently and then fewest extra users
          big_section_id = group_counts.select{|k, count| count > 1}.sort_by{|k, count| [count, -1 * user_counts[k]]}.last.first
          group_counts[big_section_id] -= 1
          num_groups_assigned -= 1
        else
          # more likely will we have some extra groups now because of remainder students from our first pass
          # so at least one section will have to have some smaller groups now
          # best thing to do now is to find the group that can take the hit the easiest
          leftover_sec_id = group_counts.sort_by{|k, count| [-1 * (extra_groups[k] || 0), (user_counts[k].to_f / (count + 1)), k]}.last.first
          group_counts[leftover_sec_id] += 1
          extra_groups[leftover_sec_id] ||= 0
          extra_groups[leftover_sec_id] += 1
          num_groups_assigned += 1
        end
      end

      @group_distributions = {}
      group_counts.each do |section_id, num_groups|
        # turn them into an array of group sizes, e.g. 7 users into 3 groups becomes [3, 2, 2]
        dist = [user_counts[section_id] / num_groups] * num_groups # base
        (user_counts[section_id] % num_groups).times do |idx| # distribute remainder around
          dist[idx % num_groups] += 1
        end
        @group_distributions[section_id] = dist
      end
      if @group_distributions.values.map(&:count).sum != @groups.count || @group_distributions.any?{|k, v| v.sum != user_counts[k]}
        raise "user/group count mismatch" # we should make sure this works before going any further
      end
      @group_distributions
    end

    def assign_students_to_groups
      @group_distributions.each do |section_id, group_sizes|
        @users_by_section_id[section_id].shuffle!
        group_sizes.each do |group_size|
          group = @groups.pop
          group.bulk_add_users_to_group(@users_by_section_id[section_id].pop(group_size))
        end
      end
    end
  end
end
