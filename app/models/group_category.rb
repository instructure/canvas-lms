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

class GroupCategory < ActiveRecord::Base
  attr_accessible :name, :role, :context
  attr_reader :create_group_count
  attr_accessor :assign_unassigned_members

  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Course', 'Account']
  has_many :groups, :dependent => :destroy
  has_many :assignments, :dependent => :nullify
  has_many :progresses, :as => 'context', :dependent => :destroy
  has_one :current_progress, :as => 'context', :class_name => 'Progress', :conditions => "workflow_state IN ('queued','running')", :order => 'created_at'

  EXPORTABLE_ATTRIBUTES = [ :id, :context_id, :context_type, :name, :role,
    :deleted_at, :self_signup, :group_limit, :auto_leader
  ]

  EXPORTABLE_ASSOCIATIONS = [:context, :groups, :assignments]

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

    def uncategorized
      GroupCategory.new(name: name_for_role('uncategorized'), role: 'uncategorized')
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
                 context.group_categories.build(:name => name_for_role(role), :role => role)
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
    self.role.present?
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

  def configure_auto_leader(enabled, auto_leader_type)
    args = {enable_auto_leader: enabled, auto_leader_type: auto_leader_type}
    self.auto_leader = GroupCategories::Params.new(args).auto_leader
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
    groups.active.where("EXISTS (?)", GroupMembership.active.where("group_id=groups.id").where(user_id: user)).first
  end

  alias_method :destroy!, :destroy
  def destroy
    # TODO: this is kinda redundant with the :dependent => :destroy on the
    # groups association, but that doesn't get called since we override
    # destroy. also, the group destroy happens to be "soft" as well, and I
    # double checked groups.destroy_all does the right thing. :)
    groups.destroy_all
    self.deleted_at = Time.now.utc
    self.save
  end

  def distribute_members_among_groups(members, groups)
    if groups.empty? || members.empty?
      complete_progress
      return []
    end

    ##
    # new memberships to be returned
    new_memberships = []
    members_assigned_count = 0

    ##
    # shuffle for randomness
    members.shuffle!

    ##
    # pool fill algorithm:
    # 1) sort groups by member count
    #
    #  m   8  |
    #  e   7  |
    #  m   6  |                X  --- largest_group_size = 6
    #  b   5  |                X  --- currently_assigned_count = 14
    #  e   4  |             X  X  --- groups.size = 6
    #  r   3  |          X  X  X  --- member_count = ???
    #  s   2  |          X  X  X
    #      1  |_______X__X__X__X
    #           a  b  c  d  e  f
    #                groups
    groups.sort_by! {|group| group.users.size }

    ##
    # 2) ideally, the groups would have equal member counts,
    #    which would enable us to simply partition the members
    #    equally across each group.

    #    the simplest case occurs when we have enough members
    #    to fill the pool all the way to the largest group:
    #
    #    X: old member
    #    O: new member
    #
    #  m   8  |                   --- largest_group_size = 6
    #  e   7  |                   --- currently_assigned_count = 14
    #  m   6  | O  O  O  O  O  X  --- groups.size = 6
    #  b   5  | O  O  O  O  O  X  --- equalizing_count = largest_group_size * groups.size
    #  e   4  | O  O  O  O  X  X                       = 6 * 6 = 36
    #  r   3  | O  O  O  X  X  X  --- delta_required = equalizing_count - currently_assigned_count
    #  s   2  | O  O  O  X  X  X                     = 36 - 14 = 22
    #      1  |_O__O__X__X__X__X  --- member_count >= 22
    #           a  b  c  d  e  f
    #                groups
    #
    #   for member_counts > 22, partition extra members equally
    #   amongst the now equal groups
    member_count = members.size
    currently_assigned_count = groups.inject(0) {|sum, group| sum += group.users.size}
    largest_group_size = 0
    delta_required = 0

    ##
    # 3) however, we may not be able to fill to the largest group
    #    say member_count = 12
    #
    #    in this case, we should distribute the members like so:
    #
    #  m   8  |
    #  e   7  |
    #  m   6  |                X
    #  b   5  |                X
    #  e   4  | O  O  O  O  X  X
    #  r   3  | O  O  O  X  X  X
    #  s   2  | O  O  O  X  X  X
    #      1  |_O__O__X__X__X__X
    #           a  b  c  d  e  f
    #                groups
    #
    #   with only 12 members, we are unable to bring all groups up
    #   to 6 members each, the number of the users in the largest group (f)
    #
    #   that is, our member_count < delta_required
    #
    #   but fear not! we can pop off that last group and pretend it doesn't exist!
    #
    #  m   8  |                 --- largest_group_size = 4 (UPDATED to be the next largest)
    #  e   7  |                 --- currently_assigned_count = 8 (UPDATED)
    #  m   6  |                 --- groups.size = 5 (UPDATED -= 1)
    #  b   5  |                 --- equalizing_count = largest_group_size * groups.size
    #  e   4  | O  O  O  O  X                        = 4 * 5 = 20
    #  r   3  | O  O  O  X  X   --- delta_required = equalizing_count - currently_assigned_count
    #  s   2  | O  O  O  X  X                      = 20 - 8 = 12
    #      1  |_O__O__X__X__X   --- member_count = 12
    #           a  b  c  d  e
    #              groups

    ##
    # to summarize:
    #
    # if there are enough new members to equalize the groups,
    # equalize them and evenly distribute the surplus.
    #
    # if there are not enough, discard the fullest groups until there
    # are. equalize the remaining groups and distribute the surplus
    # members among them
    #
    # in all cases where things do not divide evenly, sprinkle the
    # remainder around

    loop do
      largest_group = groups.last
      largest_group_size = largest_group.users.size
      equalizing_count = largest_group_size * groups.size
      delta_required = equalizing_count - currently_assigned_count

      break if member_count > delta_required
      currently_assigned_count -= largest_group_size
      groups.pop
    end

    chunk_count, sprinkle_count = (member_count - delta_required).divmod(groups.size)

    groups.each do |group|
      sprinkle = sprinkle_count > 0 ? 1 : 0
      number_to_bring_base_equality = largest_group_size - group.users.size
      number_of_users_to_add = number_to_bring_base_equality + chunk_count + sprinkle
      ##
      # respect group limits!
      if self.group_limit
        slots_remaining = self.group_limit - group.users.size
        number_of_users_to_add = [slots_remaining, number_of_users_to_add].min
      end
      next if number_of_users_to_add <= 0

      new_members_to_add = members.pop(number_of_users_to_add)
      new_memberships.concat(group.bulk_add_users_to_group(new_members_to_add))
      members_assigned_count += number_of_users_to_add

      update_progress(members_assigned_count, member_count)
      break if members.empty?
      sprinkle_count -= 1
    end

    if self.auto_leader
      groups.each{|group| GroupLeadership.new(group).auto_assign!(auto_leader) }
    end

    if !groups.empty?
      Group.where(:id => groups.map(&:id)).update_all(:updated_at => Time.now.utc)
      if context_type == 'Course'
        DueDateCacher.recompute_course(context_id, Assignment.where(context_type: context_type, context_id: context_id, group_category_id: self).pluck(:id))
      end
    end
    complete_progress
    new_memberships
  end

  def create_group_count=(num)
    @create_group_count = num && num > 0 ?
      [num, Setting.get('max_groups_in_new_category', '200').to_i].min :
      nil
  end

  def auto_create_groups
    create_groups(@create_group_count) if @create_group_count
    assign_unassigned_members if @assign_unassigned_members && @create_group_count
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

  def assign_unassigned_members
    Delayed::Batch.serial_batch do
      distribute_members_among_groups(unassigned_users, groups.active)
    end
  end

  def assign_unassigned_members_in_background
    start_progress
    send_later_enqueue_args :assign_unassigned_members, :priority => Delayed::LOW_PRIORITY
  end

  set_policy do
    given { |user, session| context.grants_right?(user, session, :read) }
    can :read
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
    if group_limit_changed?
      groups.update_all(:max_membership => group_limit)
    end
  end
end
