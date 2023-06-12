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

  ENROLLMENT_TYPES = %w[StudentEnrollment TeacherEnrollment TaEnrollment DesignerEnrollment ObserverEnrollment].freeze

  DEFAULT_ACCOUNT_TYPE = "AccountMembership"
  ACCOUNT_TYPES = ["AccountAdmin", "AccountMembership"].freeze

  BASE_TYPES = (ACCOUNT_TYPES + ENROLLMENT_TYPES + [NULL_ROLE_TYPE]).freeze
  KNOWN_TYPES = (BASE_TYPES +
    %w[StudentViewEnrollment
       NilEnrollment
       teacher
       ta
       designer
       student
       observer]).freeze

  module AssociationHelper
    # this is an override to take advantage of built-in role caching since those are by far the most common
    def role
      return super if association(:role).loaded?

      self.role = shard.activate do
        # Use `default_canvas_role` even though `default_role` sounds better since default_role is a rails method in rails >= 6.1
        Role.get_role_by_id(read_attribute(:role_id)) || (respond_to?(:default_canvas_role) ? default_canvas_role : nil)
      end
    end

    def self.included(klass)
      klass.before_save(:resolve_cross_account_role)
    end

    def resolve_cross_account_role
      if will_save_change_to_role_id? && respond_to?(:root_account_id) && root_account_id && role.root_account_id != root_account_id
        self.role = role.role_for_root_account_id(root_account_id)
      end
    end
  end

  belongs_to :account
  belongs_to :root_account, class_name: "Account"
  has_many :role_overrides

  before_validation :infer_root_account_id, if: :belongs_to_account?

  validate :ensure_unique_name_for_account, if: :belongs_to_account?
  validates :name, :workflow_state, presence: true
  validates :account_id, presence: { if: :belongs_to_account? }

  validates :base_role_type, inclusion: { in: BASE_TYPES, message: -> { t("is invalid") } }
  validates :name, exclusion: { in: KNOWN_TYPES, unless: :built_in?, message: -> { t("is reserved") } }
  validate :ensure_non_built_in_name

  def role_for_root_account_id(target_root_account_id)
    if built_in? &&
       root_account_id != target_root_account_id &&
       (target_role = Role.get_built_in_role(name, root_account_id: target_root_account_id))
      target_role
    else
      self
    end
  end

  def ensure_unique_name_for_account
    if active?
      scope = Role.where("name = ? AND account_id = ? AND workflow_state = ?", name, account_id, "active")
      if new_record? ? scope.exists? : scope.where.not(id:).exists?
        errors.add(:label, t(:duplicate_role, "A role with this name already exists"))
        false
      end
    end
  end

  def ensure_non_built_in_name
    if !built_in? && Role.built_in_roles(root_account_id:).map(&:label).include?(name)
      errors.add(:label, t(:duplicate_role, "A role with this name already exists"))
      false
    end
  end

  def infer_root_account_id
    unless account
      errors.add(:account_id)
      throw :abort
    end
    self.root_account_id = account.resolved_root_account_id
  end

  include Workflow
  workflow do
    state :active do
      event :deactivate, transitions_to: :inactive
    end
    state :inactive do
      event :activate, transitions_to: :active
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
    RequestCache.cache("built_in_roles", root_account_id) do
      local_id, shard = Shard.local_id_for(root_account_id)
      (shard || Shard.current).activate do
        Role.where(workflow_state: "built_in", root_account_id: local_id).order(:id).to_a
      end
    end
  end

  def self.built_in_course_roles(root_account_id:)
    built_in_roles(root_account_id:).select(&:course_role?)
  end

  def self.visible_built_in_roles(root_account_id:)
    built_in_roles(root_account_id:).select(&:visible?)
  end

  def self.get_role_by_id(id)
    return nil unless id
    return nil if id.is_a?(String) && id !~ Api::ID_REGEX

    Role.where(id:).take # giving up on built-in role caching because it's silly now and we should just preload more
  end

  def self.get_built_in_role(name, root_account_id:)
    built_in_roles(root_account_id:).detect { |role| role.name == name }
  end

  def ==(other_role)
    if other_role.is_a?(Role) && built_in? && other_role.built_in?
      name == other_role.name # be equivalent even if they're on different shards/root_accounts
    else
      super
    end
  end

  def visible?
    active? || (built_in? && !["AccountMembership", "NoPermissions"].include?(name))
  end

  def account_role?
    ACCOUNT_TYPES.include?(base_role_type)
  end

  def course_role?
    ENROLLMENT_TYPES.include?(base_role_type)
  end

  def label
    if built_in?
      if course_role?
        RoleOverride.enrollment_type_labels.detect { |label| label[:name] == name }[:label].call
      elsif name == "AccountAdmin"
        RoleOverride::ACCOUNT_ADMIN_LABEL.call
      else
        name
      end
    else
      name
    end
  end

  # Should order course roles so we get "StudentEnrollment", custom student roles, "Teacher Enrollment", custom teacher roles, etc
  # then sort alphabetically within groups
  def display_sort_index
    group_order = if course_role?
                    (ENROLLMENT_TYPES.index(base_role_type) * 2) + (built_in? ? 0 : 1)
                  else
                    built_in? ? 0 : 1
                  end
    [group_order, Canvas::ICU.collation_key(label)]
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = "deleted"
    self.deleted_at = Time.now.utc
    save!
  end

  scope :not_deleted, -> { where("roles.workflow_state IN ('active', 'inactive')") }
  scope :deleted, -> { where(workflow_state: "deleted") }
  scope :active, -> { where(workflow_state: "active") }
  scope :inactive, -> { where(workflow_state: "inactive") }
  scope :for_courses, -> { where(base_role_type: ENROLLMENT_TYPES) }
  scope :for_accounts, -> { where(base_role_type: ACCOUNT_TYPES) }
  scope :full_account_admin, -> { where(base_role_type: "AccountAdmin") }
  scope :custom_account_admin_with_permission, lambda { |permission|
    where(base_role_type: "AccountMembership")
      .where("EXISTS (
      SELECT 1
      FROM #{RoleOverride.quoted_table_name}
      WHERE role_overrides.role_id = roles.id
        AND role_overrides.permission = ?
        AND role_overrides.enabled = ?
    )",
             permission,
             true)
  }

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
  def self.all_enrollment_roles_for_account(account, include_inactive = false)
    custom_roles = account.available_custom_course_roles(include_inactive)
    RoleOverride.enrollment_type_labels.map do |br|
      new = br.clone
      new[:id] = Role.get_built_in_role(br[:name], root_account_id: account.resolved_root_account_id).id
      new[:label] = br[:label].call
      new[:plural_label] = br[:plural_label].call
      new[:custom_roles] = custom_roles.select { |cr| cr.base_role_type == new[:base_role_name] }.map do |cr|
        { id: cr.id, base_role_name: cr.base_role_type, name: cr.name, label: cr.name, asset_string: cr.asset_string, workflow_state: cr.workflow_state }
      end
      new
    end
  end

  # returns same hash as all_enrollment_roles_for_account but adds enrollment
  # counts for the given course to each item
  def self.custom_roles_and_counts_for_course(course, user, include_inactive = false)
    users_scope = course.users_visible_to(user)
    built_in_role_ids = Role.built_in_course_roles(root_account_id: course.root_account_id).map(&:id)
    base_counts = users_scope.where(enrollments: { role_id: built_in_role_ids })
                             .group("enrollments.type").select("users.id").distinct.count
    role_counts = users_scope.where.not(enrollments: { role_id: built_in_role_ids })
                             .group("enrollments.role_id").select("users.id").distinct.count

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
    is_blueprint = context.is_a?(Course) && MasterCourses::MasterTemplate.is_master_course?(context)
    manageable = []
    if context.grants_right?(user, :manage_students) && !is_blueprint
      manageable += %w[StudentEnrollment ObserverEnrollment]
    end
    if context.grants_right?(user, :manage_admin_users)
      manageable += %w[TeacherEnrollment TaEnrollment DesignerEnrollment]
      manageable << "ObserverEnrollment" unless is_blueprint
    end
    manageable.uniq.sort
  end

  def self.add_delete_roles_by_user(user, context)
    is_blueprint = context.is_a?(Course) && MasterCourses::MasterTemplate.is_master_course?(context)
    addable = []
    deleteable = []
    addable += ["TeacherEnrollment"] if context.grants_right?(user, :add_teacher_to_course)
    deleteable += ["TeacherEnrollment"] if context.grants_right?(user, :remove_teacher_from_course)
    addable += ["TaEnrollment"] if context.grants_right?(user, :add_ta_to_course)
    deleteable += ["TaEnrollment"] if context.grants_right?(user, :remove_ta_from_course)
    addable += ["DesignerEnrollment"] if context.grants_right?(user, :add_designer_to_course)
    deleteable += ["DesignerEnrollment"] if context.grants_right?(user, :remove_designer_from_course)
    addable += ["StudentEnrollment"] if context.grants_right?(user, :add_student_to_course) && !is_blueprint
    deleteable += ["StudentEnrollment"] if context.grants_right?(user, :remove_student_from_course)
    addable += ["ObserverEnrollment"] if context.grants_right?(user, :add_observer_to_course) && !is_blueprint
    deleteable += ["ObserverEnrollment"] if context.grants_right?(user, :remove_observer_from_course)

    [addable, deleteable]
  end

  def self.compile_manageable_roles(role_data, user, context)
    # for use with the old sad enrollment dialog
    granular_admin = context.root_account.feature_enabled?(:granular_permissions_manage_users)
    manageable = manageable_roles_by_user(user, context) unless granular_admin
    addable, deleteable = add_delete_roles_by_user(user, context) if granular_admin
    role_data.each_with_object([]) do |role, roles|
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
          custom_role[:addable_by_user] = is_addable
          custom_role[:deleteable_by_user] = is_deleteable
        end
        roles << custom_role
      end
    end
  end

  def self.role_data(course, user, include_inactive = false)
    role_data = custom_roles_and_counts_for_course(course, user, include_inactive)
    compile_manageable_roles(role_data, user, course)
  end

  def self.course_role_data_for_account(account, user)
    role_data = all_enrollment_roles_for_account(account)
    compile_manageable_roles(role_data, user, account)
  end
end
