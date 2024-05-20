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

class RoleOverride < ActiveRecord::Base
  extend RootAccountResolver
  belongs_to :context, polymorphic: [:account]

  belongs_to :role

  validates :enabled, inclusion: [true, false]
  validates :locked, inclusion: [true, false]

  validate :must_apply_to_something

  after_save :clear_caches

  resolves_root_account through: ->(record) { record.context.resolved_root_account_id }
  include Role::AssociationHelper

  def clear_caches
    RoleOverride.clear_caches(account, role)
  end

  def self.clear_caches(account, role)
    account.delay_if_production(singleton: "clear_downstream_role_caches:#{account.global_id}")
           .clear_downstream_caches(:role_overrides)
    role.touch
  end

  def must_apply_to_something
    errors.add(nil, "Must apply to something") unless applies_to_self? || applies_to_descendants?
  end

  def applies_to
    result = []
    result << :self if applies_to_self?
    result << :descendants if applies_to_descendants?
    result.presence
  end

  ACCOUNT_ADMIN_LABEL = -> { t("roles.account_admin", "Account Admin") }
  def self.account_membership_types(account)
    res = [{ id: Role.get_built_in_role("AccountAdmin", root_account_id: account.resolved_root_account_id).id,
             name: "AccountAdmin",
             base_role_name: Role::DEFAULT_ACCOUNT_TYPE,
             label: ACCOUNT_ADMIN_LABEL.call }]
    account.available_custom_account_roles.each do |r|
      res << { id: r.id, name: r.name, base_role_name: Role::DEFAULT_ACCOUNT_TYPE, label: r.name }
    end
    res
  end

  ENROLLMENT_TYPE_LABELS =
    [
      # StudentViewEnrollment permissions will mirror StudentPermissions
      { base_role_name: "StudentEnrollment", name: "StudentEnrollment", label: -> { t("roles.student", "Student") }, plural_label: -> { t("roles.students", "Students") } },
      { base_role_name: "TeacherEnrollment", name: "TeacherEnrollment", label: -> { t("roles.teacher", "Teacher") }, plural_label: -> { t("roles.teachers", "Teachers") } },
      { base_role_name: "TaEnrollment", name: "TaEnrollment", label: -> { t("roles.ta", "TA") }, plural_label: -> { t("roles.tas", "TAs") } },
      { base_role_name: "DesignerEnrollment", name: "DesignerEnrollment", label: -> { t("roles.designer", "Designer") }, plural_label: -> { t("roles.designers", "Designers") } },
      { base_role_name: "ObserverEnrollment", name: "ObserverEnrollment", label: -> { t("roles.observer", "Observer") }, plural_label: -> { t("roles.observers", "Observers") } }
    ].freeze
  def self.enrollment_type_labels
    ENROLLMENT_TYPE_LABELS
  end

  # Common set of granular permissions for checking rights against
  GRANULAR_FILE_PERMISSIONS = %i[manage_files_add manage_files_edit manage_files_delete].freeze
  GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS =
    %i[manage_course_content_add manage_course_content_edit manage_course_content_delete].freeze
  GRANULAR_MANAGE_GROUPS_PERMISSIONS = %i[manage_groups_add manage_groups_manage manage_groups_delete].freeze
  GRANULAR_MANAGE_LTI_PERMISSIONS = %i[manage_lti_add manage_lti_edit manage_lti_delete].freeze
  GRANULAR_MANAGE_USER_PERMISSIONS = %i[
    allow_course_admin_actions
    add_student_to_course
    add_teacher_to_course
    add_ta_to_course
    add_observer_to_course
    add_designer_to_course
    remove_student_from_course
    remove_teacher_from_course
    remove_ta_from_course
    remove_observer_from_course
    remove_designer_from_course
  ].freeze
  GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS = %i[
    manage_assignments
    manage_assignments_add
    manage_assignments_edit
    manage_assignments_delete
  ].freeze
  MANAGE_TEMPORARY_ENROLLMENT_PERMISSIONS = %i[
    temporary_enrollments_add
    temporary_enrollments_edit
    temporary_enrollments_delete
  ].freeze

  # immediately register stock canvas-lms permissions
  # NOTE: manage_alerts = Global Announcements and manage_interaction_alerts = Alerts
  # for legacy reasons
  # NOTE: if you add a permission, please also update the API documentation for
  # RoleOverridesController#add_role
  Permissions.register(
    {
      become_user: {
        label: -> { t("Act as users") },
        label_v2: -> { t("Users - act as") },
        account_only: :root,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      import_sis: {
        label: -> { t("Import SIS data") },
        label_v2: -> { t("SIS Data - import") },
        account_only: :root,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      manage_account_memberships: {
        label: -> { t("permissions.manage_account_memberships", "Add/remove other admins for the account") },
        label_v2: -> { t("Admins - add / remove") },
        available_to: [
          "AccountMembership"
        ],
        true_for: [
          "AccountAdmin"
        ],
        account_only: true
      },
      manage_account_settings: {
        label: -> { t("permissions.manage_account_settings", "Manage account-level settings") },
        label_v2: -> { t("Account-level settings - manage") },
        available_to: [
          "AccountMembership"
        ],
        true_for: [
          "AccountAdmin"
        ],
        account_only: true
      },
      manage_alerts: {
        label: -> { t("permissions.manage_announcements", "Manage global announcements") },
        label_v2: -> { t("Global Announcements - add / edit / delete") },
        account_only: true,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      manage_catalog: {
        label: -> { t("permissions.manage_catalog", "Manage catalog") },
        label_v2: -> { t("Catalog - manage") },
        account_only: true,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
        account_allows: ->(a) { a.settings[:catalog_enabled] }
      },
      # deprecated; legacy role override
      manage_courses: {
        label: -> { t("Manage ( add / edit / delete ) ") },
        label_v2: -> { t("Courses - add / edit / delete") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: ["AccountAdmin"],
        account_only: true,
        account_allows: ->(a) { !a.root_account.feature_enabled?(:granular_permissions_manage_courses) }
      },
      manage_courses_admin: {
        label: -> { t("Manage account level course actions") },
        label_v2: -> { t("Courses - manage / update") },
        group: "manage_courses",
        group_label: -> { t("Manage Courses") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: ["AccountAdmin"],
        account_only: true,
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_courses) }
      },
      manage_courses_add: {
        label: -> { t("Add courses") },
        label_v2: -> { t("Courses - add") },
        group: "manage_courses",
        group_label: -> { t("Manage Courses") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: %w[AccountAdmin],
        account_only: true,
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_courses) }
      },
      manage_courses_publish: {
        label: -> { t("Publish courses") },
        label_v2: -> { t("Courses - publish") },
        group: "manage_courses",
        group_label: -> { t("Manage Courses") },
        available_to: %w[
          AccountAdmin
          AccountMembership
          TeacherEnrollment
          TaEnrollment
          DesignerEnrollment
        ],
        true_for: %w[AccountAdmin TeacherEnrollment DesignerEnrollment],
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_courses) }
      },
      manage_courses_conclude: {
        label: -> { t("Conclude courses") },
        label_v2: -> { t("Courses - conclude") },
        group: "manage_courses",
        group_label: -> { t("Manage Courses") },
        available_to: %w[
          AccountAdmin
          AccountMembership
          TeacherEnrollment
          TaEnrollment
          DesignerEnrollment
        ],
        true_for: %w[AccountAdmin TeacherEnrollment DesignerEnrollment],
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_courses) }
      },
      manage_courses_reset: {
        label: -> { t("Reset courses") },
        label_v2: -> { t("Courses - reset") },
        group: "manage_courses",
        group_label: -> { t("Manage Courses") },
        available_to: %w[
          AccountAdmin
          AccountMembership
          TeacherEnrollment
          DesignerEnrollment
        ],
        true_for: %w[AccountAdmin],
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_courses) }
      },
      manage_courses_delete: {
        label: -> { t("Delete courses") },
        label_v2: -> { t("Courses - delete") },
        group: "manage_courses",
        group_label: -> { t("Manage Courses") },
        available_to: %w[
          AccountAdmin
          AccountMembership
          TeacherEnrollment
          DesignerEnrollment
        ],
        true_for: %w[AccountAdmin],
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_courses) }
      },
      manage_data_services: {
        label: -> { t("permissions.manage_data_services", "Manage data services") },
        label_v2: -> { t("Data Services - manage ") },
        account_only: true,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      manage_course_visibility: {
        label: -> { t("Change course visibility") },
        label_v2: -> { t("Courses - change visibility") },
        available_to: %w[
          AccountAdmin
          AccountMembership
          TeacherEnrollment
          TaEnrollment
          DesignerEnrollment
        ],
        true_for: %w[
          AccountAdmin
          TeacherEnrollment
          TaEnrollment
          DesignerEnrollment
        ]
      },
      manage_developer_keys: {
        label: -> { t("permissions.manage_developer_keys", "Manage developer keys") },
        label_v2: -> { t("Developer Keys - manage ") },
        account_only: true,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      moderate_user_content: {
        label: -> { t("permissions.moderate_user_content", "Moderate user content") },
        label_v2: -> { t("Users - moderate content") },
        account_only: true,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      view_feature_flags: {
        label: -> { t("View feature options at an account level") },
        label_v2: -> { t("Feature Options - view") },
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership]
      },
      manage_feature_flags: {
        label: -> { t("permissions.manage_feature_flags", "Enable or disable features at an account level") },
        label_v2: -> { t("Feature Options - enable / disable") },
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership]
      },
      manage_frozen_assignments: {
        label: -> { t("permissions.manage_frozen_assignment", "Manage (edit / delete) frozen assignments") },
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
        enabled_for_plugin: :assignment_freezer
      },
      manage_global_outcomes: {
        label: -> { t("permissions.manage_global_outcomes", "Manage global learning outcomes") },
        account_only: :site_admin,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      manage_jobs: {
        label: -> { t("permissions.managed_jobs", "Manage background jobs") },
        account_only: :site_admin,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      manage_release_notes: {
        label: -> { t("Manage release notes") },
        account_only: :site_admin,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      manage_master_courses: {
        label: -> { t("Blueprint Courses (create / edit / associate / delete)") },
        label_v2: -> { t("Blueprint Courses - add / edit / associate / delete") },
        available_to: [
          "AccountAdmin",
          "AccountMembership"
        ],
        account_only: true,
        true_for: [
          "AccountAdmin"
        ]
      },
      manage_role_overrides: {
        label: -> { t("permissions.manage_role_overrides", "Manage permissions") },
        label_v2: -> { t("Permissions - manage") },
        account_only: true,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountMembership]
      },
      manage_storage_quotas: {
        label: -> { t("permissions.manage_storage_quotas", "Manage storage quotas") },
        label_v2: -> { t("Storage Quotas - manage") },
        account_only: true,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership]
      },
      manage_sis: {
        label: -> { t("permissions.manage_sis", "Manage SIS data") },
        label_v2: -> { t("SIS Data - manage") },
        account_only: :root,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      manage_site_settings: {
        label: -> { t("permissions.manage_site_settings", "Manage site-wide and plugin settings") },
        account_only: :site_admin,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      manage_internal_settings: {
        label: -> { t("permissions.manage_internal_settings", "Manage environment-wide internal settings") },
        account_only: :site_admin,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      manage_user_logins: {
        label: -> { t("permissions.manage_user_logins", "Modify login details for users") },
        label_v2: -> { t("Users - manage login details") },
        available_to: [
          "AccountAdmin",
          "AccountMembership"
        ],
        account_only: :root,
        true_for: [
          "AccountAdmin"
        ]
      },
      manage_user_observers: {
        label: -> { t("permissions.manage_user_observers", "Manage observers for users") },
        label_v2: -> { t("Users - manage observers") },
        account_only: :root,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      read_course_content: {
        label: -> { t("permissions.read_course_content", "View course content") },
        label_v2: -> { t("Course Content - view") },
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership]
      },
      read_course_list: {
        label: -> { t("permissions.read_course_list", "View the list of courses") },
        label_v2: -> { t("Courses - view list") },
        account_only: true,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership]
      },
      read_messages: {
        label: -> { t("permissions.read_messages", "View notifications sent to users") },
        account_only: :site_admin,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      reset_any_mfa: {
        label: -> { t("Reset Multi-Factor Authentication") },
        account_only: :root,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
        account_allows: ->(a) { a.mfa_settings != :disabled }
      },
      view_course_changes: {
        label: -> { t("permissions.view_course_changes", "View Course Change Logs") },
        label_v2: -> { t("Courses - view change logs") },
        admin_tool: true,
        account_only: :root,
        available_to: [
          "AccountAdmin",
          "AccountMembership"
        ],
        true_for: ["AccountAdmin"]
      },
      view_error_reports: {
        label: -> { t("permissions.view_error_reports", "View error reports") },
        account_only: :site_admin,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      view_grade_changes: {
        label: -> { t("permissions.view_grade_changes", "View Grade Change Logs") },
        label_v2: -> { t("Grades - view change logs") },
        admin_tool: true,
        account_only: true,
        available_to: [
          "AccountAdmin",
          "AccountMembership"
        ],
        true_for: ["AccountAdmin"]
      },
      view_jobs: {
        label: -> { t("permissions.view_jobs", "View background jobs") },
        account_only: :site_admin,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      view_notifications: {
        label: -> { t("permissions.view_notifications", "View notifications") },
        label_v2: -> { t("Notifications - view") },
        admin_tool: true,
        account_only: true,
        available_to: [
          "AccountAdmin",
          "AccountMembership"
        ],
        true_for: [],
        account_allows: ->(acct) { acct.settings[:admins_can_view_notifications] }
      },
      view_statistics: {
        label: -> { t("permissions.view_statistics", "View statistics") },
        label_v2: -> { t("Statistics - view") },
        account_only: true,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership]
      },
      undelete_courses: {
        label: -> { t("permissions.undelete_courses", "Undelete courses") },
        label_v2: -> { t("Courses - undelete") },
        admin_tool: true,
        account_only: true,
        available_to: [
          "AccountAdmin",
          "AccountMembership"
        ],
        true_for: ["AccountAdmin"]
      },
      # deprecated
      change_course_state: {
        label: -> { t("permissions.change_course_state", "Change course state") },
        label_v2: -> { t("Course State - manage") },
        true_for: %w[AccountAdmin TeacherEnrollment DesignerEnrollment],
        available_to: %w[
          AccountAdmin
          AccountMembership
          TeacherEnrollment
          TaEnrollment
          DesignerEnrollment
        ],
        account_allows: ->(a) { !a.root_account.feature_enabled?(:granular_permissions_manage_courses) }
      },
      create_collaborations: {
        label: -> { t("permissions.create_collaborations", "Create student collaborations") },
        label_v2: -> { t("Student Collaborations - create") },
        available_to: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ]
      },
      create_conferences: {
        label: -> { t("permissions.create_conferences", "Create web conferences") },
        label_v2: -> { t("Web Conferences - create") },
        available_to: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ]
      },
      create_forum: {
        label: -> { t("Create new discussions") },
        label_v2: -> { t("Discussions - create") },
        available_to: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ],
        restrict_future_enrollments: true
      },
      generate_observer_pairing_code: {
        label: -> { t("Users - generate observer pairing codes for students") },
        true_for: %w[AccountAdmin],
        available_to: %w[TeacherEnrollment ObserverEnrollment TaEnrollment AccountAdmin AccountMembership DesignerEnrollment]
      },
      import_outcomes: {
        label: -> { t("Import learning outcomes") },
        label_v2: -> { t("Learning Outcomes - import") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ]
      },
      # lagacy role override
      lti_add_edit: {
        label: -> { t("LTI add and edit") },
        label_v2: -> { t("LTI - add / edit / delete") },
        available_to: %w[
          TeacherEnrollment
          TaEnrollment
          DesignerEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TeacherEnrollment
          TaEnrollment
          DesignerEnrollment
          AccountAdmin
        ],
        account_allows: ->(a) { !a.root_account.feature_enabled?(:granular_permissions_manage_lti) }
      },
      manage_lti_add: {
        label: -> { t("Add LTI") },
        label_v2: -> { t("LTI - add") },
        group: "manage_lti",
        group_label: -> { t("Manage LTI") },
        available_to: %w[
          TeacherEnrollment
          TaEnrollment
          DesignerEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TeacherEnrollment
          TaEnrollment
          DesignerEnrollment
          AccountAdmin
        ],
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_lti) }
      },
      manage_lti_edit: {
        label: -> { t("Edit LTI") },
        label_v2: -> { t("LTI - edit") },
        group: "manage_lti",
        group_label: -> { t("Manage LTI") },
        available_to: %w[
          TeacherEnrollment
          TaEnrollment
          DesignerEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TeacherEnrollment
          TaEnrollment
          DesignerEnrollment
          AccountAdmin
        ],
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_lti) }
      },
      manage_lti_delete: {
        label: -> { t("Delete LTI") },
        label_v2: -> { t("LTI - delete") },
        group: "manage_lti",
        group_label: -> { t("Manage LTI") },
        available_to: %w[
          TeacherEnrollment
          TaEnrollment
          DesignerEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TeacherEnrollment
          TaEnrollment
          DesignerEnrollment
          AccountAdmin
        ],
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_lti) }
      },
      manage_admin_users: {
        label: -> { t("permissions.manage_admin_users", "Add/remove other teachers, course designers or TAs to the course") },
        label_v2: -> { t("Users - add / remove teachers, course designers, or TAs in courses") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: [
          "TeacherEnrollment",
          "AccountAdmin"
        ],
        account_allows: ->(a) { !a.root_account.feature_enabled?(:granular_permissions_manage_users) }
      },
      allow_course_admin_actions: {
        label: -> { t("Allow administrative actions in courses") },
        label_v2: -> { t("Users - allow administrative actions in courses") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: [
          "TeacherEnrollment",
          "AccountAdmin"
        ],
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_users) }
      },
      add_teacher_to_course: {
        label: -> { t("Add Teachers to courses") },
        label_v2: -> { t("Teachers - add") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: [
          "TeacherEnrollment",
          "AccountAdmin"
        ],
        group: "manage_course_teacher_enrollments",
        group_label: -> { t("Users - Teachers") },
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_users) }
      },
      remove_teacher_from_course: {
        label: -> { t("Remove Teachers from courses") },
        label_v2: -> { t("Teachers - remove") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: [
          "TeacherEnrollment",
          "AccountAdmin"
        ],
        group: "manage_course_teacher_enrollments",
        group_label: -> { t("Users - Teachers") },
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_users) }
      },
      add_ta_to_course: {
        label: -> { t("Add TAs to courses") },
        label_v2: -> { t("TAs - add") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: [
          "TeacherEnrollment",
          "AccountAdmin"
        ],
        group: "manage_course_ta_enrollments",
        group_label: -> { t("Users - TAs") },
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_users) }
      },
      remove_ta_from_course: {
        label: -> { t("Remove TAs from courses") },
        label_v2: -> { t("TAs - remove") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: [
          "TeacherEnrollment",
          "AccountAdmin"
        ],
        group: "manage_course_ta_enrollments",
        group_label: -> { t("Users - TAs") },
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_users) }
      },
      add_observer_to_course: {
        label: -> { t("Add Observers to courses") },
        label_v2: -> { t("Observers - add") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ],
        group: "manage_course_observer_enrollments",
        group_label: -> { t("Users - Observers") },
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_users) }
      },
      remove_observer_from_course: {
        label: -> { t("Remove Observers from courses") },
        label_v2: -> { t("Observers - remove") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ],
        group: "manage_course_observer_enrollments",
        group_label: -> { t("Users - Observers") },
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_users) }
      },
      add_designer_to_course: {
        label: -> { t("Add Designers to courses") },
        label_v2: -> { t("Designers - add") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: [
          "TeacherEnrollment",
          "AccountAdmin"
        ],
        group: "manage_course_designer_enrollments",
        group_label: -> { t("Users - Designers") },
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_users) }
      },
      remove_designer_from_course: {
        label: -> { t("Remove Designers from courses") },
        label_v2: -> { t("Designers - remove") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: [
          "TeacherEnrollment",
          "AccountAdmin"
        ],
        group: "manage_course_designer_enrollments",
        group_label: -> { t("Users - Designers") },
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_users) }
      },
      manage_assignments: {
        label: -> { t("permissions.manage_assignments", "Manage (add / edit / delete) assignments and quizzes") },
        label_v2: -> { t("Assignments and Quizzes - add / edit / delete") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ],
        acts_as_access_token_scope: true,
        account_allows: ->(a) { !a.root_account.feature_enabled?(:granular_permissions_manage_assignments) }
      },
      manage_assignments_add: {
        label: -> { t("Add assignments and quizzes") },
        label_v2: -> { t("Assignments and Quizzes - add") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ],
        acts_as_access_token_scope: true,
        group: "manage_assignments_and_quizzes",
        group_label: -> { t("Manage Assignments and Quizzes") },
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_assignments) }
      },
      manage_assignments_edit: {
        label: -> { t("Manage / edit assignments and quizzes") },
        label_v2: -> { t("Assignments and Quizzes - edit") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ],
        acts_as_access_token_scope: true,
        group: "manage_assignments_and_quizzes",
        group_label: -> { t("Manage Assignments and Quizzes") },
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_assignments) }
      },
      manage_assignments_delete: {
        label: -> { t("Delete assignments and quizzes") },
        label_v2: -> { t("Assignments and Quizzes - delete") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ],
        acts_as_access_token_scope: true,
        group: "manage_assignments_and_quizzes",
        group_label: -> { t("Manage Assignments and Quizzes") },
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_assignments) }
      },
      manage_account_calendar_visibility: {
        label: -> { t("Change visibility of account calendars") },
        label_v2: -> { t("Account Calendars - change visibility") },
        group: "manage_account_calendar",
        group_label: -> { t("Manage Account Calendars") },
        account_only: true,
        available_to: %w[AccountAdmin AccountMembership],
        true_for: %w[AccountAdmin]
      },
      manage_account_calendar_events: {
        label: -> { t("Add, edit and delete events on account calendars") },
        label_v2: -> { t("Account Calendars - add / edit / delete events") },
        group: "manage_account_calendar",
        group_label: -> { t("Manage Account Calendars") },
        account_only: true,
        available_to: %w[AccountAdmin AccountMembership],
        true_for: %w[AccountAdmin]
      },
      manage_calendar: {
        label: -> { t("permissions.manage_calendar", "Add, edit and delete events on the course calendar") },
        label_v2: -> { t("Course Calendar - add / edit / delete") },
        available_to: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ]
      },
      # legacy role override
      manage_content: {
        label: -> { t("Manage all other course content") },
        label_v2: -> { t("Course Content - add / edit / delete") },
        available_to: %w[
          TaEnrollment
          TeacherEnrollment
          DesignerEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          TeacherEnrollment
          DesignerEnrollment
          AccountAdmin
        ],
        account_allows: ->(a) { !a.root_account.feature_enabled?(:granular_permissions_manage_course_content) }
      },
      manage_course_content_add: {
        label: -> { t("Add all other course content") },
        label_v2: -> { t("Course Content - add") },
        group: "manage_course_content",
        group_label: -> { t("Manage Course Content") },
        available_to: %w[
          TaEnrollment
          TeacherEnrollment
          DesignerEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          TeacherEnrollment
          DesignerEnrollment
          AccountAdmin
        ],
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_course_content) }
      },
      manage_course_content_edit: {
        label: -> { t("Edit all other course content") },
        label_v2: -> { t("Course Content - edit") },
        group: "manage_course_content",
        group_label: -> { t("Manage Course Content") },
        available_to: %w[
          TaEnrollment
          TeacherEnrollment
          DesignerEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          TeacherEnrollment
          DesignerEnrollment
          AccountAdmin
        ],
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_course_content) }
      },
      manage_course_content_delete: {
        label: -> { t("Delete all other course content") },
        label_v2: -> { t("Course Content - delete") },
        group: "manage_course_content",
        group_label: -> { t("Manage Course Content") },
        available_to: %w[
          TaEnrollment
          TeacherEnrollment
          DesignerEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          TeacherEnrollment
          DesignerEnrollment
          AccountAdmin
        ],
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_course_content) }
      },
      # Course Template account permissions
      add_course_template: {
        label: -> { t("Course Templates - create") },
        label_v2: -> { t("Course Templates - create") },
        available_to: [
          "AccountAdmin",
          "AccountMembership"
        ],
        true_for: [
          "AccountAdmin"
        ],
        group: "manage_course_templates",
        group_label: -> { t("Manage Course Templates") },
        account_allows: ->(a) { a.root_account.feature_enabled?(:course_templates) },
        account_only: true
      },
      edit_course_template: {
        label: -> { t("Course Templates - edit") },
        label_v2: -> { t("Course Templates - edit") },
        available_to: [
          "AccountAdmin",
          "AccountMembership"
        ],
        true_for: [
          "AccountAdmin"
        ],
        group: "manage_course_templates",
        group_label: -> { t("Courses - Course Templates") },
        account_allows: ->(a) { a.root_account.feature_enabled?(:course_templates) },
        account_only: true
      },
      delete_course_template: {
        label: -> { t("Course Templates - delete") },
        label_v2: -> { t("Course Templates - delete") },
        available_to: [
          "AccountAdmin",
          "AccountMembership"
        ],
        true_for: [
          "AccountAdmin"
        ],
        group: "manage_course_templates",
        group_label: -> { t("Manage Course Templates") },
        account_allows: ->(a) { a.root_account.feature_enabled?(:course_templates) },
        account_only: true
      },
      manage_account_banks: {
        label: -> { t("permissions.manage_account_banks", "Manage account level item Banks") },
        label_v2: -> { t("Item Banks - manage account") },
        available_to: %w[
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          AccountAdmin
        ],
      },
      share_banks_with_subaccounts: {
        label: -> { t("permissions.share_banks_with_subaccounts", "Share item banks with subaccounts") },
        label_v2: -> { t("Item Banks - share with subaccounts") },
        available_to: %w[
          DesignerEnrollment
          TaEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          AccountAdmin
        ],
        account_allows: ->(_a) { Account.site_admin.feature_enabled?(:new_quizzes_subaccount_sharing_permission) },
      },
      manage_files_add: {
        label: -> { t("Add course files") },
        label_v2: -> { t("Course Files - add") },
        group: "manage_files",
        group_label: -> { t("Manage Course Files") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
        acts_as_access_token_scope: true
      },
      manage_files_edit: {
        label: -> { t("Edit course files") },
        label_v2: -> { t("Course Files - edit") },
        group: "manage_files",
        group_label: -> { t("Manage Course Files") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
        acts_as_access_token_scope: true
      },
      manage_files_delete: {
        label: -> { t("Delete course files") },
        label_v2: -> { t("Course Files - delete") },
        group: "manage_files",
        group_label: -> { t("Manage Course Files") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
        acts_as_access_token_scope: true
      },
      manage_grades: {
        label: -> { t("permissions.manage_grades", "Edit grades") },
        label_v2: -> { t("Grades - edit") },
        available_to: %w[
          TaEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          TeacherEnrollment
          AccountAdmin
        ]
      },
      # lagacy role override
      manage_groups: {
        label: -> { t("Manage (create / edit / delete) groups") },
        label_v2: -> { t("Groups - add / edit / delete") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
        acts_as_access_token_scope: true,
        account_allows: ->(a) { !a.root_account.feature_enabled?(:granular_permissions_manage_groups) }
      },
      manage_groups_add: {
        label: -> { t("Add groups") },
        label_v2: -> { t("Groups - add") },
        group: "manage_groups",
        group_label: -> { t("Manage Groups") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
        acts_as_access_token_scope: true,
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_groups) }
      },
      manage_groups_manage: {
        label: -> { t("Manage groups") },
        label_v2: -> { t("Groups - manage") },
        group: "manage_groups",
        group_label: -> { t("Manage Groups") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
        acts_as_access_token_scope: true,
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_groups) }
      },
      manage_groups_delete: {
        label: -> { t("Delete groups") },
        label_v2: -> { t("Groups - delete") },
        group: "manage_groups",
        group_label: -> { t("Manage Groups") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
        acts_as_access_token_scope: true,
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_groups) }
      },
      manage_interaction_alerts: {
        label: -> { t("permissions.manage_interaction_alerts", "Manage alerts") },
        label_v2: -> { t("Alerts - add / edit / delete") },
        true_for: %w[AccountAdmin TeacherEnrollment],
        available_to: %w[AccountAdmin AccountMembership TeacherEnrollment TaEnrollment],
      },
      manage_outcomes: {
        label: -> { t("permissions.manage_outcomes", "Manage learning outcomes") },
        label_v2: -> { t("Learning Outcomes - add / edit / delete") },
        available_to: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ]
      },
      manage_proficiency_calculations: {
        label: -> { t("permissions.manage_proficiency_calculations", "Manage outcome proficiency calculations") },
        label_v2: -> { t("Outcome Proficiency Calculations - add / edit") },
        available_to: %w[
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: [
          "AccountAdmin"
        ]
      },
      manage_proficiency_scales: {
        label: -> { t("permissions.manage_proficiency_scales", "Manage outcome mastery scales") },
        label_v2: -> { t("Outcome Mastery Scales - add / edit") },
        available_to: %w[
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: [
          "AccountAdmin"
        ]
      },
      manage_sections_add: {
        label: -> { t("permissions.manage_sections_add", "Add course sections") },
        label_v2: -> { t("Course Sections - add") },
        group: "manage_sections",
        group_label: -> { t("Manage Course Sections") },
        available_to: %w[
          AccountAdmin
          AccountMembership
          TeacherEnrollment
          TaEnrollment
          DesignerEnrollment
        ],
        true_for: %w[AccountAdmin TeacherEnrollment DesignerEnrollment]
      },
      manage_sections_edit: {
        label: -> { t("permissions.manage_sections_edit", "Edit course sections") },
        label_v2: -> { t("Course Sections - edit") },
        group: "manage_sections",
        group_label: -> { t("Manage Course Sections") },
        available_to: %w[
          AccountAdmin
          AccountMembership
          TeacherEnrollment
          TaEnrollment
          DesignerEnrollment
        ],
        true_for: %w[AccountAdmin TeacherEnrollment DesignerEnrollment]
      },
      manage_sections_delete: {
        label: -> { t("permissions.manage_sections_delete", "Delete course sections") },
        label_v2: -> { t("Course Sections - delete") },
        group: "manage_sections",
        group_label: -> { t("Manage Course Sections") },
        available_to: %w[
          AccountAdmin
          AccountMembership
          TeacherEnrollment
          TaEnrollment
          DesignerEnrollment
        ],
        true_for: %w[AccountAdmin TeacherEnrollment DesignerEnrollment]
      },
      manage_students: {
        label: lambda do
          if Account.site_admin.feature_enabled?(:granular_permissions_manage_users)
            t("Manage students for the course")
          else
            t("permissions.manage_students", "Add/remove students for the course")
          end
        end,
        label_v2: lambda do
                    if Account.site_admin.feature_enabled?(:granular_permissions_manage_users)
                      t("Users - manage students in courses")
                    else
                      t("Users - add / remove students in courses")
                    end
                  end,
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ]
      },
      add_student_to_course: {
        label: -> { t("Add Students to courses") },
        label_v2: -> { t("Students - add") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ],
        group: "manage_course_student_enrollments",
        group_label: -> { t("Users - Students") },
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_users) }
      },
      remove_student_from_course: {
        label: -> { t("Remove Students from courses") },
        label_v2: -> { t("Students - remove") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ],
        group: "manage_course_student_enrollments",
        group_label: -> { t("Users - Students") },
        account_allows: ->(a) { a.root_account.feature_enabled?(:granular_permissions_manage_users) }
      },
      temporary_enrollments_add: {
        label: -> { t("permissions.temporary_enrollments_add", "Add temporary enrollments") },
        label_v2: -> { t("Temporary Enrollments - add") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: ["AccountAdmin"],
        account_only: true,
        account_allows: ->(a) { a.root_account.feature_enabled?(:temporary_enrollments) },
        group: "manage_temporary_enrollments",
        group_label: -> { t("Users - Temporary Enrollments") }
      },
      temporary_enrollments_edit: {
        label: -> { t("permissions.temporary_enrollments_edit", "Edit temporary enrollments") },
        label_v2: -> { t("Temporary Enrollments - edit") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: ["AccountAdmin"],
        account_only: true,
        account_allows: ->(a) { a.root_account.feature_enabled?(:temporary_enrollments) },
        group: "manage_temporary_enrollments",
        group_label: -> { t("Users - Temporary Enrollments") }
      },
      temporary_enrollments_delete: {
        label: -> { t("permissions.temporary_enrollments_delete", "Delete temporary enrollments") },
        label_v2: -> { t("Temporary Enrollments - delete") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: ["AccountAdmin"],
        account_only: true,
        account_allows: ->(a) { a.root_account.feature_enabled?(:temporary_enrollments) },
        group: "manage_temporary_enrollments",
        group_label: -> { t("Users - Temporary Enrollments") }
      },
      manage_user_notes: {
        label: -> { t("permissions.manage_user_notes", "Manage faculty journal entries") },
        label_v2: -> { t("Faculty Journal - manage entries") },
        available_to: %w[
          TaEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          TeacherEnrollment
          AccountAdmin
        ],
        account_allows: ->(a) { a.root_account.enable_user_notes }
      },
      manage_rubrics: {
        label: -> { t("permissions.manage_rubrics", "Create and edit assessing rubrics") },
        label_v2: -> { t("Rubrics - add / edit / delete") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          DesignerEnrollment
          TaEnrollment
          TeacherEnrollment
          AccountAdmin
        ]
      },
      manage_wiki_create: {
        label: -> { t("Create pages") },
        label_v2: -> { t("Pages - create") },
        available_to: %w[
          TaEnrollment
          TeacherEnrollment
          DesignerEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          TeacherEnrollment
          DesignerEnrollment
          AccountAdmin
        ],
        group: "manage_wiki",
        group_label: -> { t("Manage Pages") }
      },
      manage_wiki_update: {
        label: -> { t("Update pages") },
        label_v2: -> { t("Pages - update") },
        available_to: %w[
          TaEnrollment
          TeacherEnrollment
          DesignerEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          TeacherEnrollment
          DesignerEnrollment
          AccountAdmin
        ],
        group: "manage_wiki",
        group_label: -> { t("Manage Pages") }
      },
      manage_wiki_delete: {
        label: -> { t("Delete pages") },
        label_v2: -> { t("Pages - delete") },
        available_to: %w[
          TaEnrollment
          TeacherEnrollment
          DesignerEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          TeacherEnrollment
          DesignerEnrollment
          AccountAdmin
        ],
        group: "manage_wiki",
        group_label: -> { t("Manage Pages") }
      },
      moderate_forum: {
        label: -> { t("permissions.moderate_form", "Moderate discussions ( delete / edit other's posts, lock topics)") },
        label_v2: -> { t("Discussions - moderate") },
        available_to: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ]
      },
      post_to_forum: {
        label: -> { t("permissions.post_to_forum", "Post to discussions") },
        label_v2: -> { t("Discussions - post") },
        available_to: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ],
        restrict_future_enrollments: true,
        applies_to_concluded: ["TeacherEnrollment", "TaEnrollment"]
      },
      proxy_assignment_submission: {
        label: -> { t("Instructors can submit on behalf of students") },
        label_v2: -> { t("Submission - Submit on behalf of student") },
        available_to: %w[
          TaEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: [],
        account_allows: lambda do |_a|
          Account.site_admin.feature_enabled?(:proxy_file_uploads)
        end
      },
      read_announcements: {
        label: -> { t("View announcements") },
        label_v2: -> { t("Announcements - view") },
        available_to: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          ObserverEnrollment
          TeacherEnrollment
          AccountAdmin
        ],
        applies_to_concluded: true
      },
      read_email_addresses: {
        label: -> { t("See other users' primary email address") },
        label_v2: -> { t("Users - view primary email address") },
        available_to: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          TeacherEnrollment
          AccountAdmin
        ],
        applies_to_concluded: ["TeacherEnrollment", "TaEnrollment"]
      },
      read_forum: {
        label: -> { t("permissions.read_forum", "View discussions") },
        label_v2: -> { t("Discussions - view") },
        available_to: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          ObserverEnrollment
          TeacherEnrollment
          AccountAdmin
        ],
        applies_to_concluded: true
      },
      read_question_banks: {
        label: -> { t("permissions.read_question_banks", "View and link to question banks") },
        label_v2: -> { t("Question banks - view and link") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ],
        applies_to_concluded: true
      },
      read_reports: {
        label: -> { t("permissions.read_reports", "Manage account or course-level reports") },
        label_v2: -> { t("Reports - manage") }, # Reports - manage is used by both Account and Course Roles in Permissions
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ]
      },
      read_roster: {
        label: -> { t("permissions.read_roster", "See the list of users") },
        label_v2: -> { t("Users - view list") },
        available_to: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ],
        applies_to_concluded: %w[TeacherEnrollment TaEnrollment DesignerEnrollment]
      },
      read_sis: {
        label: -> { t("permission.read_sis", "Read SIS data") },
        label_v2: -> { t("SIS Data - read") },
        true_for: %w[AccountAdmin TeacherEnrollment],
        available_to: %w[AccountAdmin AccountMembership TeacherEnrollment TaEnrollment StudentEnrollment]
      },
      select_final_grade: {
        label: -> { t("Grades - select final grade for moderation") },
        true_for: %w[AccountAdmin TeacherEnrollment TaEnrollment],
        available_to: %w[AccountAdmin AccountMembership TeacherEnrollment TaEnrollment]
      },
      send_messages: {
        label: -> { t("permissions.send_messages", "Send messages to individual course members") },
        label_v2: -> { t("Conversations - send messages to individual course members") },
        available_to: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ]
      },
      send_messages_all: {
        label: -> { t("permissions.send_messages_all", "Send messages to the entire class") },
        label_v2: -> { t("Conversations - send messages to entire class") },
        available_to: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ]
      },
      view_audit_trail: {
        label: -> { t("Grades - view audit trail") },
        true_for: %w[AccountAdmin],
        available_to: %w[TeacherEnrollment AccountAdmin AccountMembership]
      },
      view_all_grades: {
        label: -> { t("permissions.view_all_grades", "View all grades") },
        label_v2: -> { t("Grades - view all grades") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          TeacherEnrollment
          AccountAdmin
        ],
        applies_to_concluded: true
      },
      view_group_pages: {
        label: -> { t("permissions.view_group_pages", "View the group pages of all student groups") },
        label_v2: -> { t("Groups - view all student groups") },
        available_to: %w[
          StudentEnrollment
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          ObserverEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
        ],
        applies_to_concluded: true
      },
      view_quiz_answer_audits: {
        label: -> { t("permissions.view_quiz_answer_audits", "View the answer matrix in Quiz Submission Logs") },
        label_v2: -> { t("Quizzes - view submission log") },
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
        account_allows: ->(a) { a.feature_allowed?(:quiz_log_auditing) }
      },
      view_user_logins: {
        label: -> { t("View login ids for users") },
        label_v2: -> { t("Users - view login IDs") },
        available_to: %w[AccountAdmin AccountMembership TeacherEnrollment TaEnrollment],
        true_for: %w[AccountAdmin TeacherEnrollment TaEnrollment]
      },
      view_admin_analytics: {
        label: -> { I18n.t("Admin Analytics - view and export data") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: %w[AccountAdmin],
        account_only: true,
        account_allows: ->(a) { a.feature_enabled?(:admin_analytics_view_permission) }
      },
      view_ask_questions_analytics: {
        label: -> { t("Ask Your Data") },
        group: "view_advanced_analytics",
        group_label: -> { t("Advanced Analytics") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: %w[AccountAdmin],
        account_only: true,
        account_allows: ->(a) { a.feature_enabled?(:advanced_analytics_ask_questions) }
      },
      manage_impact: {
        label: -> { t("Manage Impact") },
        label_v2: -> { t("Impact - Manage") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: %w[AccountAdmin],
        account_only: :root
      }
    }
  )

  ACCESS_TOKEN_SCOPE_PREFIX = "https://api.instructure.com/auth/canvas"

  def self.permissions
    Permissions.retrieve
  end

  # permissions that apply to concluded courses/enrollments
  def self.concluded_permission_types
    permissions.select { |_k, p| p[:applies_to_concluded] }
  end

  def self.manageable_permissions(context, base_role_type = nil)
    permissions = self.permissions.dup
    permissions.reject! { |_k, p| p[:account_only] == :site_admin } unless context.site_admin?
    permissions.reject! { |_k, p| p[:account_only] == :root } unless context.root_account?
    permissions.reject! { |_k, p| p[:available_to].exclude?(base_role_type) } unless base_role_type.nil?
    permissions.reject! { |_k, p| p[:account_allows] && !p[:account_allows].call(context) }
    permissions.reject! do |_k, p|
      p[:enabled_for_plugin] &&
        !((plugin = Canvas::Plugin.find(p[:enabled_for_plugin])) && plugin.enabled?)
    end
    permissions
  end

  def self.manageable_access_token_scopes(context)
    permissions = manageable_permissions(context).dup
    permissions.select! { |_, p| p[:acts_as_access_token_scope].present? }

    permissions.map do |k, p|
      {
        name: "#{ACCESS_TOKEN_SCOPE_PREFIX}.#{k}",
        label: p.key?(label_v2) ? p[:label_v2].call : p[:label].call
      }
    end
  end

  def self.readonly_for(context, permission, role, role_context = :role_account)
    permission_for(context, permission, role, role_context)[:readonly]
  end

  def self.title_for(context, permission, role, role_context = :role_account)
    if readonly_for(context, permission, role, role_context)
      t "tooltips.readonly", "you do not have permission to change this."
    else
      t "tooltips.toogle", "Click to toggle this permission ON or OFF"
    end
  end

  def self.locked_for(context, permission, role, role_context = :role_account)
    permission_for(context, permission, role, role_context)[:locked]
  end

  def self.hidden_value_for(context, permission, role, role_context = :role_account)
    generated_permission = permission_for(context, permission, role, role_context)
    if !generated_permission[:readonly] && generated_permission[:explicit]
      generated_permission[:enabled] ? "checked" : "unchecked"
    else
      ""
    end
  end

  def self.clear_cached_contexts; end

  # permission changes won't register right away but we already cache user permission checks for an hour so adding some latency here isn't the worst
  def self.local_cache_ttl
    return 0.seconds if ::Rails.env.test? # untangling the billion specs where this goes wrong is hard

    Setting.get("role_override_local_cache_ttl_seconds", "300").to_i.seconds
  end

  def self.permission_for(context, permission, role_or_role_id, role_context = :role_account, no_caching = false, preloaded_overrides: nil)
    # we can avoid a query since we're just using it for the batched keys on redis
    permissionless_base_key = ["role_override_calculation2", Shard.global_id_for(role_or_role_id)].join("/") unless no_caching
    account = context.is_a?(Account) ? context : Account.new(id: context.account_id)
    default_data = permissions[permission]

    if default_data[:account_allows] || no_caching
      # could depend on anything - can't cache (but that's okay because it's not super common)
      uncached_permission_for(context, permission, role_or_role_id, role_context, account, permissionless_base_key, default_data, no_caching, preloaded_overrides:)
    else
      full_base_key = [permissionless_base_key, permission, Shard.global_id_for(role_context)].join("/")
      LocalCache.fetch([full_base_key, account.global_id].join("/"), expires_in: local_cache_ttl) do
        Rails.cache.fetch_with_batched_keys(full_base_key,
                                            batch_object: account,
                                            batched_keys: [:account_chain, :role_overrides],
                                            skip_cache_if_disabled: true) do
          uncached_permission_for(context, permission, role_or_role_id, role_context, account, permissionless_base_key, default_data, preloaded_overrides:)
        end
      end
    end.freeze
  end

  def self.preload_overrides(account, roles, role_context = account)
    return Hash.new([].freeze) if roles.empty?

    account.shard.activate do
      result = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = {} } }

      account_root_id = account.root_account_id&.nonzero? ? account.global_root_account_id : account.global_id

      # skip loading from site admin if the role is not from site admin
      Shard.partition_by_shard(account.account_chain(include_federated_parent: true, include_site_admin: role_context == Account.site_admin)) do |shard_accounts|
        uniq_root_account_ids = shard_accounts.map { |sa| sa.root_account_id&.nonzero? ? sa.root_account_id : sa.id }.uniq
        uniq_root_account_ids -= [account_root_id] if Shard.current == account.shard
        all_roles = roles + Role.where(
          workflow_state: "built_in",
          root_account_id: uniq_root_account_ids,
          base_role_type: roles.select(&:built_in?).map(&:base_role_type)
        )
        id_map = all_roles.flat_map do |r|
          ret = [[r.global_id, r.global_id]]
          # If and only if we are supposed to inherit permissions cross root account, match up the built-in roles
          # since the ids won't match between root accounts
          if r.built_in? && r.global_root_account_id != account_root_id && !account.root_account.primary_settings_root_account?
            # These will all be built-in role copies
            ret << [r.global_id, roles.detect { |local| local.built_in? && local.base_role_type == r.base_role_type }.global_id]
          end
          ret
        end.to_h

        RoleOverride.where(role: all_roles, account: shard_accounts).find_each do |ro|
          permission_hash = result[ro.permission]
          permission_hash[ro.global_context_id][id_map[ro.global_role_id]] = ro
        end
        nil
      end
      result
    end
  end

  # this is a very basic PORO to represent when an actual RoleOverride
  # doesn't exist for passing between internal methods. It's _much_
  # faster than creating an AR object.
  class OverrideDummy
    attr_reader :context_id

    def initialize(context_id)
      @context_id = context_id
    end

    def new_record?
      true
    end

    def context_type
      "Account"
    end

    def locked?
      false
    end

    def has_asset?(asset)
      asset.instance_of?(Account) && asset.id == context_id
    end
  end
  private_constant :OverrideDummy

  def self.uncached_overrides_for(context, role, role_context, preloaded_overrides: nil, only_permission: nil)
    context.shard.activate do
      accounts = context.account_chain(include_site_admin: true)

      preloaded_overrides ||= preload_overrides(context, [role], role_context)

      overrides = {}

      dummies = RequestCache.cache("role_override_dummies") do
        Hash.new do |h, account_id|
          h[account_id] = OverrideDummy.new(account_id)
        end
      end

      # every context has to be represented so that we can't miss role_context below
      preloaded_overrides.each do |(permission, overrides_by_account)|
        next if only_permission && permission != only_permission

        overrides[permission] = accounts.reverse_each.map do |account|
          overrides_by_account[account.global_id][role.global_id] || dummies[account.id]
        end
      end
      overrides
    end
  end

  EMPTY_ARRAY = [].freeze
  private_constant :EMPTY_ARRAY

  def self.uncached_permission_for(context, permission, role_or_role_id, role_context, account, permissionless_base_key, default_data, no_caching = false, preloaded_overrides: nil)
    role = role_or_role_id.is_a?(Role) ? role_or_role_id : Role.get_role_by_id(role_or_role_id)

    # be explicit that we're expecting calculation to stop at the role's account rather than, say, passing in a course
    # unnecessarily to make sure we go all the way down the chain (when nil would work just as well)
    role_context = role.account if role_context == :role_account

    # Determine if the permission is able to be used for the account. A non-setting is 'true'.
    # Execute linked proc if given.
    account_allows = !!(default_data[:account_allows].nil? || (default_data[:account_allows].respond_to?(:call) &&
        default_data[:account_allows].call(context.root_account)))

    base_role = role.base_role_type
    locked = !default_data[:available_to].include?(base_role) || !account_allows

    generated_permission = {
      account_allows:,
      permission:,
      enabled: account_allows && (default_data[:true_for].include?(base_role) ? [:self, :descendants] : false),
      locked:,
      readonly: locked,
      explicit: false,
      base_role_type: base_role,
      enrollment_type: role.name,
      role_id: role.id,
    }
    generated_permission[:group] = default_data[:group] if default_data[:group].present?

    # NOTE: built-in roles don't have an account so we need to remember to send it in explicitly
    if default_data[:account_only] &&
       ((default_data[:account_only] == :root && !(role_context && role_context.is_a?(Account) && role_context.root_account?)) ||
        (default_data[:account_only] == :site_admin && !(role_context && role_context.is_a?(Account) && role_context.site_admin?)))
      generated_permission[:enabled] = false
      return generated_permission # shouldn't be able to be overridden because the account_user doesn't belong to the root/site_admin
    end

    # cannot be overridden; don't bother looking for overrides
    return generated_permission if locked

    overrides = if no_caching
                  uncached_overrides_for(context, role, role_context, preloaded_overrides:, only_permission: permission.to_s)
                else
                  RequestCache.cache(permissionless_base_key, account) do
                    LocalCache.fetch([permissionless_base_key, account.global_id].join("/"), expires_in: local_cache_ttl) do
                      Rails.cache.fetch_with_batched_keys(permissionless_base_key,
                                                          batch_object: account,
                                                          batched_keys: [:account_chain, :role_overrides],
                                                          skip_cache_if_disabled: true) do
                        uncached_overrides_for(context, role, role_context, preloaded_overrides:)
                      end
                    end
                  end
                end

    # walk the overrides from most general (site admin, root account) to most specific (the role's account)
    # and apply them; short-circuit once someone has locked it
    last_override = false
    hit_role_context = false
    (overrides[permission.to_s] || EMPTY_ARRAY).each do |override|
      # set the flag that we have an override for the context we're on
      last_override = override.context_id == context.id && override.context_type == context.class.base_class.name

      generated_permission[:context_id] = override.context_id unless override.new_record?
      generated_permission[:locked] = override.locked?
      # keep track of the value for the parent
      generated_permission[:prior_default] = generated_permission[:enabled]

      # override.enabled.nil? is no longer possible, but is important for the migration that removes nils
      if override.new_record? || override.enabled.nil?
        if last_override
          case generated_permission[:enabled]
          when [:descendants]
            generated_permission[:enabled] = [:self, :descendants]
          when [:self]
            generated_permission[:enabled] = nil
          end
        end
      else
        generated_permission[:explicit] = true if last_override
        if hit_role_context
          generated_permission[:enabled] ||= override.enabled? ? override.applies_to : nil
        else
          generated_permission[:enabled] = override.enabled? ? override.applies_to : nil
        end
      end
      hit_role_context ||= role_context.is_a?(Account) && override.has_asset?(role_context)

      break if override.locked?
      break if generated_permission[:enabled] && hit_role_context
    end

    # there was not an override matching this context, so do a half loop
    # to set the inherited values
    unless last_override
      generated_permission[:prior_default] = generated_permission[:enabled]
      generated_permission[:readonly] = true if generated_permission[:locked]
    end

    generated_permission
  end

  # returns just the :enabled key of permission_for, adjusted for applying it to a certain
  # context
  def self.enabled_for?(context, permission, role, role_context = :role_account)
    permission = permission_for(context, permission, role, role_context)
    return [] unless permission[:enabled]

    # this override applies to self, and we are self; no adjustment necessary
    return permission[:enabled] if context.id == permission[:context_id]
    # this override applies to descendants, and we're not applying it to self
    #   (presumed that other logic prevents calling this method with context being a parent of role_context)
    return [:self, :descendants] if context.id != permission[:context_id] && permission[:enabled].include?(:descendants)

    []
  end

  # settings is a hash with recognized keys :override and :locked. each key
  # differentiates nil, false, and truthy as possible values
  def self.manage_role_override(context, role, permission, settings)
    context.shard.activate do
      role_override = context.role_overrides.where(permission:, role_id: role.id).first
      if !settings[:override].nil? || settings[:locked]
        role_override ||= context.role_overrides.build(
          permission:,
          role:
        )
        role_override.enabled = settings[:override] unless settings[:override].nil?
        role_override.locked = settings[:locked] unless settings[:locked].nil?
        role_override.applies_to_self = settings[:applies_to_self] unless settings[:applies_to_self].nil?
        unless settings[:applies_to_descendants].nil?
          role_override.applies_to_descendants = settings[:applies_to_descendants]
        end
        role_override.save!
      elsif role_override
        account = role_override.account
        role = role_override.role
        role_override.destroy
        RoleOverride.clear_caches(account, role)
        role_override = nil
      end
      role_override
    end
  end
end
