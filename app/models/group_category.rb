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
  has_many :groups, :dependent => :destroy
  has_many :assignments, :dependent => :nullify
  has_many :progresses, :as => 'context', :dependent => :destroy
  has_one :current_progress, :as => 'context', :class_name => 'Progress', :conditions => "workflow_state IN ('queued','running')", :order => 'created_at'

  after_save :auto_create_groups

  validates_each :name do |record, attr, value|
    next unless record.name_changed? || value.blank?
    max_len = maximum_string_length
    max_len -= record.create_group_count.to_s.length + 1 if record.create_group_count

    if value.blank?
      record.errors.add attr, t(:name_required, "Name is required")
    elsif GroupCategory.protected_name_for_context?(value, record.context)
      record.errors.add attr, t(:name_reserved, "%{name} is a reserved name.", name: value)
    elsif record.context && record.context.group_categories.other_than(record).find_by_name(value)
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

  scope :active, where(:deleted_at => nil)

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

    protected
    def name_for_role(role)
      case role
      when 'student_organized' then t('group_categories.student_organized', "Student Groups")
      when 'imported'          then t('group_categories.imported', "Imported Groups")
      when 'communities'       then t('group_categories.communities', "Communities")
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
      category = context.group_categories.find_by_role(role) ||
                 context.group_categories.build(:name => name_for_role(role), :role => role)
      category.save(false) if category.new_record?
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
    if !enabled
      self.self_signup = nil
    elsif restricted
      self.self_signup = 'restricted'
    else
      self.self_signup = 'enabled'
    end
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
    groups.active.to_a.find{ |g| g.users.include?(user) }
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
    return [] if groups.empty?
    new_memberships = []
    touched_groups = [].to_set

    groups_by_size = {}
    groups.each do |group|
      size = group.users.size
      groups_by_size[size] ||= []
      groups_by_size[size] << group
    end
    smallest_group_size = groups_by_size.keys.min
    members_count = members.size

    GroupMembership.skip_callback(:update_cached_due_dates) do
      members.sort_by{ rand }.each_with_index do |member, i|
        group = groups_by_size[smallest_group_size].first
        membership = group.add_user(member)
        if membership.valid?
          new_memberships << membership
          touched_groups << group.id

          # successfully added member to group, move it to the new size bucket
          groups_by_size[smallest_group_size].shift
          groups_by_size[smallest_group_size + 1] ||= []
          groups_by_size[smallest_group_size + 1] << group

          # was that the last group of that size?
          if groups_by_size[smallest_group_size].empty?
            groups_by_size.delete(smallest_group_size)
            smallest_group_size += 1
          end
        end
        update_progress(i, members_count)
      end
    end
    if !touched_groups.empty?
      Group.where(:id => touched_groups.to_a).update_all(:updated_at => Time.now.utc)
      if context_type == 'Course'
        DueDateCacher.recompute_course(context_id, Assignment.where(context_type: context_type, context_id: context_id, group_category_id: self).pluck(:id))
      end
    end
    complete_progress
    return new_memberships
  end

  def create_group_count=(num)
    @create_group_count = num && num > 0 ?
      [num, Setting.get('max_groups_in_new_category', '200').to_i].min :
      nil
  end

  def auto_create_groups
    create_groups(@create_group_count) if @create_group_count && @create_group_count > 0
    assign_unassigned_members if @assign_unassigned_members
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
    context.users_not_in_groups(groups.active)
  end

  def assign_unassigned_members
    distribute_members_among_groups(unassigned_users, groups.active)
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
    do_progress_update = i % 100 == 0
    if do_progress_update
      current_progress.calculate_completion! i, total
    end
  end

  def complete_progress
    return unless current_progress
    current_progress.complete
    current_progress.save!
    current_progress.reload
  end

end
