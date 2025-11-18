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
# `group` values are keys into PERMISSION_GROUPS defined in permissions_groups.rb.
# help text can be provided in `details` or `considerations` (which will apply in both account and course contexts)
# and or `account_` / `course_` prefixed versions, which will only apply in those contexts.
BASE_PERMISSIONS = {
  become_user: {
    label: -> { I18n.t("Users - act as") },
    account_only: :root,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
    account_details: [
      { title: -> { I18n.t("People (Account)") },
        description: -> { I18n.t("Allows user to act as other users in the account.") } },
      { description: -> { I18n.t("This permission should only be assigned to users that your institution has authorized to act as other users in your entire Canvas account.") } },
      { description: -> { I18n.t("Users with this permission may be able to use the Act as feature to manage account settings, view and adjust grades, access user information, etc.") } },
      { title: -> { I18n.t("Student Context Card") },
        description: -> { I18n.t("Allows user to access the Act as User link on student context cards.") } },
      { title: -> { I18n.t("SpeedGrader") },
        description: -> { I18n.t("Allows user to delete a submission file.") } },
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("Allows user to view Login IDs in a course People page.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("API") },
        description: -> { I18n.t("The Roles API refers to this permission as become_user.") } },
      { title: -> { I18n.t("People (Account)") },
        description: -> { I18n.t("To view the list of users in an account, Users - view list must be enabled.") } },
      { title: -> { I18n.t("Student Context Card") },
        description: -> { I18n.t("Student Context Cards must be enabled for an account by an admin.") } },
      { title: -> { I18n.t("Subaccounts") },
        description: -> { I18n.t("Not available at the subaccount level.") } }
    ]
  },
  import_sis: {
    label: -> { I18n.t("SIS Data - import") },
    account_only: :root,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
    account_details: [
      { title: -> { I18n.t("Account Navigation") },
        description: -> { I18n.t("Determines visibility and management of SIS Import link in Account Navigation.") } },
      { title: -> { I18n.t("SIS Import") },
        description: -> { I18n.t("Allows user to import SIS data.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("SIS Import") },
        description: -> { I18n.t("To manage SIS data, SIS Data - manage must also be enabled.") } },
      { title: -> { I18n.t("Subaccounts") },
        description: -> { I18n.t("Not available at the subaccount level") } }
    ]
  },
  create_access_tokens: {
    label: -> { I18n.t("Access Tokens - create / update") },
    account_only: :root,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
    account_allows: ->(a) { a.feature_enabled?(:admin_manage_access_tokens) },
    group: :users_manage_access_tokens,
    account_details: [
      {
        title: -> { I18n.t("Access Tokens") },
        description: -> { I18n.t("Allows user to create and update other user's access tokens.") }
      }
    ]
  },
  delete_access_tokens: {
    label: -> { I18n.t("Access Tokens - delete") },
    account_only: :root,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
    # Doesn't make a ton of sense for admins to be able to view access tokens but not delete them, hence the
    # site admin check.
    account_allows: ->(a) { Account.site_admin.feature_enabled?(:student_access_token_management) || a.feature_enabled?(:admin_manage_access_tokens) },
    group: :users_manage_access_tokens,
    account_details: [
      {
        title: -> { I18n.t("Access Tokens") },
        description: -> { I18n.t("Allows user to delete other user's access tokens.") }
      }
    ]
  },
  view_user_generated_access_tokens: {
    label: -> { I18n.t("Manually Generated Access Tokens - view") },
    account_only: :root,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
    account_allows: ->(_) { Account.site_admin.feature_enabled?(:student_access_token_management) },
    group: :users_manage_access_tokens,
    account_details: [
      {
        title: -> { I18n.t("Access Tokens") },
        description: -> { I18n.t("Allows user to view other user's manually generated access tokens. This does not let them read the actual token value itself, just the information about it.") }
      }
    ]
  },
  manage_account_memberships: {
    label: -> { I18n.t("Admins - add / remove") },
    available_to: %w[AccountMembership],
    true_for: %w[AccountAdmin],
    account_only: true,
    account_details: [
      { title: -> { I18n.t("Account Settings") },
        description: -> { I18n.t("Allows user to add and remove other account admins.") } },
      { title: -> { I18n.t("Commons") },
        description: -> { I18n.t("Allows user to access and edit the Admin settings in Commons.") } },
      { description: -> { I18n.t("Allows user to create and manage Groups. Allows user to manage shared resources in the account.") } },
      { description: -> { I18n.t("Allows user to manage shared resources in the account.") } }
    ]
  },
  manage_account_settings: {
    label: -> { I18n.t("Account-level settings - manage") },
    available_to: %w[AccountMembership],
    true_for: %w[AccountAdmin],
    account_only: true,
    account_details: [
      { title: -> { I18n.t("Account Settings") },
        description: -> { I18n.t("Allows user to view and manage the Settings and Notifications tabs in Account Settings.") } },
      { title: -> { I18n.t("Authentication") },
        description: -> { I18n.t("Allows user to view and manage authentication options for the whole account.") } },
      { title: -> { I18n.t("Subaccounts") },
        description: -> { I18n.t("Allows user to view and manage subaccounts for the account.") } },
      { title: -> { I18n.t("Terms") },
        description: -> { I18n.t("Allows user to view and manage terms for the account.") } },
      { title: -> { I18n.t("Theme Editor") },
        description: -> { I18n.t("Allows user to access the Theme Editor.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Announcements") },
        description: -> { I18n.t("The Announcements tab is always visible to admins; however, to manage announcements, Global Announcements - add / edit / delete must also be enabled.") } },
      { title: -> { I18n.t("Feature Options (Account Settings)") },
        description: -> { I18n.t("To manage the Feature Options tab, Feature Options - enable disable - must also be enabled.") } },
      { title: -> { I18n.t("Reports (Account Settings)") },
        description: -> { I18n.t("To view the Reports tab, Reports - manage must also be enabled.") } },
      { title: -> { I18n.t("Subaccount Navigation (Account Settings)") },
        description: -> { I18n.t("Not all settings options are available at the subaccount level, including the Notifications tab.") } }
    ]
  },
  manage_alerts: {
    label: -> { I18n.t("Global Announcements - add / edit / delete") },
    account_only: true,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
    account_details: [
      { title: -> { I18n.t("Announcements (Account)") },
        description: -> { I18n.t("Allows user to add, edit, and delete global announcements.") } }
    ]
  },
  manage_catalog: {
    label: -> { I18n.t("Catalog - manage") },
    account_only: true,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
    account_allows: ->(a) { a.settings[:catalog_enabled] }
  },
  manage_courses_admin: {
    label: -> { I18n.t("Courses - manage / update") },
    group: :manage_courses,
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_only: true
  },
  manage_courses_add: {
    label: -> { I18n.t("Courses - add") },
    group: :manage_courses,
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_only: true
  },
  manage_courses_publish: {
    label: -> { I18n.t("Courses - publish") },
    group: :manage_courses,
    available_to: %w[AccountAdmin AccountMembership TeacherEnrollment TaEnrollment DesignerEnrollment],
    true_for: %w[AccountAdmin TeacherEnrollment DesignerEnrollment]
  },
  manage_courses_conclude: {
    label: -> { I18n.t("Courses - conclude") },
    group: :manage_courses,
    available_to: %w[AccountAdmin AccountMembership TeacherEnrollment TaEnrollment DesignerEnrollment],
    true_for: %w[AccountAdmin TeacherEnrollment DesignerEnrollment]
  },
  manage_courses_reset: {
    label: -> { I18n.t("Courses - reset") },
    group: :manage_courses,
    available_to: %w[AccountAdmin AccountMembership TeacherEnrollment DesignerEnrollment],
    true_for: %w[AccountAdmin]
  },
  manage_courses_delete: {
    label: -> { I18n.t("Courses - delete") },
    group: :manage_courses,
    available_to: %w[AccountAdmin AccountMembership TeacherEnrollment DesignerEnrollment],
    true_for: %w[AccountAdmin]
  },
  undelete_courses: {
    label: -> { I18n.t("Courses - undelete") },
    admin_tool: true,
    account_only: true,
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_details: [
      { title: -> { I18n.t("Admin Tools (Restore Courses tab)") },
        description: -> { I18n.t("Allows user to access the Restore Courses tab in Admin Tools.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Admin Tools (Restore Courses tab)") },
        description: -> { I18n.t("To search for a course in the Restore Courses tab, Course Content - view must also be enabled.") } },
      { description: -> { I18n.t("To restore a deleted course in an account, Manage Courses - delete and Course Content - view must also be enabled.") } }
    ]
  },
  view_archived_courses: {
    label: -> { I18n.t("Courses - view archived") },
    group: :manage_courses,
    available_to: %w[AccountAdmin AccountMembership TeacherEnrollment DesignerEnrollment],
    true_for: %w[AccountAdmin],
    account_allows: ->(a) { a.root_account.feature_enabled?(:course_archival) }
  },
  manage_data_services: {
    label: -> { I18n.t("Data Services - manage ") },
    account_only: true,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
    account_details: [
      { title: -> { I18n.t("Data Services") },
        description: -> { I18n.t("Allows user to access and manage Canvas Data Services.") } }
    ]
  },
  manage_course_visibility: {
    label: -> { I18n.t("Courses - change visibility") },
    available_to: %w[AccountAdmin AccountMembership TeacherEnrollment TaEnrollment DesignerEnrollment],
    true_for: %w[AccountAdmin TeacherEnrollment TaEnrollment DesignerEnrollment],
    details: [
      { title: -> { I18n.t("Course Settings") },
        description: -> { I18n.t("Allows user to manage the Visibility options in Course Settings or when creating a new course.") } }
    ]
  },
  manage_developer_keys: {
    label: -> { I18n.t("Developer Keys - manage ") },
    account_only: true,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
    account_details: [
      { title: -> { I18n.t("Developer Keys") },
        description: -> { I18n.t("Allows user to create developer keys for accounts.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Developer Keys") },
        description: -> { I18n.t("Required fields include key name, owner email, tool ID, redirect URL, and icon URL.") } },
      { title: -> { I18n.t("Subaccounts") },
        description: -> { I18n.t("Not available at the subaccount level.") } }
    ]
  },
  moderate_user_content: {
    label: -> { I18n.t("Users - moderate content") },
    account_only: true,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
    account_details: [
      { title: -> { I18n.t("ePortfolios") },
        description: -> { I18n.t("Allows user to view the ePortfolio Moderation page and manage ePortfolio spam content.") } }
    ]
  },
  view_feature_flags: {
    label: -> { I18n.t("Feature Options - view") },
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
    account_details: [
      { title: -> { I18n.t("Feature Options (Account Settings)") },
        description: -> { I18n.t("Allows user to view Feature Options in Account Settings.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Feature Options (Account Settings)") },
        description: -> { I18n.t("To manage Feature Options for an account, Feature Options - enable / disable must also be enabled.") } }
    ]
  },
  manage_feature_flags: {
    label: -> { I18n.t("Feature Options - enable / disable") },
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
    account_details: [
      { title: -> { I18n.t("Feature Options (Account Settings)") },
        description: -> { I18n.t("Allows user to manage Feature Options in Account Settings.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Feature Options (Account Settings)") },
        description: -> { I18n.t("To view Feature Options for an account, Feature Options - enable / disable must also be enabled.") } }
    ]
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
    label: -> { I18n.t("LTI Registrations - Manage") },
    account_only: true,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
    account_allows: ->(a) { a.root_account.feature_enabled?(:lti_registrations_page) },
    account_details: [
      { title: -> { I18n.t("LTI Registrations - Manage") },
        description: -> { I18n.t("Allows users to view, add, modify, and delete LTI 1.3 tool registrations on the new Apps page.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Additional Requirements") },
        description: -> { I18n.t("The Developer Keys - Manage permission must also be enabled for the Apps link to appear.") } }
    ]
  },
  manage_release_notes: {
    label: -> { I18n.t("Manage release notes") },
    account_only: :site_admin,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
  },
  manage_master_courses: {
    label: -> { I18n.t("Blueprint Courses - add / edit / associate / delete") },
    available_to: %w[AccountAdmin AccountMembership],
    account_only: true,
    true_for: %w[AccountAdmin],
    account_details: [
      { title: -> { I18n.t("Blueprint Courses") },
        description: -> { I18n.t("Allows user to designate a course as a Blueprint Course.") } },
      { description: -> { I18n.t("Allows user to manage Blueprint Course settings in Course Settings.") } },
      { description: -> { I18n.t("Allows user to add and remove associated courses.") } },
      { description: -> { I18n.t("Allows user to edit lock settings on individual assignments, pages, or discussions.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Blueprint Courses") },
        description: -> { I18n.t("Course roles can only manage Blueprint Courses if they are added to the Blueprint Course as a teacher, TA, or designer role.") } },
      { description: -> { I18n.t("To manage associated courses, Courses - view list and Courses - manage / update must also be enabled.") } },
      { description: -> { I18n.t("To edit lock settings on files, Courses - manage and Course Files - edit must also be enabled.") } },
      { description: -> { I18n.t("To edit lock settings on quizzes, Courses - manage and Assignments and Quizzes - manage / edit must also be enabled.") } },
      { description: -> { I18n.t("To manage lock settings for object types, Courses - manage must also be enabled.") } }
    ]
  },
  manage_role_overrides: {
    label: -> { I18n.t("Permissions - manage") },
    account_only: true,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountMembership],
    account_details: [
      { title: -> { I18n.t("Permissions") },
        description: -> { I18n.t("Allows user to view and manage permissions.") } }
    ]
  },
  manage_storage_quotas: {
    label: -> { I18n.t("Storage Quotas - manage") },
    account_only: true,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
    account_details: [
      { title: -> { I18n.t("Quotas (Account Settings)") },
        description: -> { I18n.t("Allows user to view and manage Quotas tab in Account Settings. User can set default course, user, and group storage quotes.") } }
    ]
  },
  manage_sis: {
    label: -> { I18n.t("SIS Data - manage") },
    account_only: :root,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
    account_details: [
      { title: -> { I18n.t("Account Navigation") },
        description: -> { I18n.t("Determines visibility of SIS Import link in Account Navigation.") } },
      { description: -> { I18n.t("Allows user to view the previous SIS import dates, errors, and imported items.") } },
      { title: -> { I18n.t("Course Settings") },
        description: -> { I18n.t("Allows user to edit the course SIS ID.") } },
      { title: -> { I18n.t("People (Account)") },
        description: -> { I18n.t("Allows user to view and edit the SIS ID and Integration ID in a user’s Login Details.") } },
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("Allows user to edit the course SIS ID.") } },
      { title: -> { I18n.t("Subaccount Settings") },
        description: -> { I18n.t("Allows user to view and insert data in the SIS ID field.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Course Settings") },
        description: -> { I18n.t("To edit course settings, Courses - manage must be enabled.") } },
      { title: -> { I18n.t("People (Account)") },
        description: -> { I18n.t("To view or edit a user’s SIS ID or Integration ID, Users - view list and Users - manage login details must also both be enabled.") } },
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("If this permission is enabled, users do not need the SIS Data - read permission enabled. The account permission overrides the course permission.") } },
      { description: -> { I18n.t("To disallow users from managing SIS IDs at the course level, SIS Data - manage and SIS Data - read must both be disabled.") } },
      { description: -> { I18n.t("To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).") } },
      { title: -> { I18n.t("SIS Import") },
        description: -> { I18n.t("To import SIS data, SIS Data - import must also be enabled.") } },
      { title: -> { I18n.t("Subaccounts") },
        description: -> { I18n.t("Not available at the subaccount level.") } }
    ]
  },
  manage_site_settings: {
    label: -> { I18n.t("permissions.manage_site_settings", "Manage site-wide and plugin settings") },
    account_only: :site_admin,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
  },
  manage_rate_limiting: {
    label: -> { I18n.t("Account - Rate Limiting") },
    account_only: :site_admin,
    available_to: %w[AccountAdmin AccountMembership],
    true_for: [],
    account_allows: ->(a) { a.feature_enabled?(:api_rate_limits) },
    account_details: [
      { title: -> { I18n.t("Rate Limiting Management") },
        description: -> { I18n.t("Allows user to manage API rate limits for external tools and integrations.") } }
    ],
  },
  manage_internal_settings: {
    label: -> { I18n.t("permissions.manage_internal_settings", "Manage environment-wide internal settings") },
    account_only: :site_admin,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
  },
  manage_user_logins: {
    label: -> { I18n.t("Users - manage login details") },
    available_to: %w[AccountAdmin AccountMembership],
    account_only: :root,
    true_for: %w[AccountAdmin],
    account_details: [
      { title: -> { I18n.t("People (Account)") },
        description: -> { I18n.t("Allows user to create accounts for new users.") } },
      { description: -> { I18n.t("Allows user to remove and merge users in an account.") } },
      { description: -> { I18n.t("Allows user to modify user account details.") } },
      { description: -> { I18n.t("Allows user to view and modify login information for a user.") } },
      { title: -> { I18n.t("Admin Tools (Logging tab)") },
        description: -> { I18n.t("Allows user to generate login/logout activity report in Admin Tools.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Admin Tools (Logging tab)") },
        description: -> { I18n.t("If Users - manage login details or Statistics - view is enabled, the user will be able to generate login/logout activity in Admin Tools. To hide the login/logout activity option in Admin Tools, both of these permissions need to be disabled.") } },
      { title: -> { I18n.t("People (Account)") },
        description: -> { I18n.t("To view users and user account details, Users - view list must be enabled.") } },
      { description: -> { I18n.t("To change user passwords, Users - view must also be enabled.") } },
      { description: -> { I18n.t("To view a user’s SIS ID, SIS Data - manage or SIS Data - read must also be enabled.") } },
      { description: -> { I18n.t("To view a user’s Integration ID, SIS Data - manage must also be enabled.") } },
      { description: -> { I18n.t("To merge users, the Self Service User Merge feature option must also be enabled.") } },
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).") } },
      { title: -> { I18n.t("Subaccounts") },
        description: -> { I18n.t("Not available at the subaccount level.") } }
    ]
  },
  manage_dsr_requests: {
    label: -> { I18n.t("Users - create DSR export") },
    available_to: %w[AccountAdmin AccountMembership],
    account_only: :root,
    true_for: %w[AccountAdmin],
    account_allows: ->(a) { Feature.exists?(:enable_dsr_requests) && a.feature_enabled?(:enable_dsr_requests) },
    account_details: [
      { title: -> { I18n.t("Users - create DSR export") },
        description: -> { I18n.t("Allows user to create DSR exports.") } },
      { description: -> { I18n.t("Allows user to download completed DSR exports.") } }
    ]
  },
  manage_user_observers: {
    label: -> { I18n.t("Users - manage observers") },
    account_only: :root,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
    account_details: [
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("Allows user to manage observers associated with students in the account.") } }
    ]
  },
  read_course_content: {
    label: -> { I18n.t("Course Content - view") },
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
    account_details: [
      { title: -> { I18n.t("Courses") },
        description: -> { I18n.t("Allows user to view published and unpublished course content.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Admin Tools (Undelete Courses)") },
        description: -> { I18n.t("If Courses - manage and Courses - undelete are also enabled, an account-level user will be able to restore deleted courses in Admin Tools.") } },
      { title: -> { I18n.t("Courses") },
        description: -> { I18n.t("If disabled, user will still have access to Course Settings.") } },
      { description: -> { I18n.t("User cannot manage individual course content without the appropriate permission for that content item.") } },
      { description: -> { I18n.t("If course visibility is limited to users enrolled in the course, this permission allows the user to view course content without being enrolled in the course.") } },
      { title: -> { I18n.t("Gradebook") },
        description: -> { I18n.t("To view the Gradebook, Grades - view all grades must also be enabled.") } }
    ]
  },
  read_course_list: {
    label: -> { I18n.t("Courses - view list") },
    account_only: true,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
    account_details: [
      { title: -> { I18n.t("Blueprint Courses") },
        description: -> { I18n.t("Allows user to filter for Blueprint courses as the account level. Allows user to add associated courses.") } },
      { title: -> { I18n.t("Courses") },
        description: -> { I18n.t("Allows user to see the list of courses in the account.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Account Settings") },
        description: -> { I18n.t("If this permission is disabled and Courses - add is enabled, users can add a new course with the Add a New Course button in Account Settings.") } },
      { title: -> { I18n.t("Blueprint Courses") },
        description: -> { I18n.t("To add associated courses, Blueprint Courses - add / edit / associate / delete and Courses - add must also be enabled.") } },
      { title: -> { I18n.t("Statistics") },
        description: -> { I18n.t("Allows user to see the list of recently started and ended courses in account statistics.") } }
    ]
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
    label: -> { I18n.t("Courses - view change logs") },
    admin_tool: true,
    account_only: :root,
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_details: [
      { title: -> { I18n.t("Admin Tools (Logging tab)") },
        description: -> { I18n.t("Determines visibility of the Course Activity option in the Admin Tools Logging tab.") } },
      { description: -> { I18n.t("Allows user to view course activity information for the account.") } }
    ]
  },
  view_error_reports: {
    label: -> { I18n.t("permissions.view_error_reports", "View error reports") },
    account_only: :site_admin,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
  },
  view_grade_changes: {
    label: -> { I18n.t("Grades - view change logs") },
    admin_tool: true,
    account_only: true,
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_details: [
      { title: -> { I18n.t("Admin Tools (Logging tab)") },
        description: -> { I18n.t("Determines visibility of the Grade Change Activity option in the Admin Tools Logging tab.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Admin Tools (Logging tab)") },
        description: -> { I18n.t("To search by grader or student ID, Users - view must also be enabled.") } },
      { description: -> { I18n.t("To search by course ID or assignment ID, Grades - edit must also be enabled.") } },
      { description: -> { I18n.t("To search by assignment ID only, Grades - view all grades must also be enabled.") } }
    ]
  },
  view_jobs: {
    label: -> { I18n.t("permissions.view_jobs", "View background jobs") },
    account_only: :site_admin,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
  },
  view_notifications: {
    label: -> { I18n.t("Notifications - view") },
    admin_tool: true,
    account_only: true,
    available_to: %w[AccountAdmin AccountMembership],
    true_for: [],
    account_allows: ->(acct) { acct.settings[:admins_can_view_notifications] },
    account_details: [
      { title: -> { I18n.t("Admin Tools (Notifications tab)") },
        description: -> { I18n.t("Allows user to access the View Notifications tab in Admin Tools.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Admin Tools (Notifications tab)") },
        description: -> { I18n.t("To search and view notifications for a user, Users - view must also be enabled.") } },
      { title: -> { I18n.t("Subaccounts") },
        description: -> { I18n.t("Not available at the subaccount level.") } }
    ]
  },
  view_statistics: {
    label: -> { I18n.t("Statistics - view") },
    account_only: true,
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
    account_details: [
      { title: -> { I18n.t("Account Statistics") },
        description: -> { I18n.t("Allows admin user to view account statistics.") } },
      { title: -> { I18n.t("Admin Tools (Logging tab)") },
        description: -> { I18n.t("Allows user to generate login/logout activity report in Admin Tools.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Admin Tools (Logging tab)") },
        description: -> { I18n.t("If Statistics - view or Users - manage login details is enabled, the user will be able to generate login/logout activity in Admin Tools. To hide the login/logout activity option in Admin Tools, both of these permissions need to be disabled.") } },
      { title: -> { I18n.t("People (Account)") },
        description: -> { I18n.t("To view user page views, Users - view list must also be enabled.") } },
      { title: -> { I18n.t("Subaccounts") },
        description: -> { I18n.t("Not available at the subaccount level.") } }
    ]
  },
  create_collaborations: {
    label: -> { I18n.t("Student Collaborations - create") },
    available_to: %w[StudentEnrollment
                     TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[StudentEnrollment TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    details: [
      { title: -> { I18n.t("Collaborations") },
        description: -> { I18n.t("Allows user to create collaborations.") } },
      { description: -> { I18n.t("Allows user to view, edit, and delete collaborations they created.") } }
    ],
    considerations: [
      { title: -> { I18n.t("Collaborations") },
        description: -> { I18n.t("To allow view edit delete functionality of collaborations created by other users, Course Content - add / edit / delete must also be enabled.") } },
      { description: -> { I18n.t("If Course Content - add / edit / delete is enabled and Student Collaborations - create is disabled, the user will not be able to create new collaborations but will be able to view edit delete all collaborations.") } },
      { description: -> { I18n.t("To add students to a collaboration, Users - view list must also be enabled.") } },
      { description: -> { I18n.t("To add a course group to a collaboration, Groups - add must also be enabled.") } }
    ],
  },
  create_conferences: {
    label: -> { I18n.t("Web Conferences - create") },
    available_to: %w[StudentEnrollment
                     TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[StudentEnrollment TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    details: [
      { title: -> { I18n.t("Conferences") },
        description: -> { I18n.t("Allows user to create new conferences in courses and groups.") } },
      { description: -> { I18n.t("Allows user to start conferences they created.") } }
    ],
    considerations: [
      { title: -> { I18n.t("Conferences") },
        description: -> { I18n.t("To allow full management of conferences created by the user or others, the Course Content permission must also be enabled.") } },
      { description: -> { I18n.t("To end a long-running conference, the Course Content permission must be enabled.") } },
      { description: -> { I18n.t("If the Course Content permission enabled and Web Conferences - create is disabled, the user can still manage conferences.") } }
    ]
  },
  create_forum: {
    label: -> { I18n.t("Discussions - create") },
    available_to: %w[StudentEnrollment
                     TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[StudentEnrollment TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    restrict_future_enrollments: true,
    details: [
      { title: -> { I18n.t("Discussions") },
        description: -> { I18n.t("Allows user to add discussions in the Discussions page.") } }
    ],
    considerations: [
      { title: -> { I18n.t("Announcements") },
        description: -> { I18n.t("To create announcements, Discussions - moderate must also be enabled.") } },
      { title: -> { I18n.t("Discussions") },
        description: -> { I18n.t("To view discussions in a course, Discussions - view must be enabled.") } },
      { description: -> { I18n.t("Both Discussions - create and Discussions - moderate allow the user to create a discussion in the Discussions page.") } },
      { description: -> { I18n.t("To manage discussions, Discussions - moderate must also be enabled.") } }
    ]
  },
  generate_observer_pairing_code: {
    label: -> { I18n.t("Users - generate observer pairing codes for students") },
    true_for: %w[AccountAdmin],
    available_to: %w[TeacherEnrollment
                     ObserverEnrollment
                     TaEnrollment
                     AccountAdmin
                     AccountMembership
                     DesignerEnrollment],
    account_details: [
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("Allows user to generate a pairing code on behalf of a student to share with an observer.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("To generate a pairing code from a student`s User Settings page, the User - act as permission must also be enabled.") } },
      { description: -> { I18n.t("To generate a pairing code from a student`s User Details page, the Users - allow administrative actions in courses permission must also be enabled.") } },
      { description: -> { I18n.t("Pairing codes are only supported when self registration is enabled for the account.") } },
      { description: -> { I18n.t("QR codes are not the same as pairing codes and are only used to help users log into their own accounts via the Canvas mobile apps. To disable QR code logins for all users in your account, please contact your Customer Success Manager.") } }
    ],
    course_details: [
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("Allows user to generate a pairing code on behalf of a student to share with an observer.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("To generate a pairing code from a student`s User Details page, the Users - allow administrative actions in courses permission must also be enabled.") } },
      { description: -> { I18n.t("Pairing codes are only supported when self registration is enabled for the course.") } },
      { description: -> { I18n.t("QR codes are not the same as pairing codes and are only used to help users log into their own accounts via the Canvas mobile apps.") } }
    ]
  },
  import_outcomes: {
    label: -> { I18n.t("Learning Outcomes - import") },
    available_to: %w[TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[DesignerEnrollment TeacherEnrollment AccountAdmin],
    details: [
      { title: -> { I18n.t("Outcomes") },
        description: -> { I18n.t("Allows user to import account learning outcomes.") } }
    ]
  },
  manage_lti_add: {
    label: -> { I18n.t("LTI - add") },
    group: :manage_lti,
    available_to: %w[TeacherEnrollment TaEnrollment DesignerEnrollment AccountAdmin AccountMembership],
    true_for: %w[TeacherEnrollment TaEnrollment DesignerEnrollment AccountAdmin]
  },
  manage_lti_edit: {
    label: -> { I18n.t("LTI - edit") },
    group: :manage_lti,
    available_to: %w[TeacherEnrollment TaEnrollment DesignerEnrollment AccountAdmin AccountMembership],
    true_for: %w[TeacherEnrollment TaEnrollment DesignerEnrollment AccountAdmin]
  },
  manage_lti_delete: {
    label: -> { I18n.t("LTI - delete") },
    group: :manage_lti,
    available_to: %w[TeacherEnrollment TaEnrollment DesignerEnrollment AccountAdmin AccountMembership],
    true_for: %w[TeacherEnrollment TaEnrollment DesignerEnrollment AccountAdmin]
  },
  allow_course_admin_actions: {
    label: -> { I18n.t("Users - allow administrative actions in courses") },
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TeacherEnrollment AccountAdmin],
    details: [
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("Allows user to view login ID information for users.") } },
      { description: -> { I18n.t("Allows user to view user details for course users.") } },
      { description: -> { I18n.t("Allows user to edit a user’s section or role (if not added via SIS).") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("People (Account)") },
        description: -> { I18n.t("To edit user details, modify login details, or change user passwords, Users - manage login details must also be enabled.") } },
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("To view the People page, Courses - view list must be enabled.") } },
      { description: -> { I18n.t("To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).") } },
      { description: -> { I18n.t("To view SIS IDs, SIS Data - read must be enabled.") } },
      { description: -> { I18n.t("To edit a user’s section, Conversations - send to individual course members must be enabled.") } },
      { title: -> { I18n.t("Observers (Course)") },
        description: -> { I18n.t("To link an observer to a student, Users - manage login details and Conversations - send to individual course members must be enabled.") } },
      { description: -> { I18n.t("To generate a pairing code on behalf of a student to share with an observer, Users - Generate observer pairing code for students must also be enabled.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("To view the People page, Courses - view list must be enabled.") } },
      { description: -> { I18n.t("To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).") } },
      { description: -> { I18n.t("To view SIS IDs, SIS Data - read must be enabled.") } },
      { description: -> { I18n.t("To edit a user’s section, Conversations - send to individual course members must be enabled.") } },
      { title: -> { I18n.t("Observers") },
        description: -> { I18n.t("To link an observer to a student, Conversations - send to individual course members must be enabled.") } },
      { description: -> { I18n.t("To generate a pairing code on behalf of a student to share with an observer, Users - Generate observer pairing code for students must also be enabled.") } }
    ]
  },
  add_teacher_to_course: {
    label: -> { I18n.t("Teachers - add") },
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TeacherEnrollment AccountAdmin],
    group: :manage_course_teacher_enrollments,
  },
  remove_teacher_from_course: {
    label: -> { I18n.t("Teachers - remove") },
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TeacherEnrollment AccountAdmin],
    group: :manage_course_teacher_enrollments,
  },
  add_ta_to_course: {
    label: -> { I18n.t("TAs - add") },
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TeacherEnrollment AccountAdmin],
    group: :manage_course_ta_enrollments,
  },
  remove_ta_from_course: {
    label: -> { I18n.t("TAs - remove") },
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TeacherEnrollment AccountAdmin],
    group: :manage_course_ta_enrollments,
  },
  add_observer_to_course: {
    label: -> { I18n.t("Observers - add") },
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    group: :manage_course_observer_enrollments,
  },
  remove_observer_from_course: {
    label: -> { I18n.t("Observers - remove") },
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    group: :manage_course_observer_enrollments,
  },
  add_designer_to_course: {
    label: -> { I18n.t("Designers - add") },
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TeacherEnrollment AccountAdmin],
    group: :manage_course_designer_enrollments,
  },
  remove_designer_from_course: {
    label: -> { I18n.t("Designers - remove") },
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TeacherEnrollment AccountAdmin],
    group: :manage_course_designer_enrollments,
  },
  manage_assignments_add: {
    label: -> { I18n.t("Assignments and Quizzes - add") },
    available_to: %w[TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    acts_as_access_token_scope: true,
    group: :manage_assignments_and_quizzes,
  },
  manage_assignments_edit: {
    label: -> { I18n.t("Assignments and Quizzes - edit") },
    available_to: %w[TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    acts_as_access_token_scope: true,
    group: :manage_assignments_and_quizzes,
  },
  manage_assignments_delete: {
    label: -> { I18n.t("Assignments and Quizzes - delete") },
    available_to: %w[TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    acts_as_access_token_scope: true,
    group: :manage_assignments_and_quizzes,
  },
  manage_account_calendar_visibility: {
    label: -> { I18n.t("Account Calendars - change visibility") },
    group: :manage_account_calendar,
    account_only: true,
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin]
  },
  manage_account_calendar_events: {
    label: -> { I18n.t("Account Calendars - add / edit / delete events") },
    group: :manage_account_calendar,
    account_only: true,
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin]
  },
  manage_calendar: {
    label: -> { I18n.t("Course Calendar - add / edit / delete") },
    available_to: %w[StudentEnrollment
                     TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    details: [
      { title: -> { I18n.t("Calendar") },
        description: -> { I18n.t("Allows user to add, edit, and delete events in the course calendar.") } },
      { title: -> { I18n.t("Scheduler") },
        description: -> { I18n.t("Allows user to create and manage appointments on the calendar using Scheduler.") } }
    ],
    considerations: [
      { title: -> { I18n.t("Calendar") },
        description: -> { I18n.t("Regardless of whether this permission is enabled or disabled, users will still be able to manage events in their personal calendar.") } },
      { title: -> { I18n.t("Scheduler") },
        description: -> { I18n.t("Scheduler must be enabled for your account.") } }
    ]
  },
  manage_course_content_add: {
    label: -> { I18n.t("Course Content - add") },
    group: :manage_course_content,
    available_to: %w[TaEnrollment
                     TeacherEnrollment
                     DesignerEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[TaEnrollment TeacherEnrollment DesignerEnrollment AccountAdmin]
  },
  manage_course_content_edit: {
    label: -> { I18n.t("Course Content - edit") },
    group: :manage_course_content,
    available_to: %w[TaEnrollment
                     TeacherEnrollment
                     DesignerEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[TaEnrollment TeacherEnrollment DesignerEnrollment AccountAdmin]
  },
  manage_course_content_delete: {
    label: -> { I18n.t("Course Content - delete") },
    group: :manage_course_content,
    available_to: %w[TaEnrollment
                     TeacherEnrollment
                     DesignerEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[TaEnrollment TeacherEnrollment DesignerEnrollment AccountAdmin]
  },
  # Course Template account permissions
  add_course_template: {
    label: -> { I18n.t("Course Templates - create") },
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    group: :manage_course_templates,
    account_only: true
  },
  edit_course_template: {
    label: -> { I18n.t("Course Templates - edit") },
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    group: :manage_course_templates,
    account_only: true
  },
  delete_course_template: {
    label: -> { I18n.t("Course Templates - delete") },
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    group: :manage_course_templates,
    account_only: true
  },
  manage_account_banks: {
    label: -> { I18n.t("Item Banks - manage account") },
    available_to: %w[DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_details: [
      { title: -> { I18n.t("Item Banks") },
        description: -> { I18n.t("Allows a user to view and manage all item banks in an account directly from within a course and account.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Item Banks") },
        description: -> { I18n.t("Allows a user to view and manage all item banks in an account from directly within a course.") } }
    ],
    considerations: [
      { title: -> { I18n.t("Item Banks") },
        description: -> { I18n.t("This permission must be disabled for users to only view item banks created by them, shared with them from another user, or shared indirectly via the course they are enrolled in as an instructor.") } }
    ]
  },
  share_banks_with_subaccounts: {
    label: -> { I18n.t("Item Banks - share with subaccounts") },
    available_to: %w[DesignerEnrollment TaEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_allows: ->(_a) { Account.site_admin.feature_enabled?(:new_quizzes_subaccount_sharing_permission) },
    details: [
      { title: -> { I18n.t("Item Banks") },
        description: -> { I18n.t("Allows a user to manage sharing of item banks with subaccounts.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Item Banks") },
        description: -> { I18n.t("If this permission is disabled, users cannot share item banks to subaccounts. When a user with an admin role is granted this permission, the user can share item banks to subaccounts they administer.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("Item Banks") },
        description: -> { I18n.t("If this permission is disabled, users cannot share item banks to subaccounts. When a user with a course role is granted this permission, the user can share item banks to subaccounts they are associated with.") } }
    ]
  },
  manage_files_add: {
    label: -> { I18n.t("Course Files - add") },
    group: :manage_files,
    available_to: %w[TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    acts_as_access_token_scope: true
  },
  manage_files_edit: {
    label: -> { I18n.t("Course Files - edit") },
    group: :manage_files,
    available_to: %w[TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    acts_as_access_token_scope: true
  },
  manage_files_delete: {
    label: -> { I18n.t("Course Files - delete") },
    group: :manage_files,
    available_to: %w[TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    acts_as_access_token_scope: true
  },
  manage_grades: {
    label: -> { I18n.t("Grades - edit") },
    available_to: %w[TaEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TaEnrollment TeacherEnrollment AccountAdmin],
    account_details: [
      { title: -> { I18n.t("Admin Tools (Logging tab)") },
        description: -> { I18n.t("Allows user to search by course ID or assignment ID in grade change logs in Admin Tools (not available at the subaccount level.)") } },
      { title: -> { I18n.t("Analytics") },
        description: -> { I18n.t("Allows user to view student-specific data in Analytics.") } },
      { title: -> { I18n.t("Course Settings") },
        description: -> { I18n.t("Allows user to view the course grading scheme.") } },
      { title: -> { I18n.t("Discussions") },
        description: -> { I18n.t("Allows user to like discussion posts when the Only Graders Can Like checkbox is selected.") } },
      { title: -> { I18n.t("Gradebook") },
        description: -> { I18n.t("Allows user to add, edit, and update grades in the Gradebook.") } },
      { description: -> { I18n.t("Allows user to access Gradebook History. Allows user to access the Learning Mastery Gradebook (if enabled).") } },
      { title: -> { I18n.t("Grading Schemes") },
        description: -> { I18n.t("Allows user to create and modify grading schemes.") } },
      { title: -> { I18n.t("Quizzes") },
        description: -> { I18n.t("Allows user to moderate a quiz and view the quiz statistics page.") } },
      { title: -> { I18n.t("SpeedGrader") },
        description: -> { I18n.t("Allows user to edit grades and add comments in SpeedGrader.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Admin Tools (Logging tab)") },
        description: -> { I18n.t("To search grade change logs, Grades - view change logs must also be enabled.") } },
      { title: -> { I18n.t("Analytics") },
        description: -> { I18n.t("To view student analytics in course analytics, Analytics - view must also be enabled.") } },
      { title: -> { I18n.t("Course Settings") },
        description: -> { I18n.t("To edit course grading schemes, Courses - manage must also be enabled.") } },
      { title: -> { I18n.t("Gradebook, SpeedGrader") },
        description: -> { I18n.t("Gradebook and SpeedGrader will be inaccessible if both Grades - edit and Grades - view all grades are disabled.") } },
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("To view student analytics, Users - view list and Analytics - view must also be enabled.") } },
      { title: -> { I18n.t("Quizzes") },
        description: -> { I18n.t("To moderate a quiz, Assignments and Quizzes - manage / edit must also be enabled.") } },
      { description: -> { I18n.t("To view the user SIS ID column in the Quiz Item Analysis CSV file, SIS Data - read must also be enabled.") } },
      { description: -> { I18n.t("To view the submission log, Quizzes - view submission log must also be enabled.") } },
      { title: -> { I18n.t("Reports") },
        description: -> { I18n.t("To access the Student Interactions report, Reports - manage must also be enabled.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Analytics") },
        description: -> { I18n.t("Allows user to view student-specific data in Analytics.") } },
      { title: -> { I18n.t("Course Settings") },
        description: -> { I18n.t("Allows user to edit grading schemes.") } },
      { title: -> { I18n.t("Discussions") },
        description: -> { I18n.t("Allows user to like discussion posts when the Only Graders Can Like checkbox is selected.") } },
      { title: -> { I18n.t("Gradebook") },
        description: -> { I18n.t("Allows user to edit grades in the Gradebook.") } },
      { description: -> { I18n.t("Allows user to access Gradebook History.") } },
      { description: -> { I18n.t("Allows user to access the Learning Mastery Gradebook (if enabled).") } },
      { title: -> { I18n.t("Quizzes") },
        description: -> { I18n.t("Allows user to moderate a quiz and view the quiz statistics page.") } },
      { title: -> { I18n.t("SpeedGrader") },
        description: -> { I18n.t("Allows user to edit grades and add comments in SpeedGrader.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("Analytics") },
        description: -> { I18n.t("To view student analytics in course analytics, Analytics - view must also be enabled.") } },
      { title: -> { I18n.t("Gradebook, SpeedGrader") },
        description: -> { I18n.t("Gradebook and SpeedGrader will be inaccessible if both Grades - edit and Grades - view all grades are disabled.") } },
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("To view student analytics, Users - view list and Analytics - view must also be enabled.") } },
      { title: -> { I18n.t("Quizzes") },
        description: -> { I18n.t("To moderate a quiz, Assignments and Quizzes - manage / edit must also be enabled.") } },
      { description: -> { I18n.t("To view the user SIS ID column in the Quiz Item Analysis CSV file, SIS Data - read must also be enabled.") } },
      { title: -> { I18n.t("Settings") },
        description: -> { I18n.t("Course Grading Schemes can be enabled/disabled in Course Settings.") } }
    ]
  },
  manage_groups_add: {
    label: -> { I18n.t("Groups - add") },
    group: :manage_groups,
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    acts_as_access_token_scope: true
  },
  manage_groups_manage: {
    label: -> { I18n.t("Groups - manage") },
    group: :manage_groups,
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    acts_as_access_token_scope: true
  },
  manage_groups_delete: {
    label: -> { I18n.t("Groups - delete") },
    group: :manage_groups,
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    acts_as_access_token_scope: true
  },
  manage_tags_add: {
    label: -> { I18n.t("Differentiation Tags - add") },
    group: :manage_differentiation_tags,
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TeacherEnrollment AccountAdmin],
    acts_as_access_token_scope: true,
    account_allows: ->(a) { a.allow_assign_to_differentiation_tags_unlocked? },
    course_details: [
      { title: -> { I18n.t("Allows") },
        description: -> { I18n.t("This permission controls the ability to:") } },
      { description: -> { I18n.t("Create new differentiation tags") } },
      { description: -> { I18n.t("Add users to differentiation tags") } },
      { title: -> { I18n.t("Warning") },
        description: -> { I18n.t("This permission does not allow a user to edit a differentiation tag after it has been created.") } }
    ]
  },
  manage_tags_manage: {
    label: -> { I18n.t("Differentiation Tags - manage") },
    group: :manage_differentiation_tags,
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TeacherEnrollment AccountAdmin],
    acts_as_access_token_scope: true,
    account_allows: ->(a) { a.allow_assign_to_differentiation_tags_unlocked? },
    course_details: [
      { title: -> { I18n.t("What it allows") },
        description: -> { I18n.t("This permission controls the ability to:") } },
      { description: -> { I18n.t("Edit differentiation tag names, variants, and members") } },
      { description: -> { I18n.t("Remove users from differentiation tags") } },
      { description: -> { I18n.t("Add users to differentiation tags") } },
      { title: -> { I18n.t("Warning") },
        description: -> { I18n.t("A user with this permission has the ability to remove users from an assignment by removing tag variants that are assigned to an assignment") } }
    ]
  },
  manage_tags_delete: {
    label: -> { I18n.t("Differentiation Tags - delete") },
    group: :manage_differentiation_tags,
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TeacherEnrollment AccountAdmin],
    acts_as_access_token_scope: true,
    account_allows: ->(a) { a.allow_assign_to_differentiation_tags_unlocked? },
    course_details: [
      { title: -> { I18n.t("What it allows") },
        description: -> { I18n.t("This permission controls the ability to:") } },
      { description: -> { I18n.t("Delete differentiation tags") } },
      { description: -> { I18n.t("Remove users from differentiation tags") } },
      { title: -> { I18n.t("Warning") },
        description: -> { I18n.t("A user who can delete differentiation tags has the ability to remove users from an assignment by deleting the tags assigned to an assignment.") } }
    ]
  },
  manage_interaction_alerts: {
    label: -> { I18n.t("Alerts - add / edit / delete") },
    true_for: %w[AccountAdmin TeacherEnrollment],
    available_to: %w[AccountAdmin AccountMembership TeacherEnrollment TaEnrollment],
    details: [
      { title: -> { I18n.t("Course Settings") },
        description: -> { I18n.t("Allows user to configure alerts in Course Settings.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Account Settings") },
        description: -> { I18n.t("This is an account setting that must be enabled by a Customer Success Manager. Alerts are a seldom-used feature designed to send an alert to students, teachers or admins for specific triggers (e.g., no student-teacher interaction for 7 days). They are checked every day, and notifications will be sent to the student and/or the teacher until the triggering problem is resolved.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("Account Settings") },
        description: -> { I18n.t("Alerts must be configured for the institution. Alerts are a seldom-used feature designed to send an alert to students, teachers or admins for specific triggers (e.g., no student-teacher interaction for 7 days). They are checked every day, and notifications will be sent to the student and/or the teacher until the triggering problem is resolved.") } }
    ]
  },
  manage_outcomes: {
    label: -> { I18n.t("Learning Outcomes - add / edit / delete") },
    available_to: %w[StudentEnrollment
                     TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[DesignerEnrollment TeacherEnrollment AccountAdmin],
    account_details: [
      { title: -> { I18n.t("Outcomes") },
        description: -> { I18n.t("Determines visibility and management of the Outcomes link in Account Navigation.") } },
      { description: -> { I18n.t("Allows user to view the Outcomes Manage tab at the account and course levels.") } },
      { description: -> { I18n.t("Allows user to create, edit, and delete outcomes and outcome groups at the account and course levels.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Outcomes") },
        description: -> { I18n.t("Allows user to create, edit, and delete outcomes and outcome groups at the course level.") } }
    ],
    considerations: [
      { title: -> { I18n.t("Feature Option") },
        description: -> { I18n.t("If the Account and Course Level Outcome Mastery Scales feature option is enabled, the Manage tab displays an updated interface. Additionally, the Outcomes page will display two additional tabs that decouple mastery scales and proficiency calculations from outcomes management.") } },
      { description: -> { I18n.t("Access to these tabs requires the Outcome Proficiency Calculations - add / edit and Outcome Mastery Scales - add / edit permissions.") } },
      { title: -> { I18n.t("Outcomes") },
        description: -> { I18n.t("To allow the Outcomes page as read-only, this permission can be disabled but Course Content - view must be enabled.") } },
      { description: -> { I18n.t("To import learning outcomes, Learning Outcomes - import must also be enabled.") } }
    ]
  },
  manage_proficiency_calculations: {
    label: -> { I18n.t("Outcome Proficiency Calculations - add / edit") },
    available_to: %w[DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_details: [
      { title: -> { I18n.t("Outcomes") },
        description: -> { I18n.t("Allows user to view the Outcomes Calculations tab and set outcome proficiency calculations at the account and course levels.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Feature Option") },
        description: -> { I18n.t("This permission requires the Account and Course Level Outcome Mastery Scales feature option, which must be enabled by a Customer Success Manager.") } },
      { description: -> { I18n.t("This feature affects existing data for an entire account.") } },
      { title: -> { I18n.t("Outcomes") },
        description: -> { I18n.t("If the feature option is enabled, and this permission is enabled, the Outcomes page includes three tabs: Manage, Mastery, and Calculation.") } },
      { description: -> { I18n.t("To access the Mastery tab, the Outcome Mastery Scales - add / edit permission must also be enabled. To access the Manage tab, the Learning Outcomes - add / edit / delete permission must also be enabled.") } },
      { title: -> { I18n.t("Rubrics") },
        description: -> { I18n.t("If this permission is enabled, the Learning Mastery tab displays on the Outcomes page instead of the Rubrics page.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Outcomes") },
        description: -> { I18n.t("Allows user to view the Outcomes Calculation tab and set outcome proficiency calculations at the course level.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("Feature Option") },
        description: -> { I18n.t("This permission requires the Account and Course Level Outcome Mastery Scales feature option, which can only be enabled at the account level.") } },
      { description: -> { I18n.t("This feature affects existing data for all courses in the account.") } },
      { title: -> { I18n.t("Outcomes") },
        description: -> { I18n.t("If the feature option is enabled, and this permission is enabled, the Outcomes page includes three tabs: Manage, Mastery, and Calculation.") } },
      { description: -> { I18n.t("To access the Mastery tab, the Outcome Mastery Scales - add / edit permission must also be enabled. To access the Manage tab, the Learning Outcomes - add / edit / delete permission must also be enabled.") } },
      { title: -> { I18n.t("Rubrics") },
        description: -> { I18n.t("If this permission is enabled, the Learning Mastery tab displays on the Outcomes page instead of the Rubrics page.") } }
    ]
  },
  manage_proficiency_scales: {
    label: -> { I18n.t("Outcome Mastery Scales - add / edit") },
    available_to: %w[DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_details: [
      { title: -> { I18n.t("Outcomes") },
        description: -> { I18n.t("Allows user to view the Outcomes Mastery tab and set outcome mastery scales at the account and course levels.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Feature Option") },
        description: -> { I18n.t("This permission requires the Account and Course Level Outcome Mastery Scales feature option, which must be enabled by a Customer Success Manager.") } },
      { description: -> { I18n.t("This feature affects existing data for an entire account.") } },
      { title: -> { I18n.t("Outcomes") },
        description: -> { I18n.t("If the feature option is enabled, and this permission is enabled, the Outcomes page includes three tabs: Manage, Mastery, and Calculation.") } },
      { description: -> { I18n.t("To access the Calculation tab, the Outcome Proficiency Calculations - add / edit permission must also be enabled. To access the Manage tab, the Learning Outcomes - add / edit / delete permission must also be enabled.") } },
      { title: -> { I18n.t("Rubrics") },
        description: -> { I18n.t("If this permission is enabled, the Learning Mastery tab displays on the Outcomes page instead of the Rubrics page.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Outcomes") },
        description: -> { I18n.t("Allows user to view the Outcomes Mastery tab and set outcome mastery scales at the course level.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("Feature Option") },
        description: -> { I18n.t("This permission requires the Account and Course Level Outcome Mastery Scales feature option, which can only be enabled at the account level.") } },
      { description: -> { I18n.t("This feature affects existing data for all courses in the account.") } },
      { title: -> { I18n.t("Outcomes") },
        description: -> { I18n.t("If the feature option is enabled, and this permission is enabled, the Outcomes page includes three tabs: Manage, Mastery, and Calculation.") } },
      { description: -> { I18n.t("To access the Calculation tab, the Outcome Proficiency Calculations - add / edit permission must also be enabled. To access the Manage tab, the Learning Outcomes - add / edit / delete permission must also be enabled.") } },
      { title: -> { I18n.t("Rubrics") },
        description: -> { I18n.t("If this permission is enabled, the Learning Mastery tab displays on the Outcomes page instead of the Rubrics page.") } }
    ]
  },
  manage_sections_add: {
    label: -> { I18n.t("Course Sections - add") },
    group: :manage_sections,
    available_to: %w[AccountAdmin AccountMembership TeacherEnrollment TaEnrollment DesignerEnrollment],
    true_for: %w[AccountAdmin TeacherEnrollment DesignerEnrollment]
  },
  manage_sections_edit: {
    label: -> { I18n.t("Course Sections - edit") },
    group: :manage_sections,
    available_to: %w[AccountAdmin AccountMembership TeacherEnrollment TaEnrollment DesignerEnrollment],
    true_for: %w[AccountAdmin TeacherEnrollment DesignerEnrollment]
  },
  manage_sections_delete: {
    label: -> { I18n.t("Course Sections - delete") },
    group: :manage_sections,
    available_to: %w[AccountAdmin AccountMembership TeacherEnrollment TaEnrollment DesignerEnrollment],
    true_for: %w[AccountAdmin TeacherEnrollment DesignerEnrollment]
  },
  manage_students: {
    label: -> { I18n.t("Users - manage students in courses") },
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    account_details: [
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("Allows user to view login ID information for students.") } },
      { description: -> { I18n.t("Allows user to view prior enrollments.") } },
      { description: -> { I18n.t("Allows user to access a user’s settings menu and user details.") } },
      { description: -> { I18n.t("Allows user to resend course invitations from the Course People page.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Courses (Account)") },
        description: -> { I18n.t("To access the account Courses page, Courses - view list must be enabled.") } },
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("To add or remove a student to or from a course, the Users - Student permission must be enabled.") } },
      { description: -> { I18n.t("To view the list of users in the course, Users - view list must be enabled.") } },
      { description: -> { I18n.t("To view SIS IDs, SIS Data - read must be enabled.") } },
      { description: -> { I18n.t("To edit a student’s section, Conversations - send to individual course members must also be enabled.") } }
    ],
    course_details: [
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("Allows user to view login ID information for students.") } },
      { description: -> { I18n.t("Allows user to view prior enrollments.") } },
      { description: -> { I18n.t("Allows user to access a user’s settings menu and user details.") } },
      { description: -> { I18n.t("Allows user to resend course invitations from the Course People page.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("To add or remove a student to or from a course, the Users - Students permissions must be enabled.") } },
      { description: -> { I18n.t("To view the list of users in the course, Users - view list must be enabled.") } },
      { description: -> { I18n.t("To view SIS IDs, SIS Data - read must be enabled.") } },
      { description: -> { I18n.t("To edit a student’s section, Conversations - send to individual course members must also be enabled.") } }
    ]
  },
  add_student_to_course: {
    label: -> { I18n.t("Students - add") },
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    group: :manage_course_student_enrollments,
  },
  remove_student_from_course: {
    label: -> { I18n.t("Students - remove") },
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    group: :manage_course_student_enrollments,
  },
  temporary_enrollments_add: {
    label: -> { I18n.t("Temporary Enrollments - add") },
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_only: true,
    account_allows: ->(a) { a.root_account.feature_enabled?(:temporary_enrollments) },
    group: :manage_temporary_enrollments,
  },
  temporary_enrollments_edit: {
    label: -> { I18n.t("Temporary Enrollments - edit") },
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_only: true,
    account_allows: ->(a) { a.root_account.feature_enabled?(:temporary_enrollments) },
    group: :manage_temporary_enrollments,
  },
  temporary_enrollments_delete: {
    label: -> { I18n.t("Temporary Enrollments - delete") },
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_only: true,
    account_allows: ->(a) { a.root_account.feature_enabled?(:temporary_enrollments) },
    group: :manage_temporary_enrollments,
  },
  manage_rubrics: {
    label: -> { I18n.t("Rubrics - add / edit / delete") },
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[DesignerEnrollment TaEnrollment TeacherEnrollment AccountAdmin],
    account_details: [
      { title: -> { I18n.t("Rubrics") },
        description: -> { I18n.t("Determines visibility and management of the Rubrics link in Account Navigation.") } },
      { description: -> { I18n.t("Allows user to create, edit, and delete rubrics.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Assignments") },
        description: -> { I18n.t("Users can access and create (but not edit) individual assignment rubrics through Assignments when Course Content - view and Assignments and Quizzes - add are enabled.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Rubrics") },
        description: -> { I18n.t("Determines visibility and management of Rubrics link in Account Navigation.") } },
      { description: -> { I18n.t("Allows user to view the Rubrics link in Course Navigation.") } },
      { description: -> { I18n.t("Allows user to create, edit, and delete course rubrics.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("Assignments") },
        description: -> { I18n.t("Users can access and create (but not edit) individual assignment rubrics through Assignments when Assignments and Quizzes - add is enabled.") } }
    ]
  },
  manage_wiki_create: {
    label: -> { I18n.t("Pages - create") },
    available_to: %w[TaEnrollment
                     TeacherEnrollment
                     DesignerEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[TaEnrollment TeacherEnrollment DesignerEnrollment AccountAdmin],
    group: :manage_wiki,
  },
  manage_wiki_update: {
    label: -> { I18n.t("Pages - update") },
    available_to: %w[TaEnrollment
                     TeacherEnrollment
                     DesignerEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[TaEnrollment TeacherEnrollment DesignerEnrollment AccountAdmin],
    group: :manage_wiki,
  },
  manage_wiki_delete: {
    label: -> { I18n.t("Pages - delete") },
    available_to: %w[TaEnrollment
                     TeacherEnrollment
                     DesignerEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[TaEnrollment TeacherEnrollment DesignerEnrollment AccountAdmin],
    group: :manage_wiki,
  },
  moderate_forum: {
    label: -> { I18n.t("Discussions - moderate") },
    available_to: %w[StudentEnrollment
                     TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    details: [
      { title: -> { I18n.t("Announcements") },
        description: -> { I18n.t("Allows user to view the New Announcement button in the Home page.") } },
      { description: -> { I18n.t("Allows user to add announcements in the Announcements page.") } },
      { title: -> { I18n.t("Blueprint Courses") },
        description: -> { I18n.t("Allows user to edit Blueprint lock settings on the Discussions index page in a Blueprint master course.") } },
      { title: -> { I18n.t("Discussions") },
        description: -> { I18n.t("Allows user to add discussions in the Discussions page.") } },
      { description: -> { I18n.t("Allows user to close for comments, move, pin/unpin, edit, and delete discussion topics in the Discussions page.") } },
      { description: -> { I18n.t("Allows user to edit discussion topics.") } },
      { description: -> { I18n.t("Allows user to view all replies within a discussion topic.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Announcements") },
        description: -> { I18n.t("To view announcements, Announcements - view must also be enabled.") } },
      { title: -> { I18n.t("Blueprint Courses") },
        description: -> { I18n.t("To edit lock settings on the Discussions index page, Courses - manage and Discussions - view must also be enabled.") } },
      { description: -> { I18n.t("If the additional permissions are enabled, but this permission is not enabled, lock settings can be edited on individual discussions.") } },
      { title: -> { I18n.t("Discussions") },
        description: -> { I18n.t("Both Discussions - create and Discussions - moderate allow the user to create a discussion in the Discussions page. If this permission is enabled, Discussions - create is not required.") } },
      { description: -> { I18n.t("To view discussions in a course, Discussions - view must be enabled.") } },
      { description: -> { I18n.t("To reply to a discussion, Discussions - post must be enabled.") } },
      { description: -> { I18n.t("To edit a discussion, Discussions - moderate must also be enabled.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("Announcements") },
        description: -> { I18n.t("To view announcements, Announcements - view must also be enabled.") } },
      { title: -> { I18n.t("Blueprint Courses") },
        description: -> { I18n.t("Blueprint courses must be enabled for an account by an admin.") } },
      { description: -> { I18n.t("Course roles can only manage content in Blueprint Courses if they are added to the Blueprint Course as a teacher, TA, or designer role.") } },
      { description: -> { I18n.t("If this setting is disabled, and Discussions - view is enabled, the user can still adjust content lock settings on individual discussions in a Blueprint master course.") } },
      { title: -> { I18n.t("Discussions") },
        description: -> { I18n.t("Both Discussions - create and Discussions - moderate allow the user to create a discussion in the Discussions page. If this permission is enabled, Discussions - create is not required.") } },
      { description: -> { I18n.t("To view discussions in a course, Discussions - view must be enabled.") } },
      { description: -> { I18n.t("To reply to a discussion, Discussions - post must be enabled.") } },
      { description: -> { I18n.t("To edit a discussion, Discussions - moderate must also be enabled.") } }
    ]
  },
  new_quizzes_view_ip_address: {
    label: -> { I18n.t("New Quizzes - view IP address") },
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_details: [
      { title: -> { I18n.t("New Quizzes") },
        description: -> { I18n.t("This permission allows users to view IP address information on the activity log.") } }
    ]
  },
  post_to_forum: {
    label: -> { I18n.t("Discussions - post") },
    available_to: %w[StudentEnrollment
                     TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[StudentEnrollment TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    restrict_future_enrollments: true,
    applies_to_concluded: %w[TeacherEnrollment TaEnrollment],
    details: [
      { title: -> { I18n.t("Discussions") },
        description: -> { I18n.t("Allows user to reply to a discussion post.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Discussions") },
        description: -> { I18n.t("To view discussions in a course, Discussions - view must also be enabled.") } },
      { description: -> { I18n.t("If the option requiring users to post before seeing replies is selected in a discussion, users must post a reply to view all posts unless Discussions - moderate is also enabled.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("Discussions") },
        description: -> { I18n.t("To view discussions in a course, Discussions - view must also be enabled.") } },
      { description: -> { I18n.t("To manage discussions, Discussions - moderate must also be enabled.") } }
    ]
  },
  proxy_assignment_submission: {
    label: -> { I18n.t("Submission - Submit on behalf of student") },
    available_to: %w[TaEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: [],
    account_allows: ->(_a) { Account.site_admin.feature_enabled?(:proxy_file_uploads) },
    details: [
      { title: -> { I18n.t("Submissions") },
        description: -> { I18n.t("Allows instructors to submit file attachments on behalf of a student.") } }
    ],
    considerations: [
      { title: -> { I18n.t("Submissions") },
        description: -> { I18n.t("Once enabled, this option is visible in gradebook for instructors.") } },
      { description: -> { I18n.t("Instructors are not bound by attempt limits, but an instructor's submission WILL count as a student's attempt.") } }
    ]
  },
  read_announcements: {
    label: -> { I18n.t("Announcements - view") },
    available_to: %w[StudentEnrollment
                     TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[StudentEnrollment TaEnrollment DesignerEnrollment ObserverEnrollment TeacherEnrollment AccountAdmin],
    applies_to_concluded: true,
    account_details: [
      { title: -> { I18n.t("Announcements") },
        description: -> { I18n.t("Allows user to view the Announcements link in Course Navigation.") } },
      { title: -> { I18n.t("Announcements") },
        description: -> { I18n.t("Allows user to view course announcements.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Announcements") },
        description: -> { I18n.t("To view recent announcements on the home page, Course content - view must be enabled, and the Show recent announcements on Course home page checkbox must be selected in Course Settings.") } },
      { description: -> { I18n.t("To manage course announcements, Discussions - moderate ​must also be enabled.") } },
      { title: -> { I18n.t("Global Announcements") },
        description: -> { I18n.t("This permission only affects course announcements; to manage global announcements, Global Announcements - add / edit / delete​ must be enabled.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Announcements") },
        description: -> { I18n.t("Allows user to access the Announcements link in Course Navigation.") } },
      { description: -> { I18n.t("Allows user to view course announcements.") } },
      { description: -> { I18n.t("Allows user to view recent announcements on the Course Home Page.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("Announcements") },
        description: -> { I18n.t("To add announcements, Discussions - moderate must also be enabled.") } },
      { description: -> { I18n.t("To view recent announcements on the home page, the Show recent announcements on Course home page checkbox must be selected in Course Settings.") } }
    ]
  },
  read_email_addresses: {
    label: -> { I18n.t("Users - view primary email address") },
    available_to: %w[StudentEnrollment
                     TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[TaEnrollment TeacherEnrollment AccountAdmin],
    applies_to_concluded: %w[TeacherEnrollment TaEnrollment],
    account_details: [
      { title: -> { I18n.t("People (Account)") },
        description: -> { I18n.t("Allows user to search for account users via primary email address in the account People page.") } },
      { description: -> { I18n.t("Allows user to search for other users via primary email address in a course People page.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("People (Account)") },
        description: -> { I18n.t("To view the account People page, Users - view list must be enabled.") } },
      { description: -> { I18n.t("If this permission is disabled, and Users - view login IDs is enabled, users will still see email addresses used as login IDs.") } }
    ],
    course_details: [
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("Allows user to search for other users via primary email addresses in the People page.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("To access the People page, Users - view list must be enabled.") } },
      { description: -> { I18n.t("If this permission is disabled, and Users - view login IDs is enabled, users will still see email addresses used as login IDs.") } }
    ]
  },
  read_forum: {
    label: -> { I18n.t("Discussions - view") },
    available_to: %w[StudentEnrollment
                     TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[StudentEnrollment TaEnrollment DesignerEnrollment ObserverEnrollment TeacherEnrollment AccountAdmin],
    applies_to_concluded: true,
    account_details: [
      { title: -> { I18n.t("Blueprint Courses") },
        description: -> { I18n.t("Allows user to edit Blueprint content lock settings on individual discussions.") } },
      { title: -> { I18n.t("Discussions") },
        description: -> { I18n.t("Allows user to view the Discussions link in Course Navigation.") } },
      { description: -> { I18n.t("Allows user to view course discussions and all replies within the discussion topics.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Blueprint Courses") },
        description: -> { I18n.t("To edit lock settings from the Discussions index page, Blueprint Courses - add / edit / associate / delete and Courses - manage must also be enabled.") } },
      { title: -> { I18n.t("Commons") },
        description: -> { I18n.t("To share a discussion to Commons, Courses - manage must also be enabled.") } },
      { title: -> { I18n.t("Discussions") },
        description: -> { I18n.t("To manage discussions, Discussions - moderate must also be enabled.") } },
      { description: -> { I18n.t("To reply to a discussion, Discussions - post must also be enabled.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Blueprint Courses") },
        description: -> { I18n.t("Allows user to edit Blueprint content lock settings on individual settings if the user is enrolled in a Blueprint master course.") } },
      { title: -> { I18n.t("Discussions") },
        description: -> { I18n.t("Allows user to view the Discussions link in Course Navigation.") } },
      { description: -> { I18n.t("Allows user to view course discussions and all replies within the discussion topics.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("Blueprint Courses") },
        description: -> { I18n.t("Blueprint Courses must be enabled for an account by an admin.") } },
      { description: -> { I18n.t("Course roles can only manage content in Blueprint Courses if they are added to the Blueprint Course with a teacher, TA, or designer role.") } },
      { description: -> { I18n.t("To edit Blueprint lock settings from the Discussions index page, Discussions - moderate must also be enabled.") } },
      { title: -> { I18n.t("Commons") },
        description: -> { I18n.t("To share a discussion to Commons, Course Content - add / edit / delete must also be enabled.") } },
      { title: -> { I18n.t("Discussions") },
        description: -> { I18n.t("To manage discussions, Discussions - moderate must also be enabled.") } },
      { description: -> { I18n.t("To reply to a discussion, Discussions - post must also be enabled.") } }
    ]
  },
  read_question_banks: {
    label: -> { I18n.t("Question banks - view and link") },
    available_to: %w[TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    applies_to_concluded: true,
    account_details: [
      { title: -> { I18n.t("Question Banks") },
        description: -> { I18n.t("Allows user to view and link questions in a quiz to account-level question banks.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Quizzes and Question Banks") },
        description: -> { I18n.t("To access the Manage Question Banks link in a course Quizzes Index Page, Course content - view and Assignments and Quizzes - manage / edit must also be enabled.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Question Banks") },
        description: -> { I18n.t("Allows user to view and link questions in a quiz to course-level question banks.") } },
      { description: -> { I18n.t("Allows user to access the Manage Question Banks link on the Quizzes Index Page.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("Question Banks (Courses)") },
        description: -> { I18n.t("To fully manage course-level question banks, Assignments and Quizzes - manage / edit permission must also be enabled.") } }
    ]
  },
  read_reports: {
    label: -> { I18n.t("Reports - manage") }, # Reports - manage is used by both Account and Course Roles in Permissions
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    account_details: [
      { title: -> { I18n.t("Reports") },
        description: -> { I18n.t("Allows user to view and configure reports in Account Settings.") } },
      { description: -> { I18n.t("Allows user to view Access Reports.") } },
      { description: -> { I18n.t("Allows user to view last activity and total activity information on the People page.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("To view Last Activity and Total Activity information on the Course People page, Users - view list must also be enabled.") } },
      { description: -> { I18n.t("To access a Course People page, Users - view list must also be enabled.") } },
      { title: -> { I18n.t("Reports (Course)") },
        description: -> { I18n.t("To access the Student Interactions report, Grades - view all grades must also be enabled.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Course Settings") },
        description: -> { I18n.t("Allows user to view the Course Statistics button in Course Settings.") } },
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("Allows user to view Last Activity and Total Activity information on the People page.") } },
      { title: -> { I18n.t("Reports") },
        description: -> { I18n.t("Allows user to view Last Activity and Total Activity reports.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("To access the People Page, Users - view list must be enabled.") } },
      { title: -> { I18n.t("Reports") },
        description: -> { I18n.t("To access the Student Interactions report, Grades - view all grades must also be enabled.") } }
    ]
  },
  read_roster: {
    label: -> { I18n.t("Users - view list") },
    available_to: %w[StudentEnrollment
                     TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[StudentEnrollment TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    applies_to_concluded: %w[TeacherEnrollment TaEnrollment DesignerEnrollment],
    account_details: [
      { title: -> { I18n.t("Account Navigation") },
        description: -> { I18n.t("Allows user to access the People link in Account Navigation.") } },
      { title: -> { I18n.t("Admin Tools (Logging tab)") },
        description: -> { I18n.t("Allows user to view login/logout activity of users in Admin Tools.") } },
      { description: -> { I18n.t("Allows user to search grade change logs by grader or student in Admin Tools.") } },
      { title: -> { I18n.t("Assignments") },
        description: -> { I18n.t("Allows user to differentiate assignments to individual students.") } },
      { title: -> { I18n.t("Collaborations") },
        description: -> { I18n.t("Allows user to view and add users in a collaboration.") } },
      { title: -> { I18n.t("Conversations") },
        description: -> { I18n.t("Allows user to send a message in Conversations without selecting a course.") } },
      { title: -> { I18n.t("Course Navigation") },
        description: -> { I18n.t("Allows user to view the People link in Course Navigation.") } },
      { title: -> { I18n.t("Groups (Course)") },
        description: -> { I18n.t("Allows user to view groups in a course.") } },
      { title: -> { I18n.t("People (Account)") },
        description: -> { I18n.t("Allows user to view list of users in the account.") } },
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("Allows user to view list of users in the course People page.") } },
      { description: -> { I18n.t("Allows user to view the Prior Enrollments button in the course People page.") } },
      { title: -> { I18n.t("Subaccounts") },
        description: -> { I18n.t("Not available at the subaccount level.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Account Groups") },
        description: -> { I18n.t("To view account-level groups, Groups - manage must also be enabled.") } },
      { title: -> { I18n.t("Admin Tools (Logging tab)") },
        description: -> { I18n.t("To generate login/logout activity in Admin Tools, Users - manage login details or Statistics - view must also be enabled.") } },
      { description: -> { I18n.t("To generate grade change logs in Admin Tools, Grades - view change logs must also be enabled.") } },
      { title: -> { I18n.t("Courses") },
        description: -> { I18n.t("To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).") } },
      { title: -> { I18n.t("Groups") },
        description: -> { I18n.t("To add groups, Groups - add must also be enabled.") } },
      { description: -> { I18n.t("To delete groups, Groups - delete must also be enabled.") } },
      { description: -> { I18n.t("To edit groups, Groups - manage must also be enabled.") } },
      { title: -> { I18n.t("People (Account)") },
        description: -> { I18n.t("To edit user details, modify login details, or change user passwords, Users - manage login details must also be enabled.") } },
      { description: -> { I18n.t("To view user page views, Statistics - view must also be enabled.") } },
      { description: -> { I18n.t("To act as other users, Users - act as must also be enabled.") } },
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("To edit a user’s section, the appropriate Users permission (e.g. Users - Teachers), Users - allow administrative actions in courses, and Conversations - send to individual course members must also be enabled.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Assignments") },
        description: -> { I18n.t("Allows user to differentiate assignments to individual students.") } },
      { title: -> { I18n.t("Collaborations") },
        description: -> { I18n.t("Allows user to view and add users in a collaboration.") } },
      { title: -> { I18n.t("Course") },
        description: -> { I18n.t("Navigation Allows user to view the People link in Course Navigation.") } },
      { title: -> { I18n.t("Groups") },
        description: -> { I18n.t("Allows user to view groups in a course.") } },
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("Allows user to view list of users in the course People page.") } },
      { description: -> { I18n.t("Allows user to view the Prior Enrollments button in the course People page.") } },
      { title: -> { I18n.t("Settings") },
        description: -> { I18n.t("Allows user to view enrollments on the Sections tab.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("Conversations") },
        description: -> { I18n.t("To send a message to an individual user, Conversations - send messages to individual course members must also be enabled.") } },
      { title: -> { I18n.t("Groups") },
        description: -> { I18n.t("To add groups, Groups - add must also be enabled.") } },
      { description: -> { I18n.t("To delete groups, Groups - delete must also be enabled.") } },
      { description: -> { I18n.t("To edit groups, Groups - manage must also be enabled.") } },
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).") } },
      { description: -> { I18n.t("To edit a user’s section, Users - allow administrative actions in courses and Users - view list must also be enabled.") } }
    ]
  },
  read_sis: {
    label: -> { I18n.t("SIS Data - read") },
    true_for: %w[AccountAdmin TeacherEnrollment],
    available_to: %w[AccountAdmin AccountMembership TeacherEnrollment TaEnrollment StudentEnrollment],
    applies_to_concluded: %w[TeacherEnrollment TaEnrollment],
    account_details: [
      { title: -> { I18n.t("Course Settings") },
        description: -> { I18n.t("Allows user to view a course’s SIS ID.") } },
      { title: -> { I18n.t("People (Account)") },
        description: -> { I18n.t("Allows user to view the SIS ID in a user’s login details.") } },
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("Allows user to view user SIS IDs in a course People page.") } },
      { title: -> { I18n.t("Quizzes") },
        description: -> { I18n.t("Allows user to view the user SIS ID column in the Quiz Item Analysis CSV file.") } },
      { title: -> { I18n.t("SIS") },
        description: -> { I18n.t("Governs account-related SIS IDs (i.e., subaccount SIS ID).") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Account and Subaccount") },
        description: -> { I18n.t("Users and terms are located at the account, so the SIS endpoint always confirms the user’s permissions according to account.") } },
      { description: -> { I18n.t("Subaccounts only have ownership of courses and sections; they do not own user data. Subaccount admins are not able to view SIS information unless they are also granted an instructor role in a course.") } },
      { description: -> { I18n.t("Subaccount admins are not able to view SIS information unless they are also granted an instructor role in a course.") } },
      { description: -> { I18n.t("Subaccount admins cannot view SIS information without the course association, as the instructor role has permission to read SIS data at the account level.") } },
      { title: -> { I18n.t("People (Account)") },
        description: -> { I18n.t("To view a user’s login details, Users - view list and Modify login details for users must also both be enabled.") } },
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).") } },
      { title: -> { I18n.t("SIS Import") },
        description: -> { I18n.t("To manage SIS data, SIS Data - manage must be enabled.") } },
      { description: -> { I18n.t("If SIS Data - manage is enabled and SIS Data - read is disabled, the account permission overrides the course permission.") } },
      { description: -> { I18n.t("If SIS Data - manage is disabled and SIS Data - read is enabled, users can only view course, user, and subaccount SIS IDs.") } },
      { description: -> { I18n.t("To disallow users from viewing any SIS IDs at the course level, SIS Data - manage and SIS Data - read must both be disabled.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Course Settings") },
        description: -> { I18n.t("Allows user to view course SIS ID.") } },
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("Allows user to view user SIS IDs.") } },
      { title: -> { I18n.t("Quizzes") },
        description: -> { I18n.t("Allows user to view the user SIS ID column in the Quiz Item Analysis CSV file.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("To view the list of users in the course, Users - view list must also be enabled.") } },
      { description: -> { I18n.t("To add or remove users to a course via SIS, the appropriate Users permission must be enabled (e.g. Users - Teachers).") } }
    ]
  },
  select_final_grade: {
    label: -> { I18n.t("Grades - select final grade for moderation") },
    true_for: %w[AccountAdmin TeacherEnrollment TaEnrollment],
    available_to: %w[AccountAdmin AccountMembership TeacherEnrollment TaEnrollment],
    details: [
      { title: -> { I18n.t("Grades") },
        description: -> { I18n.t("Allows user to select final grade for moderated assignments.") } }
    ],
    considerations: [
      { title: -> { I18n.t("Assignments") },
        description: -> { I18n.t("To add students to a moderation set, Grades - view all grades must also be enabled.") } },
      { title: -> { I18n.t("Grades") },
        description: -> { I18n.t("To publish final grades for a moderated assignment, Grades - edit must also be enabled.") } },
      { description: -> { I18n.t("To post or hide grades for a moderated assignment, Grades - edit must also be enabled.") } },
      { title: -> { I18n.t("SpeedGrader") },
        description: -> { I18n.t("To review a moderated assignment in SpeedGrader, Grades - edit must also be enabled.") } }
    ]
  },
  send_messages: {
    label: -> { I18n.t("Conversations - send messages to individual course members") },
    available_to: %w[StudentEnrollment
                     TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[StudentEnrollment TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    details: [
      { title: -> { I18n.t("Conversations") },
        description: -> { I18n.t("Allows user to send messages to individual course members.") } }
    ],
    considerations: [
      { title: -> { I18n.t("Conversations") },
        description: -> { I18n.t("When disabled, students can still send individual messages to course teachers, course TAs, and students that belong to the same account-level groups.") } },
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("To edit a user’s section, Users - allow administrative actions in courses and Users - view list must also be enabled.") } }
    ]
  },
  send_messages_all: {
    label: -> { I18n.t("Conversations - send messages to entire class") },
    available_to: %w[StudentEnrollment
                     TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    details: [
      { title: -> { I18n.t("Conversations") },
        description: -> { I18n.t("Allows user to send a message to “All in [course name]” or \"All in [course group]\".") } }
    ]
  },
  view_audit_trail: {
    label: -> { I18n.t("Grades - view audit trail") },
    true_for: %w[AccountAdmin],
    available_to: %w[TeacherEnrollment AccountAdmin AccountMembership],
    details: [
      { title: -> { I18n.t("Grades") },
        description: -> { I18n.t("Allows user to review an audit trail in assignments, both moderated and anonymous.") } }
    ],
    considerations: [
      { title: -> { I18n.t("Grades") },
        description: -> { I18n.t("To moderate grades, Grades - Select final grade for moderation must also be enabled.") } },
      { description: -> { I18n.t("To post or hide grades for an assignment, Grades - edit must also be enabled.") } }
    ]
  },
  view_all_grades: {
    label: -> { I18n.t("Grades - view all grades") },
    available_to: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[TaEnrollment TeacherEnrollment AccountAdmin],
    applies_to_concluded: true,
    account_details: [
      { title: -> { I18n.t("Admin Tools (Logging tab)") },
        description: -> { I18n.t("Allows user to search by assignment ID in grade change logs.") } },
      { title: -> { I18n.t("Analytics") },
        description: -> { I18n.t("Allows user to view student-specific data in Analytics.") } },
      { title: -> { I18n.t("Assignments, SpeedGrader") },
        description: -> { I18n.t("Allows user to view a link to SpeedGrader from assignments.") } },
      { title: -> { I18n.t("Gradebook") },
        description: -> { I18n.t("Allows user to export the Gradebook to a comma separated values (CSV) file.") } },
      { description: -> { I18n.t("Allows user to access the Learning Mastery Gradebook (if enabled).") } },
      { title: -> { I18n.t("Grades") },
        description: -> { I18n.t("Allows user to view student Grades pages.") } },
      { title: -> { I18n.t("Modules") },
        description: -> { I18n.t("Allows user to access the Student Progress page.") } },
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("Allows user to view analytics link in the user settings menu.") } },
      { title: -> { I18n.t("Quizzes") },
        description: -> { I18n.t("Allows user to view student results, view quiz statistics, and access a quiz in SpeedGrader.") } },
      { title: -> { I18n.t("Rubrics, SpeedGrader") },
        description: -> { I18n.t("Allows user to view grader comments on a rubric in SpeedGrader.") } },
      { title: -> { I18n.t("Student Context Card") },
        description: -> { I18n.t("Adds analytics to a student’s context card.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Admin Tools (Grade Change Logs)") },
        description: -> { I18n.t("To search grade change logs, Grades - view change logs must also be enabled.") } },
      { title: -> { I18n.t("Analytics") },
        description: -> { I18n.t("To view student analytics, Analytics - view must also be enabled.") } },
      { title: -> { I18n.t("Gradebook") },
        description: -> { I18n.t("To view the Gradebook, Course Content - view must also be enabled.") } },
      { description: -> { I18n.t("If both Grades - edit and Grades - view all grades are disabled, Gradebook will be hidden from Course Navigation.") } },
      { title: -> { I18n.t("Grades") },
        description: -> { I18n.t("To post or hide grades, Grades - edit must also be enabled.") } },
      { title: -> { I18n.t("Modules") },
        description: -> { I18n.t("To view module progression, Grades - view all grades must also be enabled.") } },
      { title: -> { I18n.t("Reports") },
        description: -> { I18n.t("To access the Student Interactions report, Reports - manage must also be enabled.") } },
      { title: -> { I18n.t("Student Context Card") },
        description: -> { I18n.t("Student Context Cards must be enabled for an account by an admin.") } },
      { title: -> { I18n.t("Subaccounts") },
        description: -> { I18n.t("Not available at the subaccount level.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Analytics") },
        description: -> { I18n.t("Allows user to view student-specific data in Analytics.") } },
      { title: -> { I18n.t("Assignments, SpeedGrader") },
        description: -> { I18n.t("Allows user to access SpeedGrader from an assignment.") } },
      { title: -> { I18n.t("Gradebook") },
        description: -> { I18n.t("Allows user to view Gradebook.") } },
      { description: -> { I18n.t("Allows user to export the Gradebook to a comma separated values (CSV) file.") } },
      { description: -> { I18n.t("Allows user to access the Learning Mastery Gradebook (if enabled).") } },
      { title: -> { I18n.t("Grades") },
        description: -> { I18n.t("Allows user to view student Grades pages.") } },
      { title: -> { I18n.t("Modules") },
        description: -> { I18n.t("Allows user to access the Student Progress page.") } },
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("Adds analytics link on the user settings menu.") } },
      { title: -> { I18n.t("Quizzes") },
        description: -> { I18n.t("Allows user to view student results, view quiz statistics, and access a quiz in SpeedGrader.") } },
      { title: -> { I18n.t("Rubrics, SpeedGrader") },
        description: -> { I18n.t("Allows user to view grader comments on a rubric in SpeedGrader.") } },
      { title: -> { I18n.t("Student Context Card") },
        description: -> { I18n.t("Adds analytics to a student’s context card.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("Analytics") },
        description: -> { I18n.t("To view student analytics, Analytics - view must also be enabled.") } },
      { title: -> { I18n.t("Gradebook") },
        description: -> { I18n.t("If both Grades - edit and Grades - view all grades are disabled, Gradebook will be hidden from Course Navigation.") } },
      { title: -> { I18n.t("Grades") },
        description: -> { I18n.t("To post or hide grades, Grades - edit must also be enabled.") } },
      { title: -> { I18n.t("Modules") },
        description: -> { I18n.t("To view module progression, Grades - view all grades must also be enabled.") } },
      { title: -> { I18n.t("Reports") },
        description: -> { I18n.t("To access the Student Interactions report, Reports - manage must also be enabled.") } },
      { title: -> { I18n.t("Student Context Card") },
        description: -> { I18n.t("Student Context Cards must be enabled for an account by an admin.") } }
    ]
  },
  view_group_pages: {
    label: -> { I18n.t("Groups - view all student groups") },
    available_to: %w[StudentEnrollment
                     TaEnrollment
                     DesignerEnrollment
                     TeacherEnrollment
                     ObserverEnrollment
                     AccountAdmin
                     AccountMembership],
    true_for: %w[TaEnrollment DesignerEnrollment TeacherEnrollment AccountAdmin],
    applies_to_concluded: true,
    details: [
      { title: -> { I18n.t("Groups") },
        description: -> { I18n.t("Allows user to view the group home pages of all student groups.") } },
      { description: -> { I18n.t("Allows students to access other student groups within a group set with a direct link.") } }
    ],
    considerations: [
      { title: -> { I18n.t("Groups") },
        description: -> { I18n.t("By default students are able to create groups; to restrict students from creating groups, do not select the Let students organize their own groups checkbox in Course Settings.") } }
    ]
  },
  view_quiz_answer_audits: {
    label: -> { I18n.t("Quizzes - view submission log") },
    true_for: %w[AccountAdmin],
    available_to: %w[AccountAdmin AccountMembership],
    account_allows: ->(a) { a.feature_allowed?(:quiz_log_auditing) },
    account_details: [
      { title: -> { I18n.t("Quizzes") },
        description: -> { I18n.t("Allows user to view student quiz logs.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Grades") },
        description: -> { I18n.t("Grades - edit must also be enabled.") } },
      { title: -> { I18n.t("Quizzes") },
        description: -> { I18n.t("The Quiz Log Auditing feature option must be enabled in Course Settings.") } }
    ]
  },
  view_user_logins: {
    label: -> { I18n.t("Users - view login IDs") },
    available_to: %w[AccountAdmin AccountMembership TeacherEnrollment TaEnrollment],
    true_for: %w[AccountAdmin TeacherEnrollment TaEnrollment],
    applies_to_concluded: %w[TeacherEnrollment TaEnrollment],
    details: [
      { title: -> { I18n.t("People (Account, Course)") },
        description: -> { I18n.t("Allows user to search for other users by Login ID in the account People page.") } }
    ],
    considerations: [
      { title: -> { I18n.t("People (Account, Course)") },
        description: -> { I18n.t("To access the People page, Users - view list must be enabled.") } },
      { description: -> { I18n.t("If this permission is enabled, and if Users - view primary email address is disabled, users will see email addresses used as login IDs.") } },
      { description: -> { I18n.t("To view login IDs, Users - allow administrative actions in courses must also be enabled.") } }
    ]
  },
  view_admin_analytics: {
    label: -> { I18n.t("Admin Analytics - view and export data") },
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_only: true,
    account_allows: ->(a) { a.feature_enabled?(:admin_analytics_view_permission) },
    account_details: [
      { title: -> { I18n.t("Admin Analytics") },
        description: -> { I18n.t("Allows user to view, drill into, and export Admin Analytics data in the Overview, Course, and Student tabs.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Account Settings") },
        description: -> { I18n.t("The Admin Analytics feature must be enabled in Account Settings to view Admin Analytics dashboards.") } }
    ]
  },
  view_analytics_hub: {
    label: -> { I18n.t("Analytics Hub") },
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_only: true,
    account_allows: ->(a) { a.feature_enabled?(:analytics_hub) },
    account_details: [
      { title: -> { I18n.t("Analytics Hub") },
        description: -> { I18n.t("Allows user to open Analytics Hub, the central library of all things Data, Analytics and Insights.") } }
    ]
  },
  view_ask_questions_analytics: {
    label: -> { I18n.t("Ask Your Data") },
    group: :view_advanced_analytics,
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_only: true,
    account_allows: ->(a) { a.feature_enabled?(:advanced_analytics_ask_questions) },
    account_details: [
      { title: -> { I18n.t("Account Settings") },
        description: -> { I18n.t("Allows users to access the Ask Your Data feature of Intelligent Insights.") } },
      { title: -> { I18n.t("Subaccounts") },
        description: -> { I18n.t("Provides a scoped access to the Ask Your Data feature.") } }
    ]
  },
  manage_ask_questions_analytics_context: {
    label: -> { I18n.t("Ask Your Data - Context Library") },
    group: :view_advanced_analytics,
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_only: true,
    account_allows: ->(a) { a.feature_enabled?(:advanced_analytics_ask_questions) },
    account_details: [
      { title: -> { I18n.t("Account Settings") },
        description: -> { I18n.t("Allows Ask Your Data users to access and manage the product's Context Library feature, to influence and tailor AI responses for all users.") } },
      { title: -> { I18n.t("Subaccounts") },
        description: -> { I18n.t("Not available at the subaccount level.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Account Settings") },
        description: -> { I18n.t("Requires Ask Your Data permission to use.") } }
    ]
  },
  view_students_in_need: {
    label: -> { I18n.t("Students in Need of Attention") },
    group: :view_advanced_analytics,
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_only: true,
    account_allows: ->(a) { a.feature_enabled?(:k20_students_in_need_of_attention) },
    account_details: [
      { title: -> { I18n.t("Students in Need of Attention") },
        description: -> { I18n.t("Allows an account administrator to access the Students in Need of Attention feature of Intelligent Insights.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Intelligent Insights") },
        description: -> { I18n.t("Students in Need of Attention is part of the Intelligent Insights upgrade in Canvas.") } }
    ]
  },
  view_students_in_need_in_course: {
    label: -> { I18n.t("Intelligent Insights - Students in Need of Attention - Course Level") },
    available_to: %w[AccountAdmin AccountMembership TeacherEnrollment TaEnrollment],
    true_for: %w[AccountAdmin TeacherEnrollment],
    account_allows: ->(a) { a.feature_enabled?(:k20_students_in_need_of_attention) }
  },
  view_course_readiness: {
    label: -> { I18n.t("Course Readiness") },
    group: :view_advanced_analytics,
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_only: true,
    account_allows: ->(a) { a.feature_enabled?(:k20_course_readiness) },
    account_details: [
      { title: -> { I18n.t("Course Readiness") },
        description: -> { I18n.t("Allows an account administrator to access the Course Readiness feature of Intelligent Insights.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Intelligent Insights") },
        description: -> { I18n.t("Course Readiness is part of the Intelligent Insights upgrade in Canvas.") } }
    ]
  },
  view_title_iv_financial_aid_report: {
    label: -> { I18n.t("Financial Aid Compliance") },
    group: :view_advanced_analytics,
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_only: true,
    account_allows: ->(a) { a.feature_enabled?(:title_iv_financial_aid_report) }
  },
  view_rsi_report: {
    label: -> { I18n.t("Regular and Substantive Interaction") },
    group: :view_advanced_analytics,
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_only: true,
    account_allows: ->(a) { a.feature_enabled?(:intelligent_insights_rsi_report) }
  },
  access_ignite_agent: {
    label: -> { I18n.t("Ignite Agent - access") },
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_only: true,
    account_allows: ->(a) { a.feature_enabled?(:ignite_agent_enabled) },
    account_details: [
      { title: -> { I18n.t("Ignite Agent") },
        description: -> { I18n.t("Allows user to access the Ignite Agent AI companion for Canvas LMS.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Ignite Agent") },
        description: -> { I18n.t("The Ignite Agent feature must be enabled for the account to assign this permission.") } }
    ]
  },
  manage_impact: {
    label: -> { I18n.t("Impact - Manage") },
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_only: :root,
    account_details: [
      { title: -> { I18n.t("Impact - Manage") },
        description: -> { I18n.t("Allows an account administrator to manage the Impact service integration.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Impact") },
        description: -> { I18n.t("Impact is an add-on to Canvas LMS. Contact your CSM if interested.") } }
    ]
  },
  block_editor_template_editor: {
    label: -> { I18n.t("Block Editor Templates - edit") },
    available_to: %w[TeacherEnrollment DesignerEnrollment AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_allows: ->(a) { a.feature_enabled?(:block_editor) && a.feature_enabled?(:block_template_editor) },
    course_details: [
      { title: -> { I18n.t("Block Editor Templates - edit") },
        description: -> { I18n.t("Allows user to create and edit templates from within the Block Editor.") } }
    ]
  },
  block_editor_global_template_editor: {
    label: -> { I18n.t("Block Editor Global Templates - edit") },
    available_to: %w[TeacherEnrollment DesignerEnrollment AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_allows: ->(a) { a.feature_enabled?(:block_editor) && a.feature_enabled?(:block_template_editor) },
    course_details: [
      { title: -> { I18n.t("Block Editor Templates - global edit") },
        description: -> { I18n.t("Allows user to create and edit global templates from within the Block Editor.") } }
    ]
  },
  new_quizzes_multiple_session_detection: {
    label: -> { I18n.t("New Quizzes - view multi session information") },
    available_to: %w[TeacherEnrollment AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    details: [
      { title: -> { I18n.t("New Quizzes") },
        description: -> { I18n.t("This permission allows users to view multi-session activity information on the activity log and the moderate page.") } }
    ],
    considerations: [
      { title: -> { I18n.t("Quiz settings") },
        description: -> { I18n.t("Educators can enable the Detect Multiple Sessions setting on their quizzes to collect multi-session information on student submissions. This permission determines who can view this data in the activity log and moderate page.") } }
    ]
  },
  manage_users_in_bulk: {
    label: -> { I18n.t("Bulk actions - people page") },
    available_to: %w[AccountAdmin AccountMembership],
    true_for: %w[AccountAdmin],
    account_allows: ->(a) { a.root_account.feature_enabled?(:horizon_bulk_api_permission) },
    account_details: [
      { title: -> { I18n.t("Bulk actions - People page") },
        description: -> { I18n.t("Allows the user to perform bulk actions (enroll, delete, or suspend) on users listed on the People page.") } }
    ]
  }
}.freeze

Rails.application.config.to_prepare do
  Permissions.register(BASE_PERMISSIONS)
end

Rails.application.config.after_initialize do
  Permissions.retrieve.freeze
end
