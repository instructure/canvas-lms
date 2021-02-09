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

class Role < ActiveRecord::Base
  NULL_ROLE_TYPE = "NoPermissions"

  ENROLLMENT_TYPES = ["StudentEnrollment", "TeacherEnrollment", "TaEnrollment", "DesignerEnrollment", "ObserverEnrollment"]

  DEFAULT_ACCOUNT_TYPE = 'AccountMembership'
  ACCOUNT_TYPES = ['AccountAdmin', 'AccountMembership']

  BASE_TYPES = (ACCOUNT_TYPES + ENROLLMENT_TYPES + [NULL_ROLE_TYPE]).freeze
  KNOWN_TYPES = (BASE_TYPES +
    ['StudentViewEnrollment',
     'TeacherlessStudentEnrollment',
     'NilEnrollment',
     'teacher', 'ta', 'designer', 'student', 'observer'
    ]).freeze

  module AssociationHelper
    # this is an override to take advantage of built-in role caching since those are by far the most common
    def role
      return super if association(:role).loaded?
      self.role = self.shard.activate do
        Role.get_role_by_id(read_attribute(:role_id)) || (self.respond_to?(:default_role) ? self.default_role : nil)
      end
    end

    def self.included(klass)
      klass.before_save(:resolve_cross_account_role)
    end

    def resolve_cross_account_role
      if self.will_save_change_to_role_id? && self.respond_to?(:root_account_id) && self.root_account_id && self.role.root_account_id != self.root_account_id
        self.role = self.role.role_for_root_account_id(self.root_account_id)
      end
    end
  end

  belongs_to :account
  belongs_to :root_account, :class_name => 'Account'
  has_many :role_overrides

  before_validation :infer_root_account_id, :if => :belongs_to_account?

  validate :ensure_unique_name_for_account, :if => :belongs_to_account?
  validates_presence_of :name, :workflow_state
  validates_presence_of :account_id, :if => :belongs_to_account?

  validates_inclusion_of :base_role_type, :in => BASE_TYPES, :message => 'is invalid'
  validates_exclusion_of :name, :in => KNOWN_TYPES, :unless => :built_in?, :message => 'is reserved'
  validate :ensure_non_built_in_name

  def role_for_root_account_id(target_root_account_id)
    if self.built_in? && self.root_account_id != target_root_account_id && target_role = Role.get_built_in_role(self.name, root_account_id: target_root_account_id)
      target_role
    else
      self
    end
  end

  def ensure_unique_name_for_account
    if self.active?
      scope = Role.where("name = ? AND account_id = ? AND workflow_state = ?", self.name, self.account_id, 'active')
      if self.new_record? ? scope.exists? : scope.where("id <> ?", self.id).exists?
        self.errors.add(:label, t(:duplicate_role, 'A role with this name already exists'))
        return false
      end
    end
  end

  def ensure_non_built_in_name
    if !self.built_in? && Role.built_in_roles(root_account_id: self.root_account_id).map(&:label).include?(self.name)
      self.errors.add(:label, t(:duplicate_role, 'A role with this name already exists'))
      return false
    end
  end

  def infer_root_account_id
    unless self.account
      self.errors.add(:account_id)
      throw :abort
    end
    self.root_account_id = self.account.root_account_id || self.account.id
  end

  include Workflow
  workflow do
    state :active do
      event :deactivate, :transitions_to => :inactive
    end
    state :inactive do
      event :activate, :transitions_to => :active
    end
    state :built_in # for previously built-in roles
    state :deleted
  end

  def belongs_to_account?
    !built_in? && !deleted?
  end

  def self.built_in_roles(root_account_id:)
    raise "root_account_id required" unless root_account_id
    # giving up on in-process built-in role caching because it's probably not really worth it anymore
    RequestCache.cache('built_in_roles', root_account_id) do
      local_id, shard = Shard.local_id_for(root_account_id)
      (shard || Shard.current).activate do
        Role.where(:workflow_state => 'built_in', :root_account_id => local_id).order(:id).to_a
      end
    end
  end

  def self.built_in_course_roles(root_account_id:)
    built_in_roles(root_account_id: root_account_id).select{|role| role.course_role?}
  end

  def self.visible_built_in_roles(root_account_id:)
    built_in_roles(root_account_id: root_account_id).select{|role| role.visible?}
  end

  def self.get_role_by_id(id)
    return nil unless id
    return nil if id.is_a?(String) && id !~ Api::ID_REGEX
    Role.where(:id => id).take # giving up on built-in role caching because it's silly now and we should just preload more
  end

  def self.get_built_in_role(name, root_account_id:)
    built_in_roles(root_account_id: root_account_id).detect{|role| role.name == name}
  end

  def ==(other_role)
    if other_role.is_a?(Role) && self.built_in? && other_role.built_in?
      return self.name == other_role.name # be equivalent even if they're on different shards/root_accounts
    else
      super
    end
  end

  def visible?
    self.active? || (self.built_in? && !["AccountMembership", "NoPermissions"].include?(self.name))
  end

  def account_role?
    ACCOUNT_TYPES.include?(base_role_type)
  end

  def course_role?
    ENROLLMENT_TYPES.include?(base_role_type)
  end

  def label
    if self.built_in?
      if self.course_role?
        RoleOverride.enrollment_type_labels.detect{|label| label[:name] == self.name}[:label].call
      elsif self.name == 'AccountAdmin'
        RoleOverride::ACCOUNT_ADMIN_LABEL.call
      else
        self.name
      end
    else
      self.name
    end
  end

  # Should order course roles so we get "StudentEnrollment", custom student roles, "Teacher Enrollment", custom teacher roles, etc
  def display_sort_index
    if self.course_role?
      ENROLLMENT_TYPES.index(self.base_role_type) * 2 + (self.built_in? ? 0 : 1)
    else
      self.built_in? ? 0 : 1
    end
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.deleted_at = Time.now.utc
    save!
  end

  scope :not_deleted, -> { where("roles.workflow_state IN ('active', 'inactive')") }
  scope :deleted, -> { where(:workflow_state => 'deleted') }
  scope :active, -> { where(:workflow_state => 'active') }
  scope :inactive, -> { where(:workflow_state => 'inactive') }
  scope :for_courses, -> { where(:base_role_type => ENROLLMENT_TYPES) }
  scope :for_accounts, -> { where(:base_role_type => ACCOUNT_TYPES) }
  scope :full_account_admin, -> { where(base_role_type: 'AccountAdmin') }
  scope :custom_account_admin_with_permission, -> (permission) do
    where(base_role_type: 'AccountMembership').
    where("EXISTS (
      SELECT 1
      FROM #{RoleOverride.quoted_table_name}
      WHERE role_overrides.role_id = roles.id
        AND role_overrides.permission = ?
        AND role_overrides.enabled = ?
    )", permission, true)
  end

  # Returns a list of hashes for each base enrollment type, and each will have a
  # custom_roles key, each will look like:
  # [{:base_role_name => "StudentEnrollment",
  #   :name => "StudentEnrollment",
  #   :label => "Student",
  #   :plural_label => "Students",
  #   :custom_roles =>
  #           [{:base_role_name => "StudentEnrollment",
  #             :name => "weirdstudent",
  #             :asset_string => "role_4"
  #             :label => "weirdstudent"}]},
  # ]
  def self.all_enrollment_roles_for_account(account, include_inactive=false)
    custom_roles = account.available_custom_course_roles(include_inactive)
    RoleOverride.enrollment_type_labels.map do |br|
      new = br.clone
      new[:id] = Role.get_built_in_role(br[:name], root_account_id: account.resolved_root_account_id).id
      new[:label] = br[:label].call
      new[:plural_label] = br[:plural_label].call
      new[:custom_roles] = custom_roles.select{|cr|cr.base_role_type == new[:base_role_name]}.map do |cr|
        {:id => cr.id, :base_role_name => cr.base_role_type, :name => cr.name, :label => cr.name, :asset_string => cr.asset_string, :workflow_state => cr.workflow_state}
      end
      new
    end
  end

  # returns same hash as all_enrollment_roles_for_account but adds enrollment
  # counts for the given course to each item
  def self.custom_roles_and_counts_for_course(course, user, include_inactive=false)
    users_scope = course.users_visible_to(user)
    built_in_role_ids = Role.built_in_course_roles(root_account_id: course.root_account_id).map(&:id)
    base_counts = users_scope.where('enrollments.role_id IN (?)', built_in_role_ids).
      group('enrollments.type').select('users.id').distinct.count
    role_counts = users_scope.where('enrollments.role_id NOT IN (?)', built_in_role_ids).
      group('enrollments.role_id').select('users.id').distinct.count

    @enrollment_types = Role.all_enrollment_roles_for_account(course.account, include_inactive)
    @enrollment_types.each do |base_type|
      base_type[:count] = base_counts[base_type[:name]] || 0
      base_type[:custom_roles].each do |custom_role|
        id = custom_role[:id]
        custom_role[:count] = role_counts[id] || 0
      end
    end

    @enrollment_types
  end

  def self.manageable_roles_by_user(user, context)
    manageable = []
    if context.grants_right?(user, :manage_students) && !(context.is_a?(Course) && MasterCourses::MasterTemplate.is_master_course?(context))
      manageable += ['StudentEnrollment', 'ObserverEnrollment']
      if context.is_a?(Course) && context.teacherless?
        manageable << 'TeacherEnrollment'
      end
    end
    if !context.root_account.feature_enabled?(:granular_permissions_manage_users) && context.grants_right?(user, :manage_admin_users)
      manageable += ['ObserverEnrollment', 'TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment']
    end
    manageable.uniq.sort
  end

  def self.add_delete_roles_by_user(user, context, other_manageable)
    addable = []
    deleteable = []
    addable += ['DesignerEnrollment'] if context.grants_right?(user, :add_designer_to_course)
    deleteable += ['DesignerEnrollment'] if context.grants_right?(user, :remove_designer_from_course)
    addable += ['ObserverEnrollment'] if context.grants_right?(user, :add_observer_to_course)
    deleteable += ['ObserverEnrollment'] if context.grants_right?(user, :remove_observer_from_course)
    addable += ['TaEnrollment'] if context.grants_right?(user, :add_ta_to_course)
    deleteable += ['TaEnrollment'] if context.grants_right?(user, :remove_ta_from_course)
    addable += ['TeacherEnrollment'] if context.grants_right?(user, :add_teacher_to_course)
    deleteable += ['TeacherEnrollment'] if context.grants_right?(user, :remove_teacher_from_course)

    # Hopefully these go away when the granular permissions for all roles are fully implemented.
    # Basically they're pulling in what :manage_students currently grants, as well as the old
    # behavior of :manage_admin_users, plus that odd case where if a course has no teacher then
    # anyone at all can add a teacher enrollment.
    if other_manageable.include? 'ObserverEnrollment'
      addable += ['ObserverEnrollment']
      deleteable += ['ObserverEnrollment']
    end

    if other_manageable.include? 'StudentEnrollment'
      addable += ['StudentEnrollment']
      deleteable += ['StudentEnrollment']
    end

    if other_manageable.include? 'TeacherEnrollment'
      addable += ['TeacherEnrollment']
      deleteable += ['TeacherEnrollment']
    end

    [addable.uniq, deleteable.uniq]
  end

  def self.compile_manageable_roles(role_data, user, context)
    # for use with the old sad enrollment dialog
    manageable = self.manageable_roles_by_user(user, context)
    granular_admin = context.root_account.feature_enabled?(:granular_permissions_manage_users)
    addable, deleteable = self.add_delete_roles_by_user(user, context, manageable) if granular_admin
    role_data.inject([]) { |roles, role|
      is_manageable = manageable.include?(role[:base_role_name]) unless granular_admin
      is_addable = addable.include?(role[:base_role_name]) if granular_admin
      is_deleteable = deleteable.include?(role[:base_role_name]) if granular_admin
      role[:manageable_by_user] = is_manageable unless granular_admin
      if granular_admin
        role[:addable_by_user] = is_addable
        role[:deleteable_by_user] = is_deleteable
      end
      custom_roles = role.delete(:custom_roles)
      roles << role

      custom_roles.each do |custom_role|
        custom_role[:manageable_by_user] = is_manageable unless granular_admin
        if granular_admin
          role[:addable_by_user] = is_addable
          role[:deleteable_by_user] = is_deleteable
        end
        roles << custom_role
      end
      roles
    }
  end

  def self.role_data(course, user, include_inactive=false)
    role_data = self.custom_roles_and_counts_for_course(course, user, include_inactive)
    self.compile_manageable_roles(role_data, user, course)
  end

  def self.course_role_data_for_account(account, user)
    role_data = self.all_enrollment_roles_for_account(account)
    self.compile_manageable_roles(role_data, user, account)
  end
end
