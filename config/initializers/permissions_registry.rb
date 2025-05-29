# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
# NOTE: manage_alerts = Global Announcements and manage_interaction_alerts = Alerts for legacy reasons
# NOTE: if you add a permission, also update API documentation for RoleOverridesController#add_role
#
Rails.application.config.to_prepare do
  # Base canvas-lms permissions
  Permissions.register(
    {
      become_user: {
        label: -> { I18n.t("Act as users") },
        label_v2: -> { I18n.t("Users - act as") },
        account_only: :root,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      import_sis: {
        label: -> { I18n.t("Import SIS data") },
        label_v2: -> { I18n.t("SIS Data - import") },
        account_only: :root,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      create_access_tokens: {
        label: -> { I18n.t("Create User Access Tokens") },
        label_v2: -> { I18n.t("Access Tokens - create / update") },
        account_only: :root,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
        account_allows: ->(a) { a.feature_enabled?(:admin_manage_access_tokens) },
        group: "users_manage_access_tokens",
        group_label: -> { I18n.t("Users - Manage Access Tokens") },
      },
      delete_access_tokens: {
        label: -> { I18n.t("Delete User Access Tokens") },
        label_v2: -> { I18n.t("Access Tokens - delete") },
        account_only: :root,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
        account_allows: ->(a) { a.feature_enabled?(:admin_manage_access_tokens) },
        group: "users_manage_access_tokens",
        group_label: -> { I18n.t("Users - Manage Access Tokens") },
      },
      manage_account_memberships: {
        label: -> { I18n.t("permissions.manage_account_memberships", "Add/remove other admins for the account") },
        label_v2: -> { I18n.t("Admins - add / remove") },
        available_to: [
          "AccountMembership"
        ],
        true_for: [
          "AccountAdmin"
        ],
        account_only: true
      },
      manage_account_settings: {
        label: -> { I18n.t("permissions.manage_account_settings", "Manage account-level settings") },
        label_v2: -> { I18n.t("Account-level settings - manage") },
        available_to: [
          "AccountMembership"
        ],
        true_for: [
          "AccountAdmin"
        ],
        account_only: true
      },
      manage_alerts: {
        label: -> { I18n.t("permissions.manage_announcements", "Manage global announcements") },
        label_v2: -> { I18n.t("Global Announcements - add / edit / delete") },
        account_only: true,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      manage_catalog: {
        label: -> { I18n.t("permissions.manage_catalog", "Manage catalog") },
        label_v2: -> { I18n.t("Catalog - manage") },
        account_only: true,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
        account_allows: ->(a) { a.settings[:catalog_enabled] }
      },
      manage_courses_admin: {
        label: -> { I18n.t("Manage account level course actions") },
        label_v2: -> { I18n.t("Courses - manage / update") },
        group: "manage_courses",
        group_label: -> { I18n.t("Manage Courses") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: ["AccountAdmin"],
        account_only: true
      },
      manage_courses_add: {
        label: -> { I18n.t("Add courses") },
        label_v2: -> { I18n.t("Courses - add") },
        group: "manage_courses",
        group_label: -> { I18n.t("Manage Courses") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: %w[AccountAdmin],
        account_only: true
      },
      manage_courses_publish: {
        label: -> { I18n.t("Publish courses") },
        label_v2: -> { I18n.t("Courses - publish") },
        group: "manage_courses",
        group_label: -> { I18n.t("Manage Courses") },
        available_to: %w[
          AccountAdmin
          AccountMembership
          TeacherEnrollment
          TaEnrollment
          DesignerEnrollment
        ],
        true_for: %w[AccountAdmin TeacherEnrollment DesignerEnrollment]
      },
      manage_courses_conclude: {
        label: -> { I18n.t("Conclude courses") },
        label_v2: -> { I18n.t("Courses - conclude") },
        group: "manage_courses",
        group_label: -> { I18n.t("Manage Courses") },
        available_to: %w[
          AccountAdmin
          AccountMembership
          TeacherEnrollment
          TaEnrollment
          DesignerEnrollment
        ],
        true_for: %w[AccountAdmin TeacherEnrollment DesignerEnrollment]
      },
      manage_courses_reset: {
        label: -> { I18n.t("Reset courses") },
        label_v2: -> { I18n.t("Courses - reset") },
        group: "manage_courses",
        group_label: -> { I18n.t("Manage Courses") },
        available_to: %w[
          AccountAdmin
          AccountMembership
          TeacherEnrollment
          DesignerEnrollment
        ],
        true_for: %w[AccountAdmin]
      },
      manage_courses_delete: {
        label: -> { I18n.t("Delete courses") },
        label_v2: -> { I18n.t("Courses - delete") },
        group: "manage_courses",
        group_label: -> { I18n.t("Manage Courses") },
        available_to: %w[
          AccountAdmin
          AccountMembership
          TeacherEnrollment
          DesignerEnrollment
        ],
        true_for: %w[AccountAdmin]
      },
      undelete_courses: {
        label: -> { I18n.t("permissions.undelete_courses", "Undelete courses") },
        label_v2: -> { I18n.t("Courses - undelete") },
        admin_tool: true,
        account_only: true,
        available_to: %w[
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[AccountAdmin]
      },
      view_archived_courses: {
        label: -> { I18n.t("View archived courses") },
        label_v2: -> { I18n.t("Courses - view archived") },
        group: "manage_courses",
        group_label: -> { I18n.t("Manage Courses") },
        available_to: %w[
          AccountAdmin
          AccountMembership
          TeacherEnrollment
          DesignerEnrollment
        ],
        true_for: %w[AccountAdmin],
        account_allows: ->(a) { a.root_account.feature_enabled?(:course_archival) }
      },
      manage_data_services: {
        label: -> { I18n.t("permissions.manage_data_services", "Manage data services") },
        label_v2: -> { I18n.t("Data Services - manage ") },
        account_only: true,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      manage_course_visibility: {
        label: -> { I18n.t("Change course visibility") },
        label_v2: -> { I18n.t("Courses - change visibility") },
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
        label: -> { I18n.t("permissions.manage_developer_keys", "Manage developer keys") },
        label_v2: -> { I18n.t("Developer Keys - manage ") },
        account_only: true,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      moderate_user_content: {
        label: -> { I18n.t("permissions.moderate_user_content", "Moderate user content") },
        label_v2: -> { I18n.t("Users - moderate content") },
        account_only: true,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      view_feature_flags: {
        label: -> { I18n.t("View feature options at an account level") },
        label_v2: -> { I18n.t("Feature Options - view") },
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership]
      },
      manage_feature_flags: {
        label: -> { I18n.t("permissions.manage_feature_flags", "Enable or disable features at an account level") },
        label_v2: -> { I18n.t("Feature Options - enable / disable") },
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership]
      },
      manage_frozen_assignments: {
        label: -> { I18n.t("permissions.manage_frozen_assignment", "Manage (edit / delete) frozen assignments") },
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
        enabled_for_plugin: :assignment_freezer
      },
      manage_global_outcomes: {
        label: -> { I18n.t("permissions.manage_global_outcomes", "Manage global learning outcomes") },
        account_only: :site_admin,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      manage_jobs: {
        label: -> { I18n.t("permissions.managed_jobs", "Manage background jobs") },
        account_only: :site_admin,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      manage_lti_registrations: {
        label: -> { I18n.t("LTI Registrations - manage ") },
        account_only: true,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
        account_allows: ->(a) { a.root_account.feature_enabled?(:lti_registrations_page) }
      },
      manage_release_notes: {
        label: -> { I18n.t("Manage release notes") },
        account_only: :site_admin,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      manage_master_courses: {
        label: -> { I18n.t("Blueprint Courses (create / edit / associate / delete)") },
        label_v2: -> { I18n.t("Blueprint Courses - add / edit / associate / delete") },
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
        label: -> { I18n.t("permissions.manage_role_overrides", "Manage permissions") },
        label_v2: -> { I18n.t("Permissions - manage") },
        account_only: true,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountMembership]
      },
      manage_storage_quotas: {
        label: -> { I18n.t("permissions.manage_storage_quotas", "Manage storage quotas") },
        label_v2: -> { I18n.t("Storage Quotas - manage") },
        account_only: true,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership]
      },
      manage_sis: {
        label: -> { I18n.t("permissions.manage_sis", "Manage SIS data") },
        label_v2: -> { I18n.t("SIS Data - manage") },
        account_only: :root,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      manage_site_settings: {
        label: -> { I18n.t("permissions.manage_site_settings", "Manage site-wide and plugin settings") },
        account_only: :site_admin,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      manage_internal_settings: {
        label: -> { I18n.t("permissions.manage_internal_settings", "Manage environment-wide internal settings") },
        account_only: :site_admin,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      manage_user_logins: {
        label: -> { I18n.t("permissions.manage_user_logins", "Modify login details for users") },
        label_v2: -> { I18n.t("Users - manage login details") },
        available_to: [
          "AccountAdmin",
          "AccountMembership"
        ],
        account_only: :root,
        true_for: [
          "AccountAdmin"
        ]
      },
      manage_dsr_requests: {
        label: -> { I18n.t("permissions.manage_dsr_requests", "Create DSR Exports for Users") },
        label_v2: -> { I18n.t("Users - create DSR export") },
        available_to: [
          "AccountAdmin",
          "AccountMembership"
        ],
        account_only: :root,
        true_for: [
          "AccountAdmin"
        ],
        account_allows: ->(a) { Feature.exists?(:enable_dsr_requests) && a.feature_enabled?(:enable_dsr_requests) }
      },
      manage_user_observers: {
        label: -> { I18n.t("permissions.manage_user_observers", "Manage observers for users") },
        label_v2: -> { I18n.t("Users - manage observers") },
        account_only: :root,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      read_course_content: {
        label: -> { I18n.t("permissions.read_course_content", "View course content") },
        label_v2: -> { I18n.t("Course Content - view") },
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership]
      },
      read_course_list: {
        label: -> { I18n.t("permissions.read_course_list", "View the list of courses") },
        label_v2: -> { I18n.t("Courses - view list") },
        account_only: true,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership]
      },
      read_messages: {
        label: -> { I18n.t("permissions.read_messages", "View notifications sent to users") },
        account_only: :site_admin,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      reset_any_mfa: {
        label: -> { I18n.t("Reset Multi-Factor Authentication") },
        account_only: :root,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
        account_allows: ->(a) { a.mfa_settings != :disabled }
      },
      view_course_changes: {
        label: -> { I18n.t("permissions.view_course_changes", "View Course Change Logs") },
        label_v2: -> { I18n.t("Courses - view change logs") },
        admin_tool: true,
        account_only: :root,
        available_to: [
          "AccountAdmin",
          "AccountMembership"
        ],
        true_for: ["AccountAdmin"]
      },
      view_error_reports: {
        label: -> { I18n.t("permissions.view_error_reports", "View error reports") },
        account_only: :site_admin,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      view_grade_changes: {
        label: -> { I18n.t("permissions.view_grade_changes", "View Grade Change Logs") },
        label_v2: -> { I18n.t("Grades - view change logs") },
        admin_tool: true,
        account_only: true,
        available_to: [
          "AccountAdmin",
          "AccountMembership"
        ],
        true_for: ["AccountAdmin"]
      },
      view_jobs: {
        label: -> { I18n.t("permissions.view_jobs", "View background jobs") },
        account_only: :site_admin,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
      },
      view_notifications: {
        label: -> { I18n.t("permissions.view_notifications", "View notifications") },
        label_v2: -> { I18n.t("Notifications - view") },
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
        label: -> { I18n.t("permissions.view_statistics", "View statistics") },
        label_v2: -> { I18n.t("Statistics - view") },
        account_only: true,
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership]
      },
      create_collaborations: {
        label: -> { I18n.t("permissions.create_collaborations", "Create student collaborations") },
        label_v2: -> { I18n.t("Student Collaborations - create") },
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
        label: -> { I18n.t("permissions.create_conferences", "Create web conferences") },
        label_v2: -> { I18n.t("Web Conferences - create") },
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
        label: -> { I18n.t("Create new discussions") },
        label_v2: -> { I18n.t("Discussions - create") },
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
        label: -> { I18n.t("Users - generate observer pairing codes for students") },
        true_for: %w[AccountAdmin],
        available_to: %w[TeacherEnrollment ObserverEnrollment TaEnrollment AccountAdmin AccountMembership DesignerEnrollment]
      },
      import_outcomes: {
        label: -> { I18n.t("Import learning outcomes") },
        label_v2: -> { I18n.t("Learning Outcomes - import") },
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
      manage_lti_add: {
        label: -> { I18n.t("Add LTI") },
        label_v2: -> { I18n.t("LTI - add") },
        group: "manage_lti",
        group_label: -> { I18n.t("Manage LTI") },
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
        ]
      },
      manage_lti_edit: {
        label: -> { I18n.t("Edit LTI") },
        label_v2: -> { I18n.t("LTI - edit") },
        group: "manage_lti",
        group_label: -> { I18n.t("Manage LTI") },
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
        ]
      },
      manage_lti_delete: {
        label: -> { I18n.t("Delete LTI") },
        label_v2: -> { I18n.t("LTI - delete") },
        group: "manage_lti",
        group_label: -> { I18n.t("Manage LTI") },
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
        ]
      },
      allow_course_admin_actions: {
        label: -> { I18n.t("Allow administrative actions in courses") },
        label_v2: -> { I18n.t("Users - allow administrative actions in courses") },
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
        ]
      },
      add_teacher_to_course: {
        label: -> { I18n.t("Add Teachers to courses") },
        label_v2: -> { I18n.t("Teachers - add") },
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
        group_label: -> { I18n.t("Users - Teachers") }
      },
      remove_teacher_from_course: {
        label: -> { I18n.t("Remove Teachers from courses") },
        label_v2: -> { I18n.t("Teachers - remove") },
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
        group_label: -> { I18n.t("Users - Teachers") }
      },
      add_ta_to_course: {
        label: -> { I18n.t("Add TAs to courses") },
        label_v2: -> { I18n.t("TAs - add") },
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
        group_label: -> { I18n.t("Users - TAs") }
      },
      remove_ta_from_course: {
        label: -> { I18n.t("Remove TAs from courses") },
        label_v2: -> { I18n.t("TAs - remove") },
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
        group_label: -> { I18n.t("Users - TAs") }
      },
      add_observer_to_course: {
        label: -> { I18n.t("Add Observers to courses") },
        label_v2: -> { I18n.t("Observers - add") },
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
        group_label: -> { I18n.t("Users - Observers") }
      },
      remove_observer_from_course: {
        label: -> { I18n.t("Remove Observers from courses") },
        label_v2: -> { I18n.t("Observers - remove") },
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
        group_label: -> { I18n.t("Users - Observers") }
      },
      add_designer_to_course: {
        label: -> { I18n.t("Add Designers to courses") },
        label_v2: -> { I18n.t("Designers - add") },
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
        group_label: -> { I18n.t("Users - Designers") }
      },
      remove_designer_from_course: {
        label: -> { I18n.t("Remove Designers from courses") },
        label_v2: -> { I18n.t("Designers - remove") },
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
        group_label: -> { I18n.t("Users - Designers") }
      },
      manage_assignments_add: {
        label: -> { I18n.t("Add assignments and quizzes") },
        label_v2: -> { I18n.t("Assignments and Quizzes - add") },
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
        group_label: -> { I18n.t("Manage Assignments and Quizzes") }
      },
      manage_assignments_edit: {
        label: -> { I18n.t("Manage / edit assignments and quizzes") },
        label_v2: -> { I18n.t("Assignments and Quizzes - edit") },
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
        group_label: -> { I18n.t("Manage Assignments and Quizzes") }
      },
      manage_assignments_delete: {
        label: -> { I18n.t("Delete assignments and quizzes") },
        label_v2: -> { I18n.t("Assignments and Quizzes - delete") },
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
        group_label: -> { I18n.t("Manage Assignments and Quizzes") }
      },
      manage_account_calendar_visibility: {
        label: -> { I18n.t("Change visibility of account calendars") },
        label_v2: -> { I18n.t("Account Calendars - change visibility") },
        group: "manage_account_calendar",
        group_label: -> { I18n.t("Manage Account Calendars") },
        account_only: true,
        available_to: %w[AccountAdmin AccountMembership],
        true_for: %w[AccountAdmin]
      },
      manage_account_calendar_events: {
        label: -> { I18n.t("Add, edit and delete events on account calendars") },
        label_v2: -> { I18n.t("Account Calendars - add / edit / delete events") },
        group: "manage_account_calendar",
        group_label: -> { I18n.t("Manage Account Calendars") },
        account_only: true,
        available_to: %w[AccountAdmin AccountMembership],
        true_for: %w[AccountAdmin]
      },
      manage_calendar: {
        label: -> { I18n.t("permissions.manage_calendar", "Add, edit and delete events on the course calendar") },
        label_v2: -> { I18n.t("Course Calendar - add / edit / delete") },
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
      manage_course_content_add: {
        label: -> { I18n.t("Add all other course content") },
        label_v2: -> { I18n.t("Course Content - add") },
        group: "manage_course_content",
        group_label: -> { I18n.t("Manage Course Content") },
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
        ]
      },
      manage_course_content_edit: {
        label: -> { I18n.t("Edit all other course content") },
        label_v2: -> { I18n.t("Course Content - edit") },
        group: "manage_course_content",
        group_label: -> { I18n.t("Manage Course Content") },
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
        ]
      },
      manage_course_content_delete: {
        label: -> { I18n.t("Delete all other course content") },
        label_v2: -> { I18n.t("Course Content - delete") },
        group: "manage_course_content",
        group_label: -> { I18n.t("Manage Course Content") },
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
        ]
      },
      # Course Template account permissions
      add_course_template: {
        label: -> { I18n.t("Course Templates - create") },
        label_v2: -> { I18n.t("Course Templates - create") },
        available_to: [
          "AccountAdmin",
          "AccountMembership"
        ],
        true_for: [
          "AccountAdmin"
        ],
        group: "manage_course_templates",
        group_label: -> { I18n.t("Manage Course Templates") },
        account_allows: ->(a) { a.root_account.feature_enabled?(:course_templates) },
        account_only: true
      },
      edit_course_template: {
        label: -> { I18n.t("Course Templates - edit") },
        label_v2: -> { I18n.t("Course Templates - edit") },
        available_to: [
          "AccountAdmin",
          "AccountMembership"
        ],
        true_for: [
          "AccountAdmin"
        ],
        group: "manage_course_templates",
        group_label: -> { I18n.t("Courses - Course Templates") },
        account_allows: ->(a) { a.root_account.feature_enabled?(:course_templates) },
        account_only: true
      },
      delete_course_template: {
        label: -> { I18n.t("Course Templates - delete") },
        label_v2: -> { I18n.t("Course Templates - delete") },
        available_to: [
          "AccountAdmin",
          "AccountMembership"
        ],
        true_for: [
          "AccountAdmin"
        ],
        group: "manage_course_templates",
        group_label: -> { I18n.t("Manage Course Templates") },
        account_allows: ->(a) { a.root_account.feature_enabled?(:course_templates) },
        account_only: true
      },
      manage_account_banks: {
        label: -> { I18n.t("permissions.manage_account_banks", "Manage account level item Banks") },
        label_v2: -> { I18n.t("Item Banks - manage account") },
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
        label: -> { I18n.t("permissions.share_banks_with_subaccounts", "Share item banks with subaccounts") },
        label_v2: -> { I18n.t("Item Banks - share with subaccounts") },
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
        label: -> { I18n.t("Add course files") },
        label_v2: -> { I18n.t("Course Files - add") },
        group: "manage_files",
        group_label: -> { I18n.t("Manage Course Files") },
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
        label: -> { I18n.t("Edit course files") },
        label_v2: -> { I18n.t("Course Files - edit") },
        group: "manage_files",
        group_label: -> { I18n.t("Manage Course Files") },
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
        label: -> { I18n.t("Delete course files") },
        label_v2: -> { I18n.t("Course Files - delete") },
        group: "manage_files",
        group_label: -> { I18n.t("Manage Course Files") },
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
        label: -> { I18n.t("permissions.manage_grades", "Edit grades") },
        label_v2: -> { I18n.t("Grades - edit") },
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
      manage_groups_add: {
        label: -> { I18n.t("Add groups") },
        label_v2: -> { I18n.t("Groups - add") },
        group: "manage_groups",
        group_label: -> { I18n.t("Manage Groups") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
        acts_as_access_token_scope: true
      },
      manage_groups_manage: {
        label: -> { I18n.t("Manage groups") },
        label_v2: -> { I18n.t("Groups - manage") },
        group: "manage_groups",
        group_label: -> { I18n.t("Manage Groups") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
        acts_as_access_token_scope: true
      },
      manage_groups_delete: {
        label: -> { I18n.t("Delete groups") },
        label_v2: -> { I18n.t("Groups - delete") },
        group: "manage_groups",
        group_label: -> { I18n.t("Manage Groups") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
        acts_as_access_token_scope: true
      },
      manage_tags_add: {
        label: -> { I18n.t("Add Differentiation Tags") },
        label_v2: -> { I18n.t("Differentiation Tags - add") },
        group: "manage_differentiation_tags",
        group_label: -> { I18n.t("Manage Differentiation Tags") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[TeacherEnrollment AccountAdmin],
        acts_as_access_token_scope: true,
        account_allows: ->(a) { a.allow_assign_to_differentiation_tags_unlocked? },
      },
      manage_tags_manage: {
        label: -> { I18n.t("Manage Differentiation Tags") },
        label_v2: -> { I18n.t("Differentiation Tags - manage") },
        group: "manage_differentiation_tags",
        group_label: -> { I18n.t("Manage Differentiation Tags") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[TeacherEnrollment AccountAdmin],
        acts_as_access_token_scope: true,
        account_allows: ->(a) { a.allow_assign_to_differentiation_tags_unlocked? },
      },
      manage_tags_delete: {
        label: -> { I18n.t("Delete Differentiation Tags") },
        label_v2: -> { I18n.t("Differentiation Tags - delete") },
        group: "manage_differentiation_tags",
        group_label: -> { I18n.t("Manage Differentiation Tags") },
        available_to: %w[
          TaEnrollment
          DesignerEnrollment
          TeacherEnrollment
          AccountAdmin
          AccountMembership
        ],
        true_for: %w[TeacherEnrollment AccountAdmin],
        acts_as_access_token_scope: true,
        account_allows: ->(a) { a.allow_assign_to_differentiation_tags_unlocked? },
      },
      manage_interaction_alerts: {
        label: -> { I18n.t("permissions.manage_interaction_alerts", "Manage alerts") },
        label_v2: -> { I18n.t("Alerts - add / edit / delete") },
        true_for: %w[AccountAdmin TeacherEnrollment],
        available_to: %w[AccountAdmin AccountMembership TeacherEnrollment TaEnrollment],
      },
      manage_outcomes: {
        label: -> { I18n.t("permissions.manage_outcomes", "Manage learning outcomes") },
        label_v2: -> { I18n.t("Learning Outcomes - add / edit / delete") },
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
        label: -> { I18n.t("permissions.manage_proficiency_calculations", "Manage outcome proficiency calculations") },
        label_v2: -> { I18n.t("Outcome Proficiency Calculations - add / edit") },
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
        label: -> { I18n.t("permissions.manage_proficiency_scales", "Manage outcome mastery scales") },
        label_v2: -> { I18n.t("Outcome Mastery Scales - add / edit") },
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
        label: -> { I18n.t("permissions.manage_sections_add", "Add course sections") },
        label_v2: -> { I18n.t("Course Sections - add") },
        group: "manage_sections",
        group_label: -> { I18n.t("Manage Course Sections") },
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
        label: -> { I18n.t("permissions.manage_sections_edit", "Edit course sections") },
        label_v2: -> { I18n.t("Course Sections - edit") },
        group: "manage_sections",
        group_label: -> { I18n.t("Manage Course Sections") },
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
        label: -> { I18n.t("permissions.manage_sections_delete", "Delete course sections") },
        label_v2: -> { I18n.t("Course Sections - delete") },
        group: "manage_sections",
        group_label: -> { I18n.t("Manage Course Sections") },
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
        label: -> { I18n.t("Manage students for the course") },
        label_v2: -> { I18n.t("Users - manage students in courses") },
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
        label: -> { I18n.t("Add Students to courses") },
        label_v2: -> { I18n.t("Students - add") },
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
        group_label: -> { I18n.t("Users - Students") }
      },
      remove_student_from_course: {
        label: -> { I18n.t("Remove Students from courses") },
        label_v2: -> { I18n.t("Students - remove") },
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
        group_label: -> { I18n.t("Users - Students") }
      },
      temporary_enrollments_add: {
        label: -> { I18n.t("permissions.temporary_enrollments_add", "Add temporary enrollments") },
        label_v2: -> { I18n.t("Temporary Enrollments - add") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: ["AccountAdmin"],
        account_only: true,
        account_allows: ->(a) { a.root_account.feature_enabled?(:temporary_enrollments) },
        group: "manage_temporary_enrollments",
        group_label: -> { I18n.t("Users - Temporary Enrollments") }
      },
      temporary_enrollments_edit: {
        label: -> { I18n.t("permissions.temporary_enrollments_edit", "Edit temporary enrollments") },
        label_v2: -> { I18n.t("Temporary Enrollments - edit") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: ["AccountAdmin"],
        account_only: true,
        account_allows: ->(a) { a.root_account.feature_enabled?(:temporary_enrollments) },
        group: "manage_temporary_enrollments",
        group_label: -> { I18n.t("Users - Temporary Enrollments") }
      },
      temporary_enrollments_delete: {
        label: -> { I18n.t("permissions.temporary_enrollments_delete", "Delete temporary enrollments") },
        label_v2: -> { I18n.t("Temporary Enrollments - delete") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: ["AccountAdmin"],
        account_only: true,
        account_allows: ->(a) { a.root_account.feature_enabled?(:temporary_enrollments) },
        group: "manage_temporary_enrollments",
        group_label: -> { I18n.t("Users - Temporary Enrollments") }
      },
      manage_rubrics: {
        label: -> { I18n.t("permissions.manage_rubrics", "Create and edit assessing rubrics") },
        label_v2: -> { I18n.t("Rubrics - add / edit / delete") },
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
        label: -> { I18n.t("Create pages") },
        label_v2: -> { I18n.t("Pages - create") },
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
        group_label: -> { I18n.t("Manage Pages") }
      },
      manage_wiki_update: {
        label: -> { I18n.t("Update pages") },
        label_v2: -> { I18n.t("Pages - update") },
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
        group_label: -> { I18n.t("Manage Pages") }
      },
      manage_wiki_delete: {
        label: -> { I18n.t("Delete pages") },
        label_v2: -> { I18n.t("Pages - delete") },
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
        group_label: -> { I18n.t("Manage Pages") }
      },
      moderate_forum: {
        label: -> { I18n.t("permissions.moderate_form", "Moderate discussions ( delete / edit other's posts, lock topics)") },
        label_v2: -> { I18n.t("Discussions - moderate") },
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
        label: -> { I18n.t("permissions.post_to_forum", "Post to discussions") },
        label_v2: -> { I18n.t("Discussions - post") },
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
        label: -> { I18n.t("Instructors can submit on behalf of students") },
        label_v2: -> { I18n.t("Submission - Submit on behalf of student") },
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
        label: -> { I18n.t("View announcements") },
        label_v2: -> { I18n.t("Announcements - view") },
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
        label: -> { I18n.t("See other users' primary email address") },
        label_v2: -> { I18n.t("Users - view primary email address") },
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
        label: -> { I18n.t("permissions.read_forum", "View discussions") },
        label_v2: -> { I18n.t("Discussions - view") },
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
        label: -> { I18n.t("permissions.read_question_banks", "View and link to question banks") },
        label_v2: -> { I18n.t("Question banks - view and link") },
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
        label: -> { I18n.t("permissions.read_reports", "Manage account or course-level reports") },
        label_v2: -> { I18n.t("Reports - manage") }, # Reports - manage is used by both Account and Course Roles in Permissions
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
        label: -> { I18n.t("permissions.read_roster", "See the list of users") },
        label_v2: -> { I18n.t("Users - view list") },
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
        label: -> { I18n.t("permission.read_sis", "Read SIS data") },
        label_v2: -> { I18n.t("SIS Data - read") },
        true_for: %w[AccountAdmin TeacherEnrollment],
        available_to: %w[AccountAdmin AccountMembership TeacherEnrollment TaEnrollment StudentEnrollment],
        applies_to_concluded: %w[TeacherEnrollment TaEnrollment]
      },
      select_final_grade: {
        label: -> { I18n.t("Grades - select final grade for moderation") },
        true_for: %w[AccountAdmin TeacherEnrollment TaEnrollment],
        available_to: %w[AccountAdmin AccountMembership TeacherEnrollment TaEnrollment]
      },
      send_messages: {
        label: -> { I18n.t("permissions.send_messages", "Send messages to individual course members") },
        label_v2: -> { I18n.t("Conversations - send messages to individual course members") },
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
        label: -> { I18n.t("permissions.send_messages_all", "Send messages to the entire class") },
        label_v2: -> { I18n.t("Conversations - send messages to entire class") },
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
        label: -> { I18n.t("Grades - view audit trail") },
        true_for: %w[AccountAdmin],
        available_to: %w[TeacherEnrollment AccountAdmin AccountMembership]
      },
      view_all_grades: {
        label: -> { I18n.t("permissions.view_all_grades", "View all grades") },
        label_v2: -> { I18n.t("Grades - view all grades") },
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
        label: -> { I18n.t("permissions.view_group_pages", "View the group pages of all student groups") },
        label_v2: -> { I18n.t("Groups - view all student groups") },
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
        label: -> { I18n.t("permissions.view_quiz_answer_audits", "View the answer matrix in Quiz Submission Logs") },
        label_v2: -> { I18n.t("Quizzes - view submission log") },
        true_for: %w[AccountAdmin],
        available_to: %w[AccountAdmin AccountMembership],
        account_allows: ->(a) { a.feature_allowed?(:quiz_log_auditing) }
      },
      view_user_logins: {
        label: -> { I18n.t("View login ids for users") },
        label_v2: -> { I18n.t("Users - view login IDs") },
        available_to: %w[AccountAdmin AccountMembership TeacherEnrollment TaEnrollment],
        true_for: %w[AccountAdmin TeacherEnrollment TaEnrollment],
        applies_to_concluded: %w[TeacherEnrollment TaEnrollment]
      },
      view_admin_analytics: {
        label: -> { I18n.t("Admin Analytics - view and export data") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: %w[AccountAdmin],
        account_only: true,
        account_allows: ->(a) { a.feature_enabled?(:admin_analytics_view_permission) }
      },
      view_analytics_hub: {
        label: -> { I18n.t("Analytics Hub") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: %w[AccountAdmin],
        account_only: true,
        account_allows: ->(a) { a.feature_enabled?(:analytics_hub) }
      },
      view_ask_questions_analytics: {
        label: -> { I18n.t("Ask Your Data") },
        group: "view_advanced_analytics",
        group_label: -> { I18n.t("Intelligent Insights") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: %w[AccountAdmin],
        account_only: true,
        account_allows: ->(a) { a.feature_enabled?(:advanced_analytics_ask_questions) }
      },
      view_students_in_need: {
        label: -> { I18n.t("Students in Need of Attention") },
        group: "view_advanced_analytics",
        group_label: -> { I18n.t("Intelligent Insights") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: %w[AccountAdmin],
        account_only: true,
        account_allows: ->(a) { a.feature_enabled?(:k20_students_in_need_of_attention) }
      },
      view_students_in_need_in_course: {
        label: -> { I18n.t("Intelligent Insights - Students in Need of Attention - Course Level") },
        available_to: %w[AccountAdmin AccountMembership TeacherEnrollment TaEnrollment],
        true_for: %w[AccountAdmin],
        account_allows: ->(a) { a.feature_enabled?(:k20_students_in_need_of_attention) && a.feature_enabled?(:students_in_need_of_attention_course_level_beta) } ## AND they are part of the beta group.
      },
      view_course_readiness: {
        label: -> { I18n.t("Course Readiness") },
        group: "view_advanced_analytics",
        group_label: -> { I18n.t("Intelligent Insights") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: %w[AccountAdmin],
        account_only: true,
        account_allows: ->(a) { a.feature_enabled?(:k20_course_readiness) }
      },
      view_lti_usage: {
        label: -> { I18n.t("LTI Usage") },
        group: "view_advanced_analytics",
        group_label: -> { I18n.t("Intelligent Insights") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: %w[AccountAdmin],
        account_only: true,
        account_allows: ->(a) { a.feature_enabled?(:k20_lti_usage) }
      },
      view_title_iv_financial_aid_report: {
        label: -> { I18n.t("Financial Aid Compliance") },
        group: "view_advanced_analytics",
        group_label: -> { I18n.t("Intelligent Insights") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: %w[AccountAdmin],
        account_only: true,
        account_allows: ->(a) { a.feature_enabled?(:title_iv_financial_aid_report) }
      },
      manage_impact: {
        label: -> { I18n.t("Manage Impact") },
        label_v2: -> { I18n.t("Impact - Manage") },
        available_to: %w[AccountAdmin AccountMembership],
        true_for: %w[AccountAdmin],
        account_only: :root
      },
      block_editor_template_editor: {
        label: -> { I18n.t("Block Editor Templates - edit") },
        available_to: %w[TeacherEnrollment DesignerEnrollment AccountAdmin AccountMembership],
        true_for: %w[AccountAdmin],
        account_allows: ->(a) { a.feature_enabled?(:block_editor) && a.feature_enabled?(:block_template_editor) }
      },
      block_editor_global_template_editor: {
        label: -> { I18n.t("Block Editor Global Templates - edit") },
        available_to: %w[TeacherEnrollment DesignerEnrollment AccountAdmin AccountMembership],
        true_for: %w[AccountAdmin],
        account_allows: ->(a) { a.feature_enabled?(:block_editor) && a.feature_enabled?(:block_template_editor) }
      }
    }
  )
end

Rails.application.config.after_initialize do
  Permissions.retrieve.freeze
end
