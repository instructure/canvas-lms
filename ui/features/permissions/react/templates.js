/*
 * Copyright (C) 2018 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import I18n from 'i18n!permissions_v2_add_tray'

export function deepMergeAll(array) {
  return array.reduce((acc, item) => deepMerge(acc, item))
}

export function deepMerge(a, b) {
  for (const key in b) {
    try {
      if (b[key].constructor === Object) {
        a[key] = deepMerge(a[key], b[key])
      } else {
        a[key] = b[key]
      }
    } catch (e) {
      a[key] = b[key]
    }
  }
  return a
}

export const PERMISSION_DETAIL_SECTIONS = [
  {title: () => I18n.t('WHAT IT DOES'), key: 'what_it_does'},
  {title: () => I18n.t('ADDITIONAL CONSIDERATIONS'), key: 'additional_considerations'}
]

export const GROUP_PERMISSION_DESCRIPTIONS = {
  manage_courses: () => I18n.t('add / conclude / delete / publish'),
  manage_files: () => I18n.t('add / delete / edit'),
  manage_sections: () => I18n.t('add / delete / edit'),
  manage_wiki: () => I18n.t('create / delete / update'),
  manage_course_student_enrollments: () => I18n.t('add / remove in courses'),
  manage_course_teacher_enrollments: () => I18n.t('add / remove in courses'),
  manage_course_ta_enrollments: () => I18n.t('add / remove in courses'),
  manage_course_observer_enrollments: () => I18n.t('add / remove in courses'),
  manage_course_designer_enrollments: () => I18n.t('add / remove in courses'),
  manage_course_templates: () => I18n.t('create / delete / edit')
}

export const generateActionTemplates = (
  permissionsLabel,
  accountDetails,
  accountConsiderations,
  courseDetails,
  courseConsiderations
) => ({
  ACCOUNT: {
    [PERMISSION_DETAIL_SECTIONS[0].key]: {[permissionsLabel]: accountDetails},
    [PERMISSION_DETAIL_SECTIONS[1].key]: {[permissionsLabel]: accountConsiderations}
  },
  COURSE: {
    [PERMISSION_DETAIL_SECTIONS[0].key]: {[permissionsLabel]: courseDetails},
    [PERMISSION_DETAIL_SECTIONS[1].key]: {[permissionsLabel]: courseConsiderations}
  }
})

const usersActAsPermissions = generateActionTemplates(
  'become_user',
  [
    {
      title: I18n.t('People (Account)'),
      description: I18n.t('Allows user to act as other users in the account.')
    },
    {
      description: I18n.t(
        'This permission should only be assigned to users that your institution has authorized to act as other users in your entire Canvas account.'
      )
    },
    {
      description: I18n.t(
        'Users with this permission may be able to use the Act as feature to manage account settings, view and adjust grades, access user information, etc. This permissions also allows admins designated to a sub-account to access settings and information outside of their sub-account.'
      )
    },
    {
      title: I18n.t('Student Context Card'),
      description: I18n.t('Allows user to access the Act as User link on student context cards.')
    },
    {
      title: I18n.t('SpeedGrader'),
      description: I18n.t('Allows user to delete a submission file.')
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t('Allows user to view Login IDs in a course People page.')
    }
  ],
  [
    {
      title: I18n.t('API'),
      description: I18n.t('The Roles API refers to this permission as become_user.')
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        'To view the list of users in an account, Users - view list must be enabled.'
      )
    },
    {
      title: I18n.t('Student Context Card'),
      description: I18n.t('Student Context Cards must be enabled for an account by an admin.')
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t('Not available at the subaccount level.')
    }
  ],
  [],
  []
)

const sisDataImportPermissions = generateActionTemplates(
  'import_sis',
  [
    {
      title: I18n.t('Account Navigation'),
      description: I18n.t(
        'Determines visibility and management of SIS Import link in Account Navigation.'
      )
    },
    {
      title: I18n.t('SIS Import'),
      description: I18n.t('Allows user to import SIS data.')
    }
  ],
  [
    {
      title: I18n.t('SIS Import'),
      description: I18n.t('To manage SIS data, SIS Data - manage must also be enabled.')
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t('Not available at the subaccount level')
    }
  ],
  [],
  []
)

const adminsLevelPermissions = generateActionTemplates(
  'manage_account_memberships',
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t('Allows user to add and remove other account admins.')
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t('Allows user to access and edit the Admin settings in Commons.')
    },
    {
      description: I18n.t(
        'Allows user to create and manage Groups. Allows user to manage shared resources in the account.'
      )
    },
    {
      description: I18n.t('Allows user to manage shared resources in the account.')
    }
  ],
  [],
  [],
  []
)

const accountLevelPermissions = generateActionTemplates(
  'manage_account_settings',
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(
        'Allows user to view and manage the Settings and Notifications tabs in Account Settings.'
      )
    },
    {
      title: I18n.t('Authentication'),
      description: I18n.t(
        'Allows user to view and manage authentication options for the whole account.'
      )
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t('Allows user to view and manage subaccounts for the account.')
    },
    {
      title: I18n.t('Terms'),
      description: I18n.t('Allows user to view and manage terms for the account.')
    },
    {
      title: I18n.t('Theme Editor'),
      description: I18n.t('Allows user to access the Theme Editor.')
    }
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t(
        'The Announcements tab is always visible to admins; however, to manage announcements, Global Announcements - add / edit / delete must also be enabled.'
      )
    },
    {
      title: I18n.t('Feature Options (Account Settings)'),
      description: I18n.t(
        'To manage the Feature Options tab, Feature Options - enable disable - must also be enabled.'
      )
    },
    {
      title: I18n.t('Reports (Account Settings)'),
      description: I18n.t(
        'To view the Reports tab, Courses - view usage reports must also be enabled.'
      )
    },
    {
      title: I18n.t('Subaccount Navigation (Account Settings)'),
      description: I18n.t(
        'Not all settings options are available at the subaccount level, including the Notifications tab.'
      )
    }
  ],
  [],
  []
)

const globalAnnouncementsPermissions = generateActionTemplates(
  'manage_alerts',
  [
    {
      title: I18n.t('Announcements (Account)'),
      description: I18n.t('Allows user to add, edit, and delete global announcements.')
    }
  ],
  [],
  [],
  []
)

const courseTemplatesPermissions = generateActionTemplates(
  'manage_course_templates',
  [
    {
      title: I18n.t('Course Templates - create'),
      description: I18n.t('Allows user to set a template for an account.')
    },
    {
      description: I18n.t('Allows user to select a course as a course template in Course Settings.')
    },
    {
      description: I18n.t('Allows user to view names of course templates in the root account.')
    },
    {
      title: I18n.t('Course Templates - delete'),
      description: I18n.t('Allows user to remove a course as a course template in Course Settings.')
    },
    {
      description: I18n.t('Allows user to set an account to not use a template.')
    },
    {
      title: I18n.t('Course Templates - edit'),
      description: I18n.t('Allows user to change the template being used by an account.')
    },
    {
      description: I18n.t('Allows user to view names of course templates in the root account.')
    }
  ],
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(
        'To access the Account Settings tab, Account-level settings - manage must also be enabled.'
      )
    },
    {
      title: I18n.t('Courses'),
      description: I18n.t(
        'To create a new course to use as a course template, Manage Courses - add must also be enabled.'
      )
    }
  ],
  [],
  []
)

const developerKeysManagePermissions = generateActionTemplates(
  'manage_developer_keys',
  [
    {
      title: I18n.t('Developer Keys'),
      description: I18n.t('Allows user to create developer keys for accounts.')
    }
  ],
  [
    {
      title: I18n.t('Developer Keys'),
      description: I18n.t(
        'Required fields include key name, owner email, tool ID, redirect URL, and icon URL.'
      )
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t('Not available at the subaccount level.')
    }
  ],
  [],
  []
)

const featureFlagsManagePermissions = generateActionTemplates(
  'manage_feature_flags',
  [
    {
      title: I18n.t('Feature Options (Account Settings)'),
      description: I18n.t('Allows user to manage Feature Options in Account Settings.')
    }
  ],
  [
    {
      title: I18n.t('Feature Options (Account Settings)'),
      description: I18n.t(
        'To view Feature Options for an account, Feature Options - enable / disable must also be enabled.'
      )
    }
  ],
  [],
  []
)

const blueprintCoursePermissions = generateActionTemplates(
  'manage_master_courses',
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t('Allows user to designate a course as a Blueprint Course.')
    },
    {
      description: I18n.t('Allows user to manage Blueprint Course settings in Course Settings.')
    },
    {
      description: I18n.t('Allows user to add and remove associated courses.')
    },
    {
      description: I18n.t(
        'Allows user to edit lock settings on individual assignments, pages, or discussions.'
      )
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Course roles can only manage Blueprint Courses if they are added to the Blueprint Course as a teacher, TA, or designer role.'
      )
    },
    {
      description: I18n.t(
        'To manage associated courses, Courses - view list and Manage Courses - add must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To edit lock settings on files, Manage Courses: Admin - manage / update and Course Files - edit must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To edit lock settings on quizzes, Manage Courses: Admin - manage / update and Assignments and Quizzes - add / edit / delete must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To manage lock settings for object types, Manage Courses: Admin - manage / update must also be enabled.'
      )
    }
  ],
  [],
  []
)

const managePermissions = generateActionTemplates(
  'manage_role_overrides',
  [
    {
      title: I18n.t('Permissions'),
      description: I18n.t('Allows user to view and manage permissions.')
    }
  ],
  [],
  [],
  []
)

const sisDataManagePermissions = generateActionTemplates(
  'manage_sis',
  [
    {
      title: I18n.t('Account Navigation'),
      description: I18n.t('Determines visibility of SIS Import link in Account Navigation.')
    },
    {
      description: I18n.t(
        'Allows user to view the previous SIS import dates, errors, and imported items.'
      )
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to edit the course SIS ID.')
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        'Allows user to view and edit the SIS ID and Integration ID in a user’s Login Details.'
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t('Allows user to edit the course SIS ID.')
    },
    {
      title: I18n.t('Subaccount Settings'),
      description: I18n.t('Allows user to view and insert data in the SIS ID field.')
    }
  ],
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'To edit course settings, Manage Courses: Admin - manage / update must be enabled.'
      )
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        'To view or edit a user’s SIS ID or Integration ID, Users - view list and Users - manage login details must also both be enabled.'
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'If this permission is enabled, users do not need the SIS Data - read permission enabled. The account permission overrides the course permission.'
      )
    },
    {
      description: I18n.t(
        'To disallow users from managing SIS IDs at the course level, SIS Data - manage and SIS Data - read must both be disabled.'
      )
    },
    {
      description: I18n.t(
        'To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).'
      )
    },
    {
      title: I18n.t('SIS Import'),
      description: I18n.t('To import SIS data, SIS Data - import must also be enabled.')
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t('Not available at the subaccount level.')
    }
  ],
  [],
  []
)

const storageQuotasPermissions = generateActionTemplates(
  'manage_storage_quotas',
  [
    {
      title: I18n.t('Quotas (Account Settings)'),
      description: I18n.t(
        'Allows user to view and manage Quotas tab in Account Settings. User can set default course, user, and group storage quotes.'
      )
    }
  ],
  [],
  [],
  []
)

const usersManageLoginPermissions = generateActionTemplates(
  'manage_user_logins',
  [
    {
      title: I18n.t('People (Account)'),
      description: I18n.t('Allows user to create accounts for new users.')
    },
    {
      description: I18n.t('Allows user to remove and merge users in an account.')
    },
    {
      description: I18n.t('Allows user to modify user account details.')
    },
    {
      description: I18n.t('Allows user to view and modify login information for a user.')
    },
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t('Allows user to generate login/logout activity report in Admin Tools.')
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(
        'If Users - manage login details or Statistics - view is enabled, the user will be able to generate login/logout activity in Admin Tools. To hide the login/logout activity option in Admin Tools, both of these permissions need to be disabled.'
      )
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        'To view users and user account details, Users - view list must be enabled.'
      )
    },
    {
      description: I18n.t('To change user passwords, Users - view must also be enabled.')
    },
    {
      description: I18n.t(
        'To view a user’s SIS ID, SIS Data - manage or SIS Data - read must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To view a user’s Integration ID, SIS Data - manage must also be enabled.'
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).'
      )
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t('Not available at the subaccount level.')
    }
  ],
  [],
  []
)

const usersObserverPermissions = generateActionTemplates(
  'manage_user_observers',
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        'Allows user to manage observers associated with students in the account.'
      )
    }
  ],
  [],
  [],
  []
)

const usersModerateUserContentPermissions = generateActionTemplates(
  'moderate_user_content',
  [
    {
      title: I18n.t('ePortfolios'),
      description: I18n.t(
        'Allows user to view the ePortfolio Moderation page and manage ePortfolio spam content.'
      )
    }
  ],
  [],
  [],
  []
)

const courseContentViewPermissions = generateActionTemplates(
  'read_course_content',
  [
    {
      title: I18n.t('Courses'),
      description: I18n.t('Allows user to view published and unpublished course content.')
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Undelete Courses)'),
      description: I18n.t(
        'If Manage Courses: Admin - manage / update and Courses - undelete are also enabled, an account-level user will be able to restore deleted courses in Admin Tools.'
      )
    },
    {
      title: I18n.t('Courses'),
      description: I18n.t('If disabled, user will still have access to Course Settings.')
    },
    {
      description: I18n.t(
        'User cannot manage individual course content without the appropriate permission for that content item.'
      )
    },
    {
      description: I18n.t(
        'If course visibility is limited to users enrolled in the course, this permission allows the user to view course content without being enrolled in the course.'
      )
    },
    {
      title: I18n.t('Gradebook'),
      description: I18n.t('To view the Gradebook, Grades - view all grades must also be enabled.')
    }
  ],
  [],
  []
)

const courseListViewPermissions = generateActionTemplates(
  'read_course_list',
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Allows user to filter for Blueprint courses as the account level. Allows user to add associated courses.'
      )
    },
    {
      title: I18n.t('Courses'),
      description: I18n.t('Allows user to see the list of courses in the account.')
    }
  ],
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(
        'If this permission is disabled and Manage Courses - add is enabled, users can add a new course with the Add a New Course button in Account Settings.'
      )
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'To add associated courses, Blueprint Courses - add / edit / associate / delete and Manage Courses - add must also be enabled.'
      )
    },
    {
      title: I18n.t('Statistics'),
      description: I18n.t(
        'Allows user to see the list of recently started and ended courses in account statistics.'
      )
    }
  ],
  [],
  []
)

const courseViewChangePermissions = generateActionTemplates(
  'view_course_changes',
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(
        'Determines visibility of the Course Activity option in the Admin Tools Logging tab.'
      )
    },
    {
      description: I18n.t('Allows user to view course activity information for the account.')
    }
  ],
  [],
  [],
  []
)

const featureFlagsViewPermissions = generateActionTemplates(
  'view_feature_flags',
  [
    {
      title: I18n.t('Feature Options (Account Settings)'),
      description: I18n.t('Allows user to view Feature Options in Account Settings.')
    }
  ],
  [
    {
      title: I18n.t('Feature Options (Account Settings)'),
      description: I18n.t(
        'To manage Feature Options for an account, Feature Options - enable / disable must also be enabled.'
      )
    }
  ],
  [],
  []
)

const gradesViewChangeLogPermissions = generateActionTemplates(
  'view_grade_changes',
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(
        'Determines visibility of the Grade Change Activity option in the Admin Tools Logging tab.'
      )
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t('To search by grader or student ID, Users - view must also be enabled.')
    },
    {
      description: I18n.t(
        'To search by course ID or assignment ID, Grades - edit must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To search by assignment ID only, Grades - view all grades must also be enabled.'
      )
    }
  ],
  [],
  []
)

const notificationsPermissions = generateActionTemplates(
  'view_notifications',
  [
    {
      title: I18n.t('Admin Tools (Notifications tab)'),
      description: I18n.t('Allows user to access the View Notifications tab in Admin Tools.')
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Notifications tab)'),
      description: I18n.t(
        'To search and view notifications for a user, Users - view must also be enabled.'
      )
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t('Not available at the subaccount level.')
    }
  ]
)

const assignmentsAndQuizzes = generateActionTemplates(
  'view_quiz_answer_audits',
  [
    {
      title: I18n.t('Quizzes'),
      description: I18n.t('Allows user to view student quiz logs.')
    }
  ],
  [
    {
      title: I18n.t('Grades'),
      description: I18n.t('Grades - edit must also be enabled.')
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        'The Quiz Log Auditing feature option must be enabled in Course Settings.'
      )
    }
  ],
  [],
  []
)

const viewStatisticsPermissions = generateActionTemplates(
  'view_statistics',
  [
    {
      title: I18n.t('Account Statistics'),
      description: I18n.t('Allows admin user to view account statistics.')
    },
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t('Allows user to generate login/logout activity report in Admin Tools.')
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(
        'If Statistics - view or Users - manage login details is enabled, the user will be able to generate login/logout activity in Admin Tools. To hide the login/logout activity option in Admin Tools, both of these permissions need to be disabled.'
      )
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t('To view user page views, Users - view list must also be enabled.')
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t('Not available at the subaccount level.')
    }
  ],
  [],
  []
)

const courseUndeletePermissions = generateActionTemplates(
  'undelete_courses',
  [
    {
      title: I18n.t('Admin Tools (Restore Courses tab)'),
      description: I18n.t('Allows user to access the Restore Courses tab in Admin Tools.')
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Restore Courses tab)'),
      description: I18n.t(
        'To search for a course in the Restore Courses tab, Course Content - view must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To restore a deleted course in an account, Manage Courses - delete and Course Content - view must also be enabled.'
      )
    }
  ],
  [],
  []
)

const allowCourseAdminActions = generateActionTemplates(
  'allow_course_admin_actions',
  [
    {
      title: I18n.t('People (Course)'),
      description: I18n.t('Allows user to view login ID information for users.')
    },
    {
      description: I18n.t('Allows user to view user details for course users.')
    },
    {
      description: I18n.t('Allows user to edit a user’s section or role (if not added via SIS).')
    }
  ],
  [
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        'To edit user details, modify login details, or change user passwords, Users - manage login details must also be enabled.'
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t('To view the People page, Courses - view list must be enabled.')
    },
    {
      description: I18n.t(
        'To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).'
      )
    },
    {
      description: I18n.t('To view SIS IDs, SIS Data - read must be enabled.')
    },
    {
      description: I18n.t(
        'To edit a user’s section, Conversations - send to individual course members must be enabled.'
      )
    },
    {
      title: I18n.t('Observers (Course)'),
      description: I18n.t(
        'To link an observer to a student, Users - manage login details and Conversations - send to individual course members must be enabled.'
      )
    },
    {
      description: I18n.t(
        'To generate a pairing code on behalf of a student to share with an observer, Users - Generate observer pairing code for students must also be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t('Allows user to view login ID information for users.')
    },
    {
      description: I18n.t('Allows user to view user details for course users.')
    },
    {
      description: I18n.t('Allows user to edit a user’s section or role (if not added via SIS).')
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t('To view the People page, Courses - view list must be enabled.')
    },
    {
      description: I18n.t(
        'To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).'
      )
    },
    {
      description: I18n.t('To view SIS IDs, SIS Data - read must be enabled.')
    },
    {
      description: I18n.t(
        'To edit a user’s section, Conversations - send to individual course members must be enabled.'
      )
    },
    {
      title: I18n.t('Observers'),
      description: I18n.t(
        'To link an observer to a student, Users - manage login details and Conversations - send to individual course members must be enabled.'
      )
    },
    {
      description: I18n.t(
        'To generate a pairing code on behalf of a student to share with an observer, Users - Generate observer pairing code for students must also be enabled.'
      )
    }
  ]
)

const studentCollabPermissions = generateActionTemplates(
  'create_collaborations',
  [
    {
      title: I18n.t('Collaborations'),
      description: I18n.t('Allows user to create collaborations.')
    },
    {
      description: I18n.t('Allows user to view, edit, and delete collaborations they created.')
    }
  ],
  [
    {
      title: I18n.t('Collaborations'),
      description: I18n.t(
        'To allow view edit delete functionality of collaborations created by other users, Course Content - add / edit / delete must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'If Course Content - add / edit / delete is enabled and Student Collaborations - create is disabled, the user will not be able to create new collaborations but will be able to view edit delete all collaborations.'
      )
    },
    {
      description: I18n.t(
        'To add students to a collaboration, Users - view list must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To add a course group to a collaboration, Group view all student groups must also be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('Collaborations'),
      description: I18n.t('Allows user to create collaborations.')
    },
    {
      description: I18n.t('Allows user to view, edit, and delete conferences they created.')
    }
  ],
  [
    {
      title: I18n.t('Collaborations'),
      description: I18n.t(
        'To allow view, edit, and delete functionality of collaborations created by other users, Course Content - add / edit / delete must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'If Course Content - add / edit / delete is enabled and Student Collaborations - create is disabled, the user will not be able to create new collaborations but will be able to view, edit, and delete all collaborations.'
      )
    },
    {
      description: I18n.t(
        'To add students to a collaboration, Users - view list must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To add a course group to a collaboration, Groups - add / edit / delete must also be enabled.'
      )
    }
  ]
)

const webConferencesPermissions = generateActionTemplates(
  'create_conferences',
  [
    {
      title: I18n.t('Conferences'),
      description: I18n.t('Allows user to create new conferences in courses and groups.')
    },
    {
      description: I18n.t('Allows user to start conferences they created.')
    }
  ],
  [
    {
      title: I18n.t('Conferences'),
      description: I18n.t(
        'To allow full management of conferences created by the user or others, the Course Content permission must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To end a long-running conference, the Course Content permission must be enabled.'
      )
    },
    {
      description: I18n.t(
        'If the Course Content permission enabled and Web Conferences - create is disabled, the user can still manage conferences.'
      )
    }
  ],
  [
    {
      title: I18n.t('Conferences'),
      description: I18n.t('Allows user to create new conferences in courses and groups.')
    },
    {
      description: I18n.t('Allows user to start conferences they created.')
    }
  ],
  [
    {
      title: I18n.t('Conferences'),
      description: I18n.t(
        'To allow full management of conferences created by the user or others, the Course Content permission must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To end a long-running conference, the Course Content permission must be enabled.'
      )
    },
    {
      description: I18n.t(
        'If the Course Content permission enabled and Web Conferences - create is disabled, the user can still manage conferences.'
      )
    }
  ]
)

const discussionscreatePermissions = generateActionTemplates(
  'create_forum',
  [
    {
      title: I18n.t('Discussions'),
      description: I18n.t('Allows user to add discussions in the Discussions page.')
    }
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t('To create announcements, Discussions - moderate must also be enabled.')
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t('To view discussions in a course, Discussions - view must be enabled.')
    },
    {
      description: I18n.t(
        'Both Discussions - create and Discussions - moderate allow the user to create a discussion in the Discussions page.'
      )
    },
    {
      description: I18n.t('To manage discussions, Discussions - moderate must also be enabled.')
    }
  ],
  [
    {
      title: I18n.t('Discussions'),
      description: I18n.t('Allows user to add discussions in the Discussions page.')
    }
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t('To create announcements, Discussions - moderate must also be enabled.')
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t('To view discussions in a course, Discussions - view must be enabled.')
    },
    {
      description: I18n.t(
        'Both Discussions - create and Discussions - moderate allow the user to create a discussion in the Discussions page.'
      )
    },
    {
      description: I18n.t('To manage discussions, Discussions - moderate must also be enabled.')
    }
  ]
)

const pairingCodePermissions = generateActionTemplates(
  'generate_observer_pairing_code',
  [
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'Allows user to generate a pairing code on behalf of a student to share with an observer.'
      )
    }
  ],
  [
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'To generate a pairing code from a student`s User Settings page, the User - act as permission must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To generate a pairing code from a student`s User Details page, the Users - allow administrative actions in courses permission must also be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        'Allows user to generate a pairing code on behalf of a student to share with an observer.'
      )
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        'To generate a pairing code from a student`s User Details page, the Users - allow administrative actions in courses permission must also be enabled.'
      )
    }
  ]
)

const learningOutcomesImportPermissions = generateActionTemplates(
  'import_outcomes',
  [
    {
      title: I18n.t('Outcomes'),
      description: I18n.t('Allows user to import account learning outcomes.')
    }
  ],
  [],
  [
    {
      title: I18n.t('Outcomes'),
      description: I18n.t('Allows user to import course learning outcomes.')
    }
  ],
  []
)

const ltiAddEditPermissions = generateActionTemplates(
  'lti_add_edit',
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t('Allows user to manually add and delete an app in Account Settings.')
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to manually add and delete an app in Course Settings.')
    },
    {
      title: I18n.t('External Apps'),
      description: I18n.t('Allows user to edit configurations for manually added external apps.')
    }
  ],
  [
    {
      title: I18n.t('External Apps (Account, Course Settings)'),
      description: I18n.t(
        'If this permission is disabled, users can still install approved apps through the Canvas App Center (if enabled for your institution).'
      )
    },
    {
      description: I18n.t(
        'Additionally, if this permission is disabled, users cannot delete manually added external apps.'
      )
    }
  ],
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to manually add and delete an app in Course Settings.')
    },
    {
      title: I18n.t('External Apps (Course Settings)'),
      description: I18n.t('Allows user to edit configurations for manually added external apps.')
    }
  ],
  [
    {
      title: I18n.t('External Apps (Course Settings)'),
      description: I18n.t(
        'If this permission is disabled, users can still install approved apps through the Canvas App Center (if enabled for your institution).'
      )
    },
    {
      description: I18n.t(
        'Additionally, if this permission is disabled, users cannot delete manually added external apps.'
      )
    }
  ]
)

const assignmentsQuizzesPermissions = generateActionTemplates(
  'manage_assignments',
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(
        'Allows user to add, edit, delete, and publish and unpublish assignments.'
      )
    },
    {
      description: I18n.t('Allows user to manage assignment settings.')
    },
    {
      description: I18n.t('Allows user to add assignment groups in a course.')
    },
    {
      description: I18n.t('Allows user to enable and edit assignment group weighting in a course.')
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Allows user to edit Blueprint lock settings on the Assignments and Quizzes index pages in a Blueprint master course.'
      )
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t('Allows user to share a quiz to Commons.')
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t('Allows user to edit assignment details on individual discussions.')
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t('Allows user to add new assignments to a module.')
    },
    {
      title: I18n.t('Question Banks (Account Navigation)'),
      description: I18n.t(
        'Determines visibility and management of the Question Banks link in Account Navigation.'
      )
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t('Allows user to add, edit, delete, and publish and unpublish quizzes.')
    }
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(
        'To access the Assignments Index Page, Course Content - view must be enabled.'
      )
    },
    {
      description: I18n.t(
        'To differentiate assignments to individual students, Users - view list ​must also be enabled.'
      )
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'To edit lock settings from the Assignments index page, Blueprint Courses - add / edit / associate / delete and Manage Courses: Admin - manage / update must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'If these additional permissions are enabled, but Assignments and Quizzes - add / edit / delete is not enabled, Blueprint lock settings for an assignment can be managed from the assignment’s details page.'
      )
    },
    {
      description: I18n.t(
        'To edit lock settings on an individual quiz, or on the Quizzes index page, Blueprint Courses - add / edit / associate / delete and Manage Courses: Admin - manage / update must also be enabled.'
      )
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'To import assignments and quizzes using the Course Import Tool, Course Content - add / edit / delete must be enabled.'
      )
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        'To moderate grades, Grades - Select final grade for moderation must also be enabled.'
      )
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t('To moderate a quiz, Grades - edit​ must also be enabled.')
    },
    {
      title: I18n.t('Rubrics'),
      description: I18n.t(
        'Disabling this permission will override (if enabled) the Rubrics - add / edit / delete permission, preventing user from creating or editing rubrics from an individual assignment.'
      )
    }
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(
        'Allows user to add, edit, delete, and publish and unpublish assignments.'
      )
    },
    {
      description: I18n.t('Allows user to manage assignment settings.')
    },
    {
      description: I18n.t('Allows user to add assignment groups in a course.')
    },
    {
      description: I18n.t('Allows user to enable and edit assignment group weighting in a course.')
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Allows user to edit Blueprint lock settings on the Assignments and Quizzes index pages in a Blueprint master course.'
      )
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t('Allows user to share a quiz to Commons.')
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t('Allows user to edit assignment details on individual discussions.')
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t('Allows user to add new assignments to a module.')
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t('Allows user to add, edit, delete, and publish and unpublish quizzes.')
    }
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(
        'To differentiate assignments to individual students, Users - view list ​must also be enabled.'
      )
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'To edit lock settings from the Assignments index page, Blueprint Courses - add / edit / associate / delete and Manage Courses: Admin - manage / update must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'If these additional permissions are enabled, but Assignments and Quizzes - add / edit / delete is not enabled, Blueprint lock settings for an assignment can be managed from the assignment’s details page.'
      )
    },
    {
      description: I18n.t(
        'To edit lock settings on an individual quiz, or on the Quizzes index page, Blueprint Courses - add / edit / associate / delete and Manage Courses: Admin - manage / update must also be enabled.'
      )
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'To import assignments and quizzes using the Course Import Tool, Course Content - add / edit / delete must be enabled.'
      )
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        'To moderate grades, Grades - Select final grade for moderation must also be enabled.'
      )
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t('To moderate a quiz, Grades - edit​ must also be enabled.')
    },
    {
      title: I18n.t('Rubrics'),
      description: I18n.t(
        'Disabling this permission will override (if enabled) the Rubrics - add / edit / delete permission, preventing user from creating or editing rubrics from an individual assignment.'
      )
    }
  ]
)

const courseCalenderPermissions = generateActionTemplates(
  'manage_calendar',
  [
    {
      title: I18n.t('Calendar'),
      description: I18n.t('Allows user to add, edit, and delete events in the course calendar.')
    },
    {
      title: I18n.t('Scheduler'),
      description: I18n.t(
        'Allows user to create and manage appointments on the calendar using Scheduler.'
      )
    }
  ],
  [
    {
      title: I18n.t('Calendar'),
      description: I18n.t(
        'Regardless of whether this permission is enabled or disabled, users will still be able to manage events in their personal calendar.'
      )
    },
    {
      title: I18n.t('Scheduler'),
      description: I18n.t('Scheduler must be enabled for your account.')
    }
  ],
  [
    {
      title: I18n.t('Calendar'),
      description: I18n.t('Allows user to add, edit, and delete events in the course calendar.')
    },
    {
      title: I18n.t('Scheduler'),
      description: I18n.t(
        'Allows user to create and manage appointments on the calendar using Scheduler.'
      )
    }
  ],
  [
    {
      title: I18n.t('Calendar'),
      description: I18n.t(
        'Regardless of whether this permission is enabled or disabled, users will still be able to manage events in their personal calendar.'
      )
    },
    {
      title: I18n.t('Scheduler'),
      description: I18n.t('Scheduler must be enabled by your Canvas admin.')
    }
  ]
)

const courseContentAddPermissions = generateActionTemplates(
  'manage_content',
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t('Allows user to share course items directly with other users.')
    },
    {
      description: I18n.t('Allows user to copy individual course items to another course.')
    },
    {
      title: I18n.t('Attendance'),
      description: I18n.t('Allows user to access the Attendance tool.')
    },
    {
      title: I18n.t('Calendar'),
      description: I18n.t(
        'Allows user to add events to List View Dashboard via the Add to Student To-Do checkbox.'
      )
    },
    {
      title: I18n.t('Chat'),
      description: I18n.t('Allows user to access the Chat tool.')
    },
    {
      title: I18n.t('Collaborations'),
      description: I18n.t('Allows user to view previously created collaborations.')
    },
    {
      description: I18n.t(
        'Allows user to edit title, description, or remove collaborators on all collaborations.'
      )
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t('Allows user to import resources from Commons into a course.')
    },
    {
      description: I18n.t(
        'Allows user to share assignments to Commons or edit previously shared content.'
      )
    },
    {
      title: I18n.t('Conferences'),
      description: I18n.t('Allows user to edit Conferences.')
    },
    {
      title: I18n.t('Course Home Page'),
      description: I18n.t(
        'Allows user to view Course Status, Choose Home Page, and Course Setup Checklist buttons in the Home page.'
      )
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to import content using the Course Import Tool.')
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        'Allows user to add non-graded discussions to List View Dashboard via the Add to Student To-Do checkbox.'
      )
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(
        'Allows user to manage modules (create, add items, edit module settings, publish, unpublish, etc.).'
      )
    },
    {
      title: I18n.t('Pages'),
      description: I18n.t(
        'Allows user to add pages to List View Dashboard via the Add to Student To-Do checkbox.'
      )
    },
    {
      title: I18n.t('Syllabus'),
      description: I18n.t('Allows user to edit the course syllabus.')
    }
  ],
  [
    {
      title: I18n.t('Attendance'),
      description: I18n.t('The Attendance tool must be enabled by your Canvas admin.')
    },
    {
      title: I18n.t('Chat'),
      description: I18n.t('The Chat tool must be enabled by your Canvas admin.')
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t(
        'To share a Discussion to Commons, Discussions - view must also be enabled.'
      )
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'The Course Status buttons (unpublished and published) are only displayed until a student submission is received. Courses cannot be unpublished with student submissions.'
      )
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(
        'To publish and unpublish module content, Manage Courses: Admin - manage / update and Course Content - view must also be enabled. Module items cannot be unpublished if there are student submissions.'
      )
    }
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t('Allows user to share course items directly with other users.')
    },
    {
      description: I18n.t('Allows user to copy individual course items to another course.')
    },
    {
      title: I18n.t('Attendance'),
      description: I18n.t('Allows user to access the Attendance tool.')
    },
    {
      title: I18n.t('Calendar'),
      description: I18n.t(
        'Allows user to add events to List View Dashboard via the Add to Student To-Do checkbox. '
      )
    },
    {
      title: I18n.t('Chat'),
      description: I18n.t('Allows user to access the Chat tool.')
    },
    {
      title: I18n.t('Collaborations'),
      description: I18n.t('Allows user to view previously created collaborations.')
    },
    {
      description: I18n.t(
        'Allows user to edit title, description, or remove collaborators on all collaborations.'
      )
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t('Allows user to import resources from Commons into a course.')
    },
    {
      description: I18n.t(
        'Allows user to share assignments to Commons or edit previously shared content.'
      )
    },
    {
      title: I18n.t('Conferences'),
      description: I18n.t('Allows user to edit Conferences.')
    },
    {
      title: I18n.t('Course Home Page'),
      description: I18n.t(
        'Allows user to view Course Status, Choose Home Page, and Course Setup Checklist buttons in the Home page.'
      )
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to import content using the Course Import Tool.')
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        'Allows user to add non-graded discussions to List View Dashboard via the Add to Student To-Do checkbox.'
      )
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(
        'Allows user to manage modules (create, add items, edit module settings, publish, unpublish, etc.).'
      )
    },
    {
      title: I18n.t('Pages'),
      description: I18n.t(
        'Allows user to add pages to List View Dashboard via the Add to Student To-Do checkbox.'
      )
    },
    {
      title: I18n.t('Syllabus'),
      description: I18n.t('Allows user to edit the course syllabus.')
    }
  ],
  [
    {
      title: I18n.t('Attendance'),
      description: I18n.t('The Attendance tool must be enabled by your Canvas admin.')
    },
    {
      title: I18n.t('Chat'),
      description: I18n.t('The Chat tool must be enabled by your Canvas admin.')
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t(
        'To share a Discussion to Commons, Discussions - view must also be enabled.'
      )
    },
    {
      title: I18n.t('Course Home Page'),
      description: I18n.t(
        'Teachers, designers, and TAs can select a course home page without the Course content - add / edit / delete permission.'
      )
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'The Course Status buttons (unpublished and published) are only displayed until a student submission is received. Courses cannot be unpublished with student submissions.'
      )
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t('Module items cannot be unpublished if there are student submissions.')
    }
  ]
)

const courseVisibilityPermissions = generateActionTemplates(
  'manage_course_visibility',
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'Allows user to manage the Visibility options in Course Settings or when creating a new course.'
      )
    }
  ],
  [],
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'Allows user to manage the Visibility options in Course Settings or when creating a new course.'
      )
    }
  ],
  []
)

const permissionsTeacher = generateActionTemplates(
  'manage_course_teacher_enrollments',
  [
    {
      title: I18n.t('Teachers - add'),
      description: I18n.t('Allows user to add teachers to a course from the account Courses page.')
    },
    {
      description: I18n.t('Allows user to add teachers to a course.')
    },
    {
      title: I18n.t('Teachers - remove'),
      description: I18n.t('Allows user to remove teachers from a course.')
    }
  ],
  [
    {
      title: I18n.t('Courses (Account)'),
      description: I18n.t(
        'If the Open Registration account setting is enabled, users with this permission can add teachers to a course from the Courses page via email address or login ID even if a teacher does not already have a Canvas account.'
      )
    },
    {
      description: I18n.t('To add a user via SIS ID, SIS Data - manage must also be enabled.')
    },
    {
      description: I18n.t(
        'To access the account Courses page, Courses - view list must be enabled.'
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'If an enrollment is created via SIS, only admins can remove the enrollment from a course.'
      )
    },
    {
      description: I18n.t('To remove a user via SIS ID, SIS Data - manage must also be enabled.')
    }
  ],
  [
    {
      title: I18n.t('Teachers - add'),
      description: I18n.t('Allows user to add teachers to a course.')
    },
    {
      title: I18n.t('Teachers - remove'),
      description: I18n.t('Allows user to remove teachers from a course.')
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        'If the Open Registration account setting is enabled, users with this permission can add teachers to a course from the People page via email address or login ID even if a teacher does not already have a Canvas account.'
      )
    },
    {
      description: I18n.t('To add a user via SIS ID, SIS Data - manage must also be enabled.')
    },
    {
      description: I18n.t(
        'If an enrollment is created via SIS, only admins can remove the enrollment from a course.'
      )
    },
    {
      description: I18n.t('To remove a user via SIS ID, SIS Data - manage must also be enabled.')
    }
  ]
)

const permissionsTA = generateActionTemplates(
  'manage_course_ta_enrollments',
  [
    {
      title: I18n.t('TAs - add'),
      description: I18n.t('Allows user to add TAs to a course from the account Courses page.')
    },
    {
      description: I18n.t('Allows user to add TAs in the course.')
    },
    {
      title: I18n.t('TAs - remove'),
      description: I18n.t('Allows user to remove TAs from a course.')
    }
  ],
  [
    {
      title: I18n.t('Courses (Account)'),
      description: I18n.t(
        'If the Open Registration account setting is enabled, users with this permission can add TAs to a course from the Courses page via email address or login ID even if a TA does not already have a Canvas account.'
      )
    },
    {
      description: I18n.t('To add a user via SIS ID, SIS Data - manage must also be enabled.')
    },
    {
      description: I18n.t(
        'To access the account Courses page, Courses - view list must be enabled.'
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'If an enrollment is created via SIS, only admins can remove the enrollment from a course.'
      )
    },
    {
      description: I18n.t('To remove a user via SIS ID, SIS Data - manage must also be enabled.')
    }
  ],
  [
    {
      title: I18n.t('TAs - add'),
      description: I18n.t('Allows user to add TAs in the course.')
    },
    {
      title: I18n.t('TAs - remove'),
      description: I18n.t('Allows user to remove TAs from a course.')
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        'If the Open Registration account setting is enabled, users with this permission can add TAs to a course from the People page via email address or login ID even if a TA does not already have a Canvas account.'
      )
    },
    {
      description: I18n.t('To add a user via SIS ID, SIS Data - manage must also be enabled.')
    },
    {
      description: I18n.t(
        'If an enrollment is created via SIS, only admins can remove the enrollment from a course.'
      )
    },
    {
      description: I18n.t('To remove a user via SIS ID, SIS Data - manage must also be enabled.')
    }
  ]
)

const permissionsDesigner = generateActionTemplates(
  'manage_course_designer_enrollments',
  [
    {
      title: I18n.t('Designers - add'),
      description: I18n.t('Allows user to add designers to a course from the account Courses page.')
    },
    {
      description: I18n.t('Allows user to add designers to a course.')
    },
    {
      title: I18n.t('Designers - remove'),
      description: I18n.t('Allows user to remove designers from a course.')
    }
  ],
  [
    {
      title: I18n.t('Courses (Account)'),
      description: I18n.t(
        'If the Open Registration account setting is enabled, users with this permission can add designers to a course from the Courses page via email address or login ID even if a designer does not already have a Canvas account.'
      )
    },
    {
      description: I18n.t('To add a user via SIS ID, SIS Data - manage must also be enabled.')
    },
    {
      description: I18n.t(
        'To access the account Courses page, Courses - view list must be enabled.'
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'If an enrollment is created via SIS, only admins can remove the enrollment from a course.'
      )
    },
    {
      description: I18n.t('To remove a user via SIS ID, SIS Data - manage must also be enabled.')
    }
  ],
  [
    {
      title: I18n.t('Designers - add'),
      description: I18n.t('Allows user to add designers to a course.')
    },
    {
      title: I18n.t('Designers - remove'),
      description: I18n.t('Allows user to remove designers from a course.')
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        'If the Open Registration account setting is enabled, users with this permission can add designers to a course from the People page via email address or login ID even if a designer does not already have a Canvas account.'
      )
    },
    {
      description: I18n.t('To add a user via SIS ID, SIS Data - manage must also be enabled.')
    },
    {
      description: I18n.t(
        'If an enrollment is created via SIS, only admins can remove the enrollment from a course.'
      )
    },
    {
      description: I18n.t('To remove a user via SIS ID, SIS Data - manage must also be enabled.')
    }
  ]
)

const permissionsObserver = generateActionTemplates(
  'manage_course_observer_enrollments',
  [
    {
      title: I18n.t('Observers - add'),
      description: I18n.t('Allows user to add observers to a course from the account Courses page.')
    },
    {
      description: I18n.t('Allows user to add observers to a course.')
    },
    {
      title: I18n.t('Observers - remove'),
      description: I18n.t('Allows user to remove observers from a course.')
    }
  ],
  [
    {
      title: I18n.t('Courses (Account)'),
      description: I18n.t(
        'If the Open Registration account setting is enabled, users with this permission can add observers to a course from the Courses page via email address or login ID even if an observer does not already have a Canvas account.'
      )
    },
    {
      description: I18n.t('To add a user via SIS ID, SIS Data - manage must also be enabled.')
    },
    {
      description: I18n.t(
        'To access the account Courses page, Courses - view list must be enabled.'
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'If an enrollment is created via SIS, only admins can remove the enrollment from a course.'
      )
    },
    {
      description: I18n.t('To remove a user via SIS ID, SIS Data - manage must also be enabled.')
    }
  ],
  [
    {
      title: I18n.t('Observers - add'),
      description: I18n.t('Allows user to add observers to a course.')
    },
    {
      title: I18n.t('Observers - remove'),
      description: I18n.t('Allows user to remove observers from a course.')
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        'If the Open Registration account setting is enabled, users with this permission can add observers to a course from the People page via email address or login ID even if an observer does not already have a Canvas account.'
      )
    },
    {
      description: I18n.t('To add a user via SIS ID, SIS Data - manage must also be enabled.')
    },
    {
      description: I18n.t(
        'If an enrollment is created via SIS, only admins can remove the enrollment from a course.'
      )
    },
    {
      description: I18n.t('To remove a user via SIS ID, SIS Data - manage must also be enabled.')
    }
  ]
)

const permissionsStudent = generateActionTemplates(
  'manage_course_student_enrollments',
  [
    {
      title: I18n.t('Students - add'),
      description: I18n.t('Allows user to add students to a course from the account Courses page.')
    },
    {
      description: I18n.t('Allows user to add students to a course.')
    },
    {
      title: I18n.t('Students - remove'),
      description: I18n.t('Allows user to remove students from a course.')
    }
  ],
  [
    {
      title: I18n.t('Courses (Account)'),
      description: I18n.t(
        'If the Open Registration account setting is enabled, users with this permission can add students to a course from the Courses page via email address or login ID even if a student does not already have a Canvas account.'
      )
    },
    {
      description: I18n.t('To add a user via SIS ID, SIS Data - manage must also be enabled.')
    },
    {
      description: I18n.t(
        'To access the account Courses page, Courses - view list must be enabled.'
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'If an enrollment is created via SIS, only admins can remove the enrollment from a course.'
      )
    },
    {
      description: I18n.t('To remove a user via SIS ID, SIS Data - manage must also be enabled.')
    }
  ],
  [
    {
      title: I18n.t('Students - add'),
      description: I18n.t('Allows user to add students to a course.')
    },
    {
      title: I18n.t('Students - remove'),
      description: I18n.t('Allows user to remove students from a course.')
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        'If the Open Registration account setting is enabled, users with this permission can add students to a course from the People page via email address or login ID even if a student does not already have a Canvas account.'
      )
    },
    {
      description: I18n.t('To add a user via SIS ID, SIS Data - manage must also be enabled.')
    },
    {
      description: I18n.t(
        'If an enrollment is created via SIS, only admins can remove the enrollment from a course.'
      )
    },
    {
      description: I18n.t('To remove a user via SIS ID, SIS Data - manage must also be enabled.')
    }
  ]
)

const courseManagePermissions = generateActionTemplates(
  'manage_courses',
  [
    {
      title: I18n.t('Admin - manage / update'),
      description: I18n.t('Allows user to sync Blueprint Courses.')
    },
    {
      description: I18n.t('Allows user to view Blueprint Sync history.')
    },
    {
      description: I18n.t('Allows user to view and manage courses in the account.')
    },
    {
      description: I18n.t('Allows user to view the Course Setup Checklist button.')
    },
    {
      description: I18n.t('Allows user to access the Navigation tab in Course Settings.')
    },
    {
      description: I18n.t(
        'Allows user to edit course image, name, course code, time zone, subaccount, term, and other options in Course Details tab.'
      )
    },
    {
      description: I18n.t(
        'Allows user to access Student View (test student), Copy this Course, Reset Course Content, and Permanently Delete Course buttons.'
      )
    },
    {
      description: I18n.t(
        'Allows user to view student context cards in announcement and discussion replies.'
      )
    },
    {
      title: I18n.t('Courses - add'),
      description: I18n.t('Allows user to add new courses to an account.')
    },
    {
      title: I18n.t('Courses - conclude'),
      description: I18n.t('Allows user to view the Conclude Course button.')
    },
    {
      title: I18n.t('Courses - delete'),
      description: I18n.t(
        'Allows user to view the Delete this Course button. Allows user to view the Reset Course Content button.'
      )
    },
    {
      title: I18n.t('Courses - publish'),
      description: I18n.t(
        'Allows user to view the Publish Course and Unpublish Course buttons in the Course Home page. Allows user to view the Publish button in a course card for an unpublished course (Card View Dashboard).'
      )
    }
  ],
  [
    {
      title: I18n.t('Courses - Account Settings'),
      description: I18n.t(
        'To access the Courses link in Account Navigation, Courses - view list must be enabled.'
      )
    },
    {
      description: I18n.t(
        'If Courses - add is enabled and Courses - view list is disabled, users can add a new course with the Add a New Course button in Account Settings.'
      )
    },
    {
      description: I18n.t(
        'To restore a deleted course, Courses - delete, Courses - undelete, and Course Content - view must also be enabled.'
      )
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'If Admin - Manage / Update is enabled, but Blueprint Courses - add / edit / associate / delete is not enabled, users can still sync Blueprint Courses and view Sync history.'
      )
    },
    {
      title: I18n.t('Course Content'),
      description: I18n.t(
        'To manage course content, Manage Courses: Admin - manage / update and Course Content - add / edit / delete must be enabled.'
      )
    },
    {
      description: I18n.t(
        'To view Choose Home Page and Course Setup Checklist buttons, Manage Courses: Admin - manage / update and Course Content - view must also be enabled. (Teachers, designers, and TAs can set the home page of a course, regardless of their permissions.)'
      )
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'The Courses - delete permission affects viewing the Permanently Delete this Course button, which only appears for manually created courses.'
      )
    },
    {
      description: I18n.t(
        'To cross-list a section, Manage Courses: Admin - manage / update and Manage Course Sections - edit must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To edit the course SIS ID, Manage Courses: Admin - manage / update and SIS Data - manage must also be enabled.'
      )
    },
    {
      title: I18n.t('Courses - Account Navigations'),
      description: I18n.t(
        'To access the Courses link in Account Navigation, Manage Courses: Admin - manage / update and Courses - view list must be enabled.'
      )
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        'To view grades in a course, Manage Courses: Admin - manage / update and Grades - view all grades must also be enabled.'
      )
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(
        'The Courses - publish permission allows the user to publish courses that do not contain modules. To publish/unpublish module content, Course Content - add / edit / delete must be enabled.'
      )
    },
    {
      title: I18n.t('Student Context Cards'),
      description: I18n.t(
        'Student context cards must be enabled for an account by an admin. If Manage Courses: Admin - manage / update is not enabled, users can still view context cards through the Gradebook.'
      )
    }
  ],
  [
    {
      title: I18n.t('Courses - add'),
      description: I18n.t('Allows user to add new courses to an account.')
    },
    {
      title: I18n.t('Courses - conclude'),
      description: I18n.t('Allows user to view the Conclude Course button.')
    },
    {
      title: I18n.t('Courses - delete'),
      description: I18n.t('Allows user to view the Delete this Course button.')
    },
    {
      description: I18n.t('Allows user to view the Reset Course Content button.')
    },
    {
      title: I18n.t('Courses - publish'),
      description: I18n.t(
        'Allows user to view the Publish Course and Unpublish Course buttons in the Course Home page.'
      )
    },
    {
      description: I18n.t(
        'Allows user to view the Publish button in a course card for an unpublished course (Card View Dashboard).'
      )
    }
  ],
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'The Courses - delete permission affects viewing the Permanently Delete this Course button, which only appears for manually created courses.'
      )
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(
        'The Courses - publish permission allows the user to publish courses that do not contain modules. To publish/unpublish module content, Course Content - add / edit / delete must be enabled.'
      )
    }
  ]
)

const courseFilesAddPermissions = generateActionTemplates(
  'manage_files',
  [
    {
      title: I18n.t('Course Files - add'),
      description: I18n.t('Allows user to add course files and folders.')
    },
    {
      description: I18n.t('Allows user to import a zip file.')
    },
    {
      title: I18n.t('Course Files - edit'),
      description: I18n.t('Allows user to edit course files and folders.')
    },
    {
      title: I18n.t('Course Files - delete'),
      description: I18n.t('Allows user to delete course files and folders.')
    }
  ],
  [
    {
      title: I18n.t('Course Files'),
      description: I18n.t(
        'If one or all permissions are disabled, user can still view and download files into a zip file.'
      )
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'To import files using the Course Import Tool, Course files - add and Course Content - add / edit / delete must be enabled.'
      )
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'To edit lock settings for course files, Course files - edit, Blueprint Courses - add / edit / associate / delete, and Manage Courses: Admin - manage / update must also be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('Course Files - add'),
      description: I18n.t('Allows user to add course files and folders.')
    },
    {
      description: I18n.t('Allows user to import a zip file.')
    },
    {
      title: I18n.t('Course Files - edit'),
      description: I18n.t('Allows user to edit course files and folders.')
    },
    {
      title: I18n.t('Course Files - delete'),
      description: I18n.t('Allows user to delete course files and folders.')
    }
  ],
  [
    {
      title: I18n.t('Course Files'),
      description: I18n.t(
        'If one or all permissions are disabled, user can still view and download files into a zip file.'
      )
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'To import files using the Course Import Tool, Course files - add and Course Content - add / edit / delete must be enabled.'
      )
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t('Blueprint courses must be enabled for an account by an admin.')
    },
    {
      description: I18n.t(
        'Course roles can only manage content in Blueprint Courses if they are added to the Blueprint Course as a teacher, TA, or designer role.'
      )
    }
  ]
)

const gradesEditPermissions = generateActionTemplates(
  'manage_grades',
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(
        'Allows user to search by course ID or assignment ID in grade change logs in Admin Tools (not available at the subaccount level.)'
      )
    },
    {
      title: I18n.t('Analytics'),
      description: I18n.t('Allows user to view student-specific data in Analytics.')
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to view the course grading scheme.')
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        'Allows user to like discussion posts when the Only Graders Can Like checkbox is selected.'
      )
    },
    {
      title: I18n.t('Gradebook'),
      description: I18n.t('Allows user to add, edit, and update grades in the Gradebook.')
    },
    {
      description: I18n.t(
        'Allows user to access Gradebook History. Allows user to access the Learning Mastery Gradebook (if enabled).'
      )
    },
    {
      title: I18n.t('Grading Schemes'),
      description: I18n.t('Allows user to create and modify grading schemes.')
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t('Allows user to moderate a quiz and view the quiz statistics page.')
    },
    {
      title: I18n.t('SpeedGrader'),
      description: I18n.t('Allows user to edit grades and add comments in SpeedGrader.')
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(
        'To search grade change logs, Grades - view change logs must also be enabled.'
      )
    },
    {
      title: I18n.t('Analytics'),
      description: I18n.t(
        'To view student analytics in course analytics, Analytics - view must also be enabled.'
      )
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'To edit course grading schemes, Manage Courses: Admin - manage / update must also be enabled.'
      )
    },
    {
      title: I18n.t('Gradebook, SpeedGrader'),
      description: I18n.t(
        'Gradebook and SpeedGrader will be inaccessible if both Grades - edit and Grades - view all grades are disabled.'
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'To view student analytics, Users - view list and Analytics - view must also be enabled.'
      )
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        'To moderate a quiz, Assignments and Quizzes - add / edit / delete also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To view the user SIS ID column in the Quiz Item Analysis CSV file, SIS Data - read must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To view the submission log, Quizzes - view submission log must also be enabled.'
      )
    },
    {
      title: I18n.t('Reports'),
      description: I18n.t(
        'To access the Student Interactions report, Courses - view usage reports must also be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('Analytics'),
      description: I18n.t('Allows user to view student-specific data in Analytics.')
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to edit grading schemes.')
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        'Allows user to like discussion posts when the Only Graders Can Like checkbox is selected.'
      )
    },
    {
      title: I18n.t('Gradebook'),
      description: I18n.t('Allows user to edit grades in the Gradebook.')
    },
    {
      description: I18n.t('Allows user to access Gradebook History.')
    },
    {
      description: I18n.t('Allows user to access the Learning Mastery Gradebook (if enabled).')
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t('Allows user to moderate a quiz and view the quiz statistics page.')
    },
    {
      title: I18n.t('SpeedGrader'),
      description: I18n.t('Allows user to edit grades and add comments in SpeedGrader.')
    }
  ],
  [
    {
      title: I18n.t('Analytics'),
      description: I18n.t(
        'To view student analytics in course analytics, Analytics - view must also be enabled.'
      )
    },
    {
      title: I18n.t('Gradebook, SpeedGrader'),
      description: I18n.t(
        'Gradebook and SpeedGrader will be inaccessible if both Grades - edit and Grades - view all grades are disabled.'
      )
    },
    {
      title: I18n.t('People'),
      description: I18n.t(
        'To view student analytics, Users - view list and Analytics - view must also be enabled.'
      )
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        'To moderate a quiz, Assignments and Quizzes - add / edit / delete must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To view the user SIS ID column in the Quiz Item Analysis CSV file, SIS Data - read must also be enabled.'
      )
    },
    {
      title: I18n.t('Settings'),
      description: I18n.t('Course Grading Schemes can be enabled/disabled in Course Settings.')
    }
  ]
)

const gradesAddEditDeletePermissions = generateActionTemplates(
  'manage_groups',
  [
    {
      title: I18n.t('Account Groups'),
      description: I18n.t('Allows user to create, edit, and delete account groups.')
    },
    {
      title: I18n.t('Course Groups'),
      description: I18n.t('Allows user to create, edit, and delete course groups.')
    },
    {
      description: I18n.t(
        'Allows user to create, edit, and delete course groups created by students.'
      )
    }
  ],
  [
    {
      title: I18n.t('Account Groups'),
      description: I18n.t(
        'If this permission is disabled, at the account level, the user cannot view any existing account groups. At the course level, the user can view, but not access, any existing groups, including groups created by students.'
      )
    },
    {
      description: I18n.t('To view groups, Users - view list must also be enabled.')
    },
    {
      description: I18n.t(
        'To add account level groups via CSV, SIS Data - import must also be enabled.'
      )
    },
    {
      title: I18n.t('Course Groups'),
      description: I18n.t('By default, students can always create groups in a course.')
    },
    {
      description: I18n.t(
        'To restrict students from creating groups, Manage Courses: Admin - manage / update must be enabled, and the Let students organize their own groups checkbox in Course Settings must not be selected.'
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'To access the People page and view Groups, Users - view list must also be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('People (Groups tab)'),
      description: I18n.t('Allows user to create, edit, and delete course groups.')
    },
    {
      description: I18n.t(
        'Allows user to create, edit, and delete course groups created by students.'
      )
    }
  ],
  [
    {
      title: I18n.t('Collaborations'),
      description: I18n.t(
        'Allows user to view all course groups, not just where they are enrolled, in the Collaborate With window.'
      )
    },
    {
      title: I18n.t('Groups'),
      description: I18n.t(
        'If this permission is disabled, the user can only view existing groups, including groups created by students.'
      )
    },
    {
      title: I18n.t('People'),
      description: I18n.t(
        'To access the People page and view Groups, Users - view list must also be enabled.'
      )
    },
    {
      title: I18n.t('Course Settings (Course Details tab)'),
      description: I18n.t(
        'To restrict students from creating groups, do not select the Let students organize their own groups checkbox in Course Settings.'
      )
    }
  ]
)

const alertPermissions = generateActionTemplates(
  'manage_interaction_alerts',
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to configure alerts in Course Settings.')
    }
  ],
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(
        'This is an account setting that must be enabled by a Customer Success Manager. Alerts are a seldom-used feature designed to send an alert to students, teachers or admins for specific triggers (e.g., no student-teacher interaction for 7 days). They are checked every day, and notifications will be sent to the student and/or the teacher until the triggering problem is resolved.'
      )
    }
  ],
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to configure alerts in Course Settings.')
    }
  ],
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(
        'Alerts must be configured for the institution. Alerts are a seldom-used feature designed to send an alert to students, teachers or admins for specific triggers (e.g., no student-teacher interaction for 7 days). They are checked every day, and notifications will be sent to the student and/or the teacher until the triggering problem is resolved.'
      )
    }
  ]
)

const learningOutcomesAddEditDeletePermissions = generateActionTemplates(
  'manage_outcomes',
  [
    {
      title: I18n.t('Outcomes'),
      description: I18n.t('Determines visibility and management of Outcomes in Account Navigation.')
    },
    {
      description: I18n.t(
        'Allows user to create, edit, and delete outcomes and outcome groups at the account and course levels.'
      )
    }
  ],
  [
    {
      title: I18n.t('Outcomes'),
      description: I18n.t(
        'To allow the Outcomes page as read-only, this permission can be disabled but Course Content - view must be enabled.'
      )
    },
    {
      description: I18n.t(
        'To import learning outcomes, Learning Outcomes - import must also be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('Outcomes'),
      description: I18n.t(
        'Allows user to create, edit, and delete outcomes and outcome groups at the course level.'
      )
    }
  ],
  [
    {
      title: I18n.t('Outcomes'),
      description: I18n.t(
        'To import learning outcomes, Learning Outcomes - import must also be enabled.'
      )
    }
  ]
)

const outcomeProficiencyCalculationsAddEditDeletePermissions = generateActionTemplates(
  'manage_proficiency_calculations',
  [
    {
      title: I18n.t('Outcome Proficiency Calculations'),
      description: I18n.t(
        'Allows user to set outcome proficiency calculations at the account and course levels.'
      )
    }
  ],
  [],
  [
    {
      title: I18n.t('Outcome Proficiency Calculations'),
      description: I18n.t(
        'Allows user to set outcome proficiency calculations at the course level.'
      )
    }
  ],
  []
)

const outcomeProficiencyScalesAddEditDeletePermissions = generateActionTemplates(
  'manage_proficiency_scales',
  [
    {
      title: I18n.t('Outcome Mastery Scales'),
      description: I18n.t(
        'Allows user to set outcome mastery scales at the account and course levels.'
      )
    }
  ],
  [],
  [
    {
      title: I18n.t('Outcome Mastery Scales'),
      description: I18n.t('Allows user to set outcome mastery scales at the course level.')
    }
  ],
  []
)

const courseSectionsViewPermissions = generateActionTemplates(
  'manage_sections',
  [
    {
      title: I18n.t('Course Sections - add'),
      description: I18n.t('Allows user to add course sections in Course Settings.')
    },
    {
      title: I18n.t('Course Sections - edit'),
      description: I18n.t('Allows user to rename course sections.')
    },
    {
      description: I18n.t('Allows user to change start and end dates for course sections.')
    },
    {
      description: I18n.t('Allows user to cross-list sections.')
    },
    {
      title: I18n.t('Course Sections - delete'),
      description: I18n.t('Allows user to delete course sections.')
    },
    {
      description: I18n.t('Allows user to delete a user from a course section.')
    }
  ],
  [
    {
      title: I18n.t('Cross-Listing'),
      description: I18n.t(
        'To cross-list sections, Course Sections - edit and Manage Courses: Admin - manage / update must also be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('Course Sections - add'),
      description: I18n.t('Allows user to add course sections in Course Settings.')
    },
    {
      title: I18n.t('Course Sections - edit'),
      description: I18n.t(
        'Allows user to rename course sections. Allows user to change start and end dates for course sections. Allows user to cross-list sections.'
      )
    },
    {
      title: I18n.t('Course Sections - delete'),
      description: I18n.t('Allows user to delete course sections.')
    },
    {
      description: I18n.t('Allows user to delete a user from a course section.')
    }
  ],
  [
    {
      title: I18n.t('Cross-Listing'),
      description: I18n.t(
        'To cross-list sections, Course Sections - edit must be enabled. The user must also be enrolled as an instructor in the courses being cross-listed.'
      )
    }
  ]
)

const manageStudentsCoursesPermissions = generateActionTemplates(
  'manage_students',
  [
    {
      title: I18n.t('People (Course)'),
      description: I18n.t('Allows user to view login ID information for students.')
    },
    {
      description: I18n.t('Allows user to view prior enrollments.')
    },
    {
      description: I18n.t('Allows user to access a user’s settings menu and user details.')
    },
    {
      description: I18n.t('Allows user to edit a student’s section or role.')
    },
    {
      description: I18n.t('Allows user to resend course invitations from the Course People page.')
    }
  ],
  [
    {
      title: I18n.t('Courses (Account)'),
      description: I18n.t(
        'To access the account Courses page, Courses - view list must be enabled.'
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'To add or remove a student to or from a course, the Users - Student permission must be enabled.'
      )
    },
    {
      description: I18n.t(
        'To view the list of users in the course, Users - view list must be enabled.'
      )
    },
    {
      description: I18n.t('To view SIS IDs, SIS Data - read must be enabled.')
    },
    {
      description: I18n.t(
        'To edit a student’s section, Conversations - send to individual course members must also be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t('Allows user to view login ID information for students.')
    },
    {
      description: I18n.t('Allows user to view prior enrollments.')
    },
    {
      description: I18n.t('Allows user to access a user’s settings menu and user details.')
    },
    {
      description: I18n.t('Allows user to edit a student’s section or role.')
    },
    {
      description: I18n.t('Allows user to resend course invitations from the Course People page.')
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        'To add or remove a student to or from a course, the Users - Student permission must be enabled.'
      )
    },
    {
      description: I18n.t(
        'To view the list of users in the course, Users - view list must be enabled.'
      )
    },
    {
      description: I18n.t('To view SIS IDs, SIS Data - read must be enabled.')
    },
    {
      description: I18n.t(
        'To edit a student’s section, Conversations - send to individual course members must also be enabled.'
      )
    }
  ]
)

const usernotesPermissions = generateActionTemplates(
  'manage_user_notes',
  [
    {
      title: I18n.t('Global Navigation'),
      description: I18n.t('Allows user to view the Faculty Journal link in Global Navigation.')
    },
    {
      title: I18n.t('Student Interaction Report'),
      description: I18n.t(
        'Allows user to view Faculty Journal entries in the Student Interactions Report.'
      )
    },
    {
      title: I18n.t('User Details'),
      description: I18n.t(
        'Allows user to view a link to the Faculty Journal in the User Details page sidebar.'
      )
    },
    {
      description: I18n.t(
        'Allows user to view Faculty Journal information for individual students.'
      )
    },
    {
      description: I18n.t('Allows user to create new entries in the Faculty Journal.')
    }
  ],
  [
    {
      title: I18n.t('Reports'),
      description: I18n.t(
        'To view the Student Interactions Report, Grades - view all grades and Courses - view usage reports must also be enabled.'
      )
    },
    {
      title: I18n.t('User Details'),
      description: I18n.t(
        'To view the User Details page for a student, Users - add/remove students in courses must also be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('Student Interaction Report'),
      description: I18n.t(
        'Allows user to view Faculty Journal entries in the Student Interactions Report.'
      )
    },
    {
      title: I18n.t('User Details'),
      description: I18n.t(
        'Allows user to view a link to the Faculty Journal in the User Details page sidebar.'
      )
    },
    {
      description: I18n.t(
        'Allows user to view Faculty Journal information for individual students.'
      )
    },
    {
      description: I18n.t('Allows user to create new entries in the Faculty Journal.')
    }
  ],
  [
    {
      title: I18n.t('Reports'),
      description: I18n.t(
        'To view the Student Interactions Report, Grades - view all grades and Courses - view usage reports must also be enabled.'
      )
    },
    {
      title: I18n.t('User Details'),
      description: I18n.t(
        'To view the User Details page for a student, Users - add/remove students in courses must also be enabled.'
      )
    }
  ]
)

const rubricsAddPermissions = generateActionTemplates(
  'manage_rubrics',
  [
    {
      title: I18n.t('Rubrics'),
      description: I18n.t(
        'Determines visibility and management of the Rubrics link in Account Navigation.'
      )
    },
    {
      description: I18n.t('Allows user to create, edit, and delete rubrics.')
    }
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(
        'Users can access and create (but not edit) individual assignment rubrics through Assignments when Course Content - view and Assignments and Quizzes - add / edit / delete are enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('Rubrics'),
      description: I18n.t(
        'Determines visibility and management of Rubrics link in Account Navigation.'
      )
    },
    {
      description: I18n.t('Allows user to view the Rubrics link in Course Navigation.')
    },
    {
      description: I18n.t('Allows user to create, edit, and delete course rubrics.')
    }
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(
        'Users can access and create (but not edit) individual assignment rubrics through Assignments when Assignments and Quizzes - add / edit / delete is enabled.'
      )
    }
  ]
)

const pagesAddRemovePermissions = generateActionTemplates(
  'manage_wiki',
  [
    {
      title: I18n.t('Pages - create'),
      description: I18n.t('Allows user to create course pages.')
    },
    {
      title: I18n.t('Pages - delete'),
      description: I18n.t('Allows user to delete course pages.')
    },
    {
      title: I18n.t('Pages - update'),
      description: I18n.t('Allows user to edit course pages.')
    },
    {
      description: I18n.t('Allows user to define users allowed to edit the page.')
    },
    {
      description: I18n.t('Allows user to add page to student to-do list.')
    },
    {
      description: I18n.t('Allows user to publish and unpublish pages.')
    },
    {
      description: I18n.t('Allows user to view page history and set front page.')
    },
    {
      description: I18n.t(
        'Allows user to edit Blueprint Course lock settings in the Pages index page and for an individual page in a Blueprint master course.'
      )
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t('Blueprint courses must be enabled for an account by an admin.')
    },
    {
      description: I18n.t(
        'To edit lock settings on the Pages index page, Pages - update, Blueprint Courses - add / edit / associate / delete, and Manage Courses: Admin - manage / update.'
      )
    },
    {
      description: I18n.t(
        'However, if these additional permissions are enabled, but the Pages - update permission is not enabled, the user can still adjust content lock settings on individual pages in a Blueprint Master Course.'
      )
    },
    {
      title: I18n.t('Student Page History'),
      description: I18n.t(
        'Students can edit and view page history if allowed in the options for an individual page.'
      )
    }
  ],
  [
    {
      title: I18n.t('Pages - create'),
      description: I18n.t('Allows user to delete course pages.')
    },
    {
      description: I18n.t(
        'Allows user to edit Blueprint lock settings for individual pages in a Blueprint Master Course.'
      )
    },
    {
      title: I18n.t('Pages - delete'),
      description: I18n.t('Allows user to delete course pages.')
    },
    {
      description: I18n.t(
        'Allows user to edit Blueprint lock settings for individual pages in a Blueprint Master Course.'
      )
    },
    {
      title: I18n.t('Pages - update'),
      description: I18n.t('Allows user to edit course pages.')
    },
    {
      description: I18n.t('Allows user to define users allowed to edit the page.')
    },
    {
      description: I18n.t('Allows user to add page to student to-do list.')
    },
    {
      description: I18n.t('Allows user to publish and unpublish pages.')
    },
    {
      description: I18n.t('Allows user to view page history and set front page.')
    },
    {
      description: I18n.t(
        'Allows user to edit Blueprint lock settings in the Pages index page and for an individual page in a Blueprint master course.'
      )
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t('Blueprint courses must be enabled for an account by an admin.')
    },
    {
      description: I18n.t(
        'Course roles can only manage content in Blueprint Courses if they are added to the Blueprint Course as a teacher, TA, or designer role.'
      )
    },
    {
      description: I18n.t(
        'If the Pages - Update permission is disabled, the user can still adjust content lock settings on individual pages in a Blueprint Master Course.'
      )
    },
    {
      title: I18n.t('Student Page History'),
      description: I18n.t(
        'Students can edit and view page history if allowed in the options for an individual page.'
      )
    }
  ]
)

const discussionsModerateManagePermissions = generateActionTemplates(
  'moderate_forum',
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t('Allows user to view the New Announcement button in the Home page.')
    },
    {
      description: I18n.t('Allows user to add announcements in the Announcements page.')
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Allows user to edit Blueprint lock settings on the Discussions index page in a Blueprint master course.'
      )
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t('Allows user to add discussions in the Discussions page.')
    },
    {
      description: I18n.t(
        'Allows user to close for comments, move, pin and unpin, edit, and delete discussion topics created by other users.'
      )
    }
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t('To view announcements, Announcements - view must also be enabled.')
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'To edit lock settings on the Discussions index page, Manage Courses: Admin - manage / update and Discussions - view must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'If the additional permissions are enabled, but this permission is not enabled, lock settings can be edited on individual discussions.'
      )
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        'Both Discussions - create and Discussions - moderate allow the user to create a discussion in the Discussions page. If this permission is enabled, Discussions - create is not required.'
      )
    },
    {
      description: I18n.t('To view discussions in a course, Discussions - view must be enabled.')
    },
    {
      description: I18n.t('To reply to a discussion, Discussions - post must also be enabled.')
    },
    {
      description: I18n.t(
        'To edit assignment details on a discussion, Assignments and Quizzes - add / edit / delete must also be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t('Allows user to view the New Announcement button in the Home page.')
    },
    {
      description: I18n.t('Allows user to add announcements in the Announcements page.')
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Allows user to edit Blueprint lock settings on the Discussions index page in a Blueprint master course.'
      )
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t('Allows user to add discussions in the Discussions page.')
    },
    {
      description: I18n.t(
        'Allows user to close for comments, move, pin and unpin, edit, and delete discussion topics created by other users.'
      )
    }
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t('To view announcements, Announcements - view must also be enabled.')
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t('Blueprint courses must be enabled for an account by an admin.')
    },
    {
      description: I18n.t(
        'Course roles can only manage content in Blueprint Courses if they are added to the Blueprint Course as a teacher, TA, or designer role.'
      )
    },
    {
      description: I18n.t(
        'If this setting is disabled, and Discussions - view is enabled, the user can still adjust content lock settings on individual discussions in a Blueprint master course.'
      )
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        'Both Discussions - create and Discussions - moderate allow the user to create a discussion in the Discussions page. If this permission is enabled, Discussions - create is not required.'
      )
    },
    {
      description: I18n.t('To view discussions in a course, Discussions - view must be enabled.')
    },
    {
      description: I18n.t('To reply to a discussion, Discussions - post must also be enabled.')
    },
    {
      description: I18n.t(
        'To edit assignment details on a discussion, Assignments and Quizzes - add / edit / delete must also be enabled.'
      )
    }
  ]
)

const discussionPostPermissions = generateActionTemplates(
  'post_to_forum',
  [
    {
      title: I18n.t('Discussions'),
      description: I18n.t('Allows user to reply to a discussion post.')
    }
  ],
  [
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        'To view discussions in a course, Discussions - view must also be enabled.'
      )
    },
    {
      description: I18n.t('To manage discussions, Discussions - moderate must be enabled.')
    }
  ],
  [
    {
      title: I18n.t('Discussions'),
      description: I18n.t('Allows user to reply to a discussion post.')
    }
  ],
  [
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        'To view discussions in a course, Discussions - view must also be enabled.'
      )
    },
    {
      description: I18n.t('To manage discussions, Discussions - moderate must be enabled.')
    }
  ]
)

const announcementsViewPermissions = generateActionTemplates(
  'read_announcements',
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t('Allows user to view the Announcements link in Course Navigation.')
    },
    {
      title: I18n.t('Announcements'),
      description: I18n.t('Allows user to view course announcements.')
    }
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t(
        'To view recent announcements on the home page, Course content - view must be enabled, and the Show recent announcements on Course home page checkbox must be selected in Course Settings.'
      )
    },
    {
      description: I18n.t(
        'To manage course announcements, Discussions - moderate ​must also be enabled.'
      )
    },
    {
      title: I18n.t('Global Announcements'),
      description: I18n.t(
        'This permission only affects course announcements; to manage global announcements, Global Announcements - add / edit / delete​ must be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t('Allows user to access the Announcements link in Course Navigation.')
    },
    {
      description: I18n.t('Allows user to view course announcements.')
    },
    {
      description: I18n.t('Allows user to view recent announcements on the Course Home Page.')
    }
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t('To add announcements, Discussions - moderate must also be enabled.')
    },
    {
      description: I18n.t(
        'To view recent announcements on the home page, the Show recent announcements on Course home page checkbox must be selected in Course Settings.'
      )
    }
  ]
)

const usersViewEmailPermissions = generateActionTemplates(
  'read_email_addresses',
  [
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        'Allows user to search for account users via primary email address in the account People page.'
      )
    },
    {
      description: I18n.t(
        'Allows user to search for other users via primary email address in a course People page.'
      )
    }
  ],
  [
    {
      title: I18n.t('People (Account)'),
      description: I18n.t('To view the account People page, Users - view list must be enabled.')
    },
    {
      description: I18n.t(
        'If this permission is disabled, and Users - view login IDs is enabled, users will still see email addresses used as login IDs.'
      )
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        'Allows user to search for other users via primary email addresses in the People page.'
      )
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t('To access the People page, Users - view list must be enabled.')
    },
    {
      description: I18n.t(
        'If this permission is disabled, and Users - view login IDs is enabled, users will still see email addresses used as login IDs.'
      )
    }
  ]
)

const discussionViewPermissions = generateActionTemplates(
  'read_forum',
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Allows user to edit Blueprint content lock settings on individual discussions.'
      )
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t('Allows user to view the Discussions link in Course Navigation.')
    },
    {
      description: I18n.t('Allows user to view course discussions.')
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'To edit lock settings from the Discussions index page, Blueprint Courses - add / edit / associate / delete and Manage Courses: Admin - manage / update must also be enabled.'
      )
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t(
        'To share a discussion to Commons, Course Content - add / edit / delete must also be enabled.'
      )
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        'To manage discussions, Discussions - post and Discussions - moderate must also be enabled.'
      )
    },
    {
      description: I18n.t('To reply to a discussion, Discussions - post must also be enabled.')
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Allows user to edit Blueprint content lock settings on individual settings if the user is enrolled in a Blueprint master course.'
      )
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t('Allows user to view the Discussions link in Course Navigation.')
    },
    {
      description: I18n.t('Allows user to view course discussions.')
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t('Blueprint Courses must be enabled for an account by an admin.')
    },
    {
      description: I18n.t(
        'Course roles can only manage content in Blueprint Courses if they are added to the Blueprint Course with a teacher, TA, or designer role.'
      )
    },
    {
      description: I18n.t(
        'To edit Blueprint lock settings from the Discussions index page, Discussions - moderate must also be enabled.'
      )
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t(
        'To share a discussion to Commons, Course Content - add / edit / delete must also be enabled.'
      )
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t('To manage discussions, Discussions - moderate must also be enabled.')
    },
    {
      description: I18n.t('To reply to a discussion, Discussions - post must also be enabled.')
    }
  ]
)

const questionBankPermissions = generateActionTemplates(
  'read_question_banks',
  [
    {
      title: I18n.t('Question Banks'),
      description: I18n.t(
        'Allows user to view and link questions in a quiz to account-level question banks.'
      )
    }
  ],
  [
    {
      title: I18n.t('Quizzes and Question Banks'),
      description: I18n.t(
        'To access the Manage Question Banks link in a course Quizzes Index Page, Course content - view and Assignments and Quizzes - add / edit / delete must also be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('Question Banks'),
      description: I18n.t(
        'Allows user to view and link questions in a quiz to course-level question banks.'
      )
    },
    {
      description: I18n.t(
        'Allows user to access the Manage Question Banks link on the Quizzes Index Page.'
      )
    }
  ],
  [
    {
      title: I18n.t('Question Banks (Courses)'),
      description: I18n.t(
        'To fully manage course-level question banks, Assignments and Quizzes - add / edit / delete permission must also be enabled.'
      )
    }
  ]
)

const courseViewUsagePermissions = generateActionTemplates(
  'read_reports',
  [
    {
      title: I18n.t('Reports'),
      description: I18n.t('Allows user to view and configure reports in Account Settings.')
    },
    {
      description: I18n.t('Allows user to view Access Reports.')
    },
    {
      description: I18n.t(
        'Allows user to view last activity and total activity information on the People page.'
      )
    }
  ],
  [
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'To view Last Activity and Total Activity information on the Course People page, Users - view list must also be enabled.'
      )
    },
    {
      description: I18n.t('To access a Course People page, Users - view list must also be enabled.')
    },
    {
      title: I18n.t('Reports (Course)'),
      description: I18n.t(
        'To access the Student Interactions report, Grades - view all grades must also be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to view the Course Statistics button in Course Settings.')
    },
    {
      title: I18n.t('People'),
      description: I18n.t(
        'Allows user to view Last Activity and Total Activity information on the People page.'
      )
    },
    {
      title: I18n.t('Reports'),
      description: I18n.t('Allows user to view Last Activity and Total Activity reports.')
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t('To access the People Page, Users - view list must be enabled.')
    },
    {
      title: I18n.t('Reports'),
      description: I18n.t(
        'To access the Student Interactions report, Grades - view all grades must also be enabled.'
      )
    }
  ]
)

const usersViewListPermissions = generateActionTemplates(
  'read_roster',
  [
    {
      title: I18n.t('Account Navigation'),
      description: I18n.t('Allows user to access the People link in Account Navigation.')
    },
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t('Allows user to view login/logout activity of users in Admin Tools.')
    },
    {
      description: I18n.t(
        'Allows user to search grade change logs by grader or student in Admin Tools.'
      )
    },
    {
      title: I18n.t('Assignments'),
      description: I18n.t('Allows user to differentiate assignments to individual students.')
    },
    {
      title: I18n.t('Collaborations'),
      description: I18n.t('Allows user to view and add users in a collaboration.')
    },
    {
      title: I18n.t('Conversations'),
      description: I18n.t(
        'Allows user to send a message in Conversations without selecting a course.'
      )
    },
    {
      title: I18n.t('Course Navigation'),
      description: I18n.t('Allows user to view the People link in Course Navigation.')
    },
    {
      title: I18n.t('Groups (Course)'),
      description: I18n.t('Allows user to view groups in a course.')
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t('Allows user to view list of users in the account.')
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t('Allows user to view list of users in the course People page.')
    },
    {
      description: I18n.t(
        'Allows user to view the Prior Enrollments button in the course People page.'
      )
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t('Not available at the subaccount level.')
    }
  ],
  [
    {
      title: I18n.t('Account Groups'),
      description: I18n.t(
        'To view account-level groups, Groups - add / edit / delete must also be enabled.'
      )
    },
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(
        'To generate login/logout activity in Admin Tools, Users - manage login details or Statistics - view must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To generate grade change logs in Admin Tools, Grades - view change logs must also be enabled.'
      )
    },
    {
      title: I18n.t('Courses'),
      description: I18n.t(
        'To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).'
      )
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        'To edit user details, modify login details, or change user passwords, Users - manage login details must also be enabled.'
      )
    },
    {
      description: I18n.t('To view user page views, Statistics - view must also be enabled.')
    },
    {
      description: I18n.t('To act as other users, Users - act as must also be enabled.')
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'To edit a user’s section, the appropriate Users permission (e.g. Users - Teachers), Users - allow administrative actions in courses, and Conversations - send to individual course members must also be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t('Allows user to differentiate assignments to individual students.')
    },
    {
      title: I18n.t('Collaborations'),
      description: I18n.t('Allows user to view and add users in a collaboration.')
    },
    {
      title: I18n.t('Course'),
      description: I18n.t('Navigation Allows user to view the People link in Course Navigation.')
    },
    {
      title: I18n.t('Groups'),
      description: I18n.t('Allows user to view groups in a course.')
    },
    {
      title: I18n.t('People'),
      description: I18n.t('Allows user to view list of users in the course People page.')
    },
    {
      description: I18n.t(
        'Allows user to view the Prior Enrollments button in the course People page.'
      )
    },
    {
      title: I18n.t('Settings'),
      description: I18n.t('Allows user to view enrollments on the Sections tab.')
    }
  ],
  [
    {
      title: I18n.t('Conversations'),
      description: I18n.t(
        'To send a message to an individual user, Conversations - send messages to individual course members must also be enabled.'
      )
    },
    {
      title: I18n.t('Groups'),
      description: I18n.t(
        'To add, edit, or delete groups, Groups - add / edit / delete must also be enabled.'
      )
    },
    {
      title: I18n.t('People'),
      description: I18n.t(
        'To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).'
      )
    },
    {
      description: I18n.t(
        'To edit a user’s section, Users - allow administrative actions in courses and Users - view list must also be enabled.'
      )
    }
  ]
)

const sisDataReadPermissions = generateActionTemplates(
  'read_sis',
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to view a course’s SIS ID.')
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t('Allows user to view the SIS ID in a user’s login details.')
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t('Allows user to view user SIS IDs in a course People page.')
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        'Allows user to view the user SIS ID column in the Quiz Item Analysis CSV file.'
      )
    },
    {
      title: I18n.t('SIS'),
      description: I18n.t('Governs account-related SIS IDs (i.e., subaccount SIS ID).')
    }
  ],
  [
    {
      title: I18n.t('Account and Subaccount'),
      description: I18n.t(
        'Users and terms are located at the account, so the SIS endpoint always confirms the user’s permissions according to account.'
      )
    },
    {
      description: I18n.t(
        'Subaccounts only have ownership of courses and sections; they do not own user data. Subaccount admins are not able to view SIS information unless they are also granted an instructor role in a course.'
      )
    },
    {
      description: I18n.t(
        'Subaccount admins are not able to view SIS information unless they are also granted an instructor role in a course.'
      )
    },
    {
      description: I18n.t(
        'Subaccount admins cannot view SIS information without the course association, as the instructor role has permission to read SIS data at the account level.'
      )
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        'To view a user’s login details, Users - view list and Modify login details for users must also both be enabled.'
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).'
      )
    },
    {
      title: I18n.t('SIS Import'),
      description: I18n.t('To manage SIS data, SIS Data - manage must be enabled.')
    },
    {
      description: I18n.t(
        'If SIS Data - manage is enabled and SIS Data - read is disabled, the account permission overrides the course permission.'
      )
    },
    {
      description: I18n.t(
        'If SIS Data - manage is disabled and SIS Data - read is enabled, users can only view course, user, and subaccount SIS IDs.'
      )
    },
    {
      description: I18n.t(
        'To disallow users from viewing any SIS IDs at the course level, SIS Data - manage and SIS Data - read must both be disabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to view course SIS ID.')
    },
    {
      title: I18n.t('People'),
      description: I18n.t('Allows user to view user SIS IDs.')
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        'Allows user to view the user SIS ID column in the Quiz Item Analysis CSV file.'
      )
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        'To view the list of users in the course, Users - view list must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To add or remove users to a course via SIS, the appropriate Users permission must be enabled (e.g. Users - Teachers).'
      )
    }
  ]
)

const finalGradePermissions = generateActionTemplates(
  'select_final_grade',
  [
    {
      title: I18n.t('Grades'),
      description: I18n.t('Allows user to select final grade for moderated assignments.')
    }
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(
        'To add students to a moderation set, Grades - view all grades must also be enabled.'
      )
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        'To publish final grades for a moderated assignment, Grades - edit must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To post or hide grades for a moderated assignment, Grades - edit must also be enabled.'
      )
    },
    {
      title: I18n.t('SpeedGrader'),
      description: I18n.t(
        'To review a moderated assignment in SpeedGrader, Grades - edit must also be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('Grades'),
      description: I18n.t('Allows user to select final grade for moderated assignments.')
    }
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(
        'To add students to a moderation set, Grades - view all grades must also be enabled.'
      )
    },
    {
      title: I18n.t('SpeedGrader'),
      description: I18n.t(
        'To review a moderated assignment in SpeedGrader, Grades - edit must also be enabled.'
      )
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        'To publish final grades for a moderated assignment, Grades - edit must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To post or hide grades for a moderated assignment, Grades - edit must also be enabled.'
      )
    }
  ]
)

const messagesSentPermissions = generateActionTemplates(
  'send_messages',
  [
    {
      title: I18n.t('Conversations'),
      description: I18n.t('Allows user to send messages to individual course members.')
    }
  ],
  [
    {
      title: I18n.t('Conversations'),
      description: I18n.t(
        'When disabled, students can still send individual messages to course teachers, course TAs, and students who belong to the same account-level groups.'
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'To edit a user’s section, Users - allow administrative actions in courses and Users - view list must also be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('Conversations'),
      description: I18n.t('Allows user to send messages to individual course members.')
    }
  ],
  [
    {
      title: I18n.t('Conversations'),
      description: I18n.t(
        'When disabled, students can still send individual messages to course teachers, course TAs, and students that belong to the same account-level groups.'
      )
    },
    {
      title: I18n.t('People'),
      description: I18n.t(
        'To edit a user’s section, Users - allow administrative actions in courses and Users - view list must also be enabled. '
      )
    }
  ]
)

const messagesSentEntireClassPermissions = generateActionTemplates(
  'send_messages_all',
  [
    {
      title: I18n.t('Conversations'),
      description: I18n.t(
        'Allows user to send a message to “All in [course name]” or "All in [course group]".'
      )
    }
  ],
  [],
  [
    {
      title: I18n.t('Conversations'),
      description: I18n.t(
        'Allows user to send a message to “All in [course name],” or “All in [course group].”'
      )
    }
  ],
  []
)

const gradesViewAllPermissions = generateActionTemplates(
  'view_all_grades',
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t('Allows user to search by assignment ID in grade change logs.')
    },
    {
      title: I18n.t('Analytics'),
      description: I18n.t('Allows user to view student-specific data in Analytics.')
    },
    {
      title: I18n.t('Assignments, SpeedGrader'),
      description: I18n.t('Allows user to view a link to SpeedGrader from assignments.')
    },
    {
      title: I18n.t('Gradebook'),
      description: I18n.t(
        'Allows user to export the Gradebook to a comma separated values (CSV) file.'
      )
    },
    {
      description: I18n.t('Allows user to access the Learning Mastery Gradebook (if enabled).')
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t('Allows user to view student Grades pages.')
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t('Allows user to access the Student Progress page.')
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t('Allows user to view analytics link in the user settings menu.')
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        'Allows user to view student results, view quiz statistics, and access a quiz in SpeedGrader.'
      )
    },
    {
      title: I18n.t('Rubrics, SpeedGrader'),
      description: I18n.t('Allows user to view grader comments on a rubric in SpeedGrader.')
    },
    {
      title: I18n.t('Student Context Card'),
      description: I18n.t('Adds analytics to a student’s context card.')
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Grade Change Logs)'),
      description: I18n.t(
        'To search grade change logs, Grades - view change logs must also be enabled.'
      )
    },
    {
      title: I18n.t('Analytics'),
      description: I18n.t('To view student analytics, Analytics - view must also be enabled.')
    },
    {
      title: I18n.t('Gradebook'),
      description: I18n.t('To view the Gradebook, Course Content - view must also be enabled.')
    },
    {
      description: I18n.t(
        'If both Grades - edit and Grades - view all grades are disabled, Gradebook will be hidden from Course Navigation.'
      )
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t('To post or hide grades, Grades - edit must also be enabled.')
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(
        'To view module progression, Grades - view all grades must also be enabled.'
      )
    },
    {
      title: I18n.t('Reports'),
      description: I18n.t(
        'To access the Student Interactions report, Courses - view usage reports must also be enabled.'
      )
    },
    {
      title: I18n.t('Student Context Card'),
      description: I18n.t('Student Context Cards must be enabled for an account by an admin.')
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t('Not available at the subaccount level.')
    }
  ],
  [
    {
      title: I18n.t('Analytics'),
      description: I18n.t('Allows user to view student-specific data in Analytics.')
    },
    {
      title: I18n.t('Assignments, SpeedGrader'),
      description: I18n.t('Allows user to access SpeedGrader from an assignment.')
    },
    {
      title: I18n.t('Gradebook'),
      description: I18n.t('Allows user to view Gradebook.')
    },
    {
      description: I18n.t(
        'Allows user to export the Gradebook to a comma separated values (CSV) file.'
      )
    },
    {
      description: I18n.t('Allows user to access the Learning Mastery Gradebook (if enabled).')
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t('Allows user to view student Grades pages.')
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t('Allows user to access the Student Progress page.')
    },
    {
      title: I18n.t('People'),
      description: I18n.t('Adds analytics link on the user settings menu.')
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        'Allows user to view student results, view quiz statistics, and access a quiz in SpeedGrader.'
      )
    },
    {
      title: I18n.t('Rubrics, SpeedGrader'),
      description: I18n.t('Allows user to view grader comments on a rubric in SpeedGrader.')
    },
    {
      title: I18n.t('Student Context Card'),
      description: I18n.t('Adds analytics to a student’s context card.')
    }
  ],
  [
    {
      title: I18n.t('Analytics'),
      description: I18n.t('To view student analytics, Analytics - view must also be enabled.')
    },
    {
      title: I18n.t('Gradebook'),
      description: I18n.t(
        'If both Grades - edit and Grades - view all grades are disabled, Gradebook will be hidden from Course Navigation.'
      )
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t('To post or hide grades, Grades - edit must also be enabled.')
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(
        'To view module progression, Grades - view all grades must also be enabled.'
      )
    },
    {
      title: I18n.t('Reports'),
      description: I18n.t(
        'To access the Student Interactions report, Courses - view usage reports must also be enabled.'
      )
    },
    {
      title: I18n.t('Student Context Card'),
      description: I18n.t('Student Context Cards must be enabled for an account by an admin.')
    }
  ]
)

const analyticsViewPermissions = generateActionTemplates(
  'view_analytics',
  [
    {
      title: I18n.t('Analytics (Account)'),
      description: I18n.t('Allows user to view account analytics.')
    },
    {
      title: I18n.t('Analytics (Course)'),
      description: I18n.t('Allows user to view course analytics through the course dashboard.')
    },
    {
      description: I18n.t('Allows user to view student analytics.')
    }
  ],
  [
    {
      title: I18n.t('Analytics'),
      description: I18n.t(
        'To view student analytics in course analytics, Grades - view all grades must also be enabled.'
      )
    },
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(
        'The analytics feature must be enabled in Account Settings to view analytics pages.'
      )
    },
    {
      description: I18n.t(
        'To see the Analytics link in the user sidebar from the People page, Profiles must be disabled in your account.'
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'To view student analytics, Users - view list and Grades - view all grades​ must also be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('Analytics'),
      description: I18n.t(
        'Allows user to view course and student analytics from the Course Home Page or People page.'
      )
    }
  ],
  [
    {
      title: I18n.t('Analytics'),
      description: I18n.t(
        'To view student analytics in course analytics, Grades - view all grades must also be enabled'
      )
    },
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(
        'The analytics feature must be enabled in Account Settings to view analytics pages.'
      )
    },
    {
      description: I18n.t(
        'To see the Analytics link in the user sidebar from the People page, Profiles must be disabled in your account.'
      )
    },
    {
      title: I18n.t('People'),
      description: I18n.t(
        'To view student analytics, Users - view list and Grades - view all grades​ must also be enabled.'
      )
    }
  ]
)

const gradeAuditTrailPermissions = generateActionTemplates(
  'view_audit_trail',
  [
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        'Allows user to review an audit trail in assignments, both moderated and anonymous.'
      )
    }
  ],
  [
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        'To moderate grades, Grades - Select final grade for moderation must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To post or hide grades for an assignment, Grades - edit must also be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        'Allows user to review an audit trail in assignments, both moderated and anonymous.'
      )
    }
  ],
  [
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        'To moderate grades, Grades - Select final grade for moderation must also be enabled.'
      )
    },
    {
      description: I18n.t(
        'To post or hide grades for an assignment, Grades - edit must also be enabled.'
      )
    }
  ]
)

const groupsViewAllStudentPermissions = generateActionTemplates(
  'view_group_pages',
  [
    {
      title: I18n.t('Groups'),
      description: I18n.t('Allows user to view the group home pages of all student groups.')
    },
    {
      description: I18n.t(
        'Allows students to access other student groups within a group set with a direct link.'
      )
    }
  ],
  [
    {
      title: I18n.t('Groups'),
      description: I18n.t(
        'By default students are able to create groups; to restrict students from creating groups, do not select the Let students organize their own groups checkbox in Course Settings.'
      )
    }
  ],
  [
    {
      title: I18n.t('Groups'),
      description: I18n.t('Allows user to view the group home pages of all student groups.')
    },
    {
      description: I18n.t(
        'Allows students to access other student groups within a group set with a direct link.'
      )
    }
  ],
  [
    {
      title: I18n.t('Groups'),
      description: I18n.t(
        'By default students are able to create groups; to restrict students from creating groups, do not select the Let students organize their own groups checkbox in Course Settings.'
      )
    }
  ]
)

const usersViewLoginPermissions = generateActionTemplates(
  'view_user_logins',
  [
    {
      title: I18n.t('People (Account, Course)'),
      description: I18n.t(
        'Allows user to search for other users by Login ID in the account People page.'
      )
    }
  ],
  [
    {
      title: I18n.t('People (Account, Course)'),
      description: I18n.t('To access the People page, Users - view list must be enabled.')
    },
    {
      description: I18n.t(
        'If this permission is enabled, and if Users - view primary email address is disabled, users will see email addresses used as login IDs.'
      )
    },
    {
      description: I18n.t(
        'To view login IDs, Users - allow administrative actions in courses must also be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        'Allows user to search for other users by Login ID in the course People page.'
      )
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t('To access the People page, Users - view list must be enabled.')
    },
    {
      description: I18n.t(
        'If this permission is enabled, and if Users - view primary email address is disabled, users will see email addresses used as login IDs.'
      )
    },
    {
      description: I18n.t(
        'To view login IDs, Users - allow administrative actions in courses must also be enabled.'
      )
    }
  ]
)

export const PERMISSION_DETAILS_ACCOUNT_TEMPLATES = {
  ...deepMergeAll([
    accountLevelPermissions.ACCOUNT,
    adminsLevelPermissions.ACCOUNT,
    allowCourseAdminActions.ACCOUNT,
    alertPermissions.ACCOUNT,
    analyticsViewPermissions.ACCOUNT,
    announcementsViewPermissions.ACCOUNT,
    assignmentsQuizzesPermissions.ACCOUNT,
    assignmentsAndQuizzes.ACCOUNT,
    blueprintCoursePermissions.ACCOUNT,
    courseCalenderPermissions.ACCOUNT,
    courseContentAddPermissions.ACCOUNT,
    courseContentViewPermissions.ACCOUNT,
    courseFilesAddPermissions.ACCOUNT,
    courseListViewPermissions.ACCOUNT,
    courseManagePermissions.ACCOUNT,
    courseSectionsViewPermissions.ACCOUNT,
    courseTemplatesPermissions.ACCOUNT,
    courseUndeletePermissions.ACCOUNT,
    courseViewChangePermissions.ACCOUNT,
    courseViewUsagePermissions.ACCOUNT,
    courseVisibilityPermissions.ACCOUNT,
    developerKeysManagePermissions.ACCOUNT,
    discussionscreatePermissions.ACCOUNT,
    discussionsModerateManagePermissions.ACCOUNT,
    discussionPostPermissions.ACCOUNT,
    discussionViewPermissions.ACCOUNT,
    featureFlagsManagePermissions.ACCOUNT,
    featureFlagsViewPermissions.ACCOUNT,
    finalGradePermissions.ACCOUNT,
    globalAnnouncementsPermissions.ACCOUNT,
    gradeAuditTrailPermissions.ACCOUNT,
    gradesEditPermissions.ACCOUNT,
    gradesViewAllPermissions.ACCOUNT,
    gradesViewChangeLogPermissions.ACCOUNT,
    gradesAddEditDeletePermissions.ACCOUNT,
    groupsViewAllStudentPermissions.ACCOUNT,
    learningOutcomesAddEditDeletePermissions.ACCOUNT,
    learningOutcomesImportPermissions.ACCOUNT,
    ltiAddEditPermissions.ACCOUNT,
    managePermissions.ACCOUNT,
    manageStudentsCoursesPermissions.ACCOUNT,
    messagesSentPermissions.ACCOUNT,
    messagesSentEntireClassPermissions.ACCOUNT,
    notificationsPermissions.ACCOUNT,
    outcomeProficiencyCalculationsAddEditDeletePermissions.ACCOUNT,
    outcomeProficiencyScalesAddEditDeletePermissions.ACCOUNT,
    pagesAddRemovePermissions.ACCOUNT,
    pairingCodePermissions.ACCOUNT,
    permissionsDesigner.ACCOUNT,
    permissionsTA.Account,
    permissionsObserver.ACCOUNT,
    permissionsTeacher.ACCOUNT,
    permissionsStudent.ACCOUNT,
    questionBankPermissions.ACCOUNT,
    rubricsAddPermissions.ACCOUNT,
    sisDataImportPermissions.ACCOUNT,
    sisDataManagePermissions.ACCOUNT,
    sisDataReadPermissions.ACCOUNT,
    viewStatisticsPermissions.ACCOUNT,
    storageQuotasPermissions.ACCOUNT,
    studentCollabPermissions.ACCOUNT,
    usernotesPermissions.ACCOUNT,
    usersActAsPermissions.ACCOUNT,
    usersManageLoginPermissions.ACCOUNT,
    usersModerateUserContentPermissions.ACCOUNT,
    usersObserverPermissions.ACCOUNT,
    usersViewLoginPermissions.ACCOUNT,
    usersViewListPermissions.ACCOUNT,
    usersViewEmailPermissions.ACCOUNT,
    webConferencesPermissions.ACCOUNT
  ])
}

export const PERMISSION_DETAILS_COURSE_TEMPLATES = {
  ...deepMergeAll([
    accountLevelPermissions.COURSE,
    adminsLevelPermissions.COURSE,
    alertPermissions.COURSE,
    allowCourseAdminActions.COURSE,
    analyticsViewPermissions.COURSE,
    announcementsViewPermissions.COURSE,
    assignmentsAndQuizzes.COURSE,
    assignmentsQuizzesPermissions.COURSE,
    blueprintCoursePermissions.COURSE,
    courseUndeletePermissions.COURSE,
    courseViewChangePermissions.COURSE,
    courseViewUsagePermissions.COURSE,
    courseCalenderPermissions.COURSE,
    courseContentAddPermissions.COURSE,
    courseContentViewPermissions.COURSE,
    courseFilesAddPermissions.COURSE,
    courseListViewPermissions.COURSE,
    courseManagePermissions.COURSE,
    courseSectionsViewPermissions.COURSE,
    courseTemplatesPermissions.COURSE,
    courseVisibilityPermissions.COURSE,
    developerKeysManagePermissions.COURSE,
    discussionscreatePermissions.COURSE,
    discussionsModerateManagePermissions.COURSE,
    discussionPostPermissions.COURSE,
    discussionViewPermissions.COURSE,
    featureFlagsManagePermissions.COURSE,
    featureFlagsViewPermissions.COURSE,
    finalGradePermissions.COURSE,
    globalAnnouncementsPermissions.COURSE,
    gradeAuditTrailPermissions.COURSE,
    gradesEditPermissions.COURSE,
    gradesViewAllPermissions.COURSE,
    gradesViewChangeLogPermissions.COURSE,
    gradesAddEditDeletePermissions.COURSE,
    groupsViewAllStudentPermissions.COURSE,
    learningOutcomesAddEditDeletePermissions.COURSE,
    learningOutcomesImportPermissions.COURSE,
    ltiAddEditPermissions.COURSE,
    manageStudentsCoursesPermissions.COURSE,
    messagesSentPermissions.COURSE,
    messagesSentEntireClassPermissions.COURSE,
    pagesAddRemovePermissions.COURSE,
    pairingCodePermissions.COURSE,
    permissionsDesigner.COURSE,
    permissionsTA.COURSE,
    permissionsObserver.COURSE,
    permissionsTeacher.COURSE,
    permissionsStudent.COURSE,
    outcomeProficiencyCalculationsAddEditDeletePermissions.COURSE,
    outcomeProficiencyScalesAddEditDeletePermissions.COURSE,
    questionBankPermissions.COURSE,
    rubricsAddPermissions.COURSE,
    sisDataImportPermissions.COURSE,
    sisDataManagePermissions.COURSE,
    sisDataReadPermissions.COURSE,
    storageQuotasPermissions.COURSE,
    studentCollabPermissions.COURSE,
    usernotesPermissions.COURSE,
    usersActAsPermissions.COURSE,
    usersManageLoginPermissions.COURSE,
    usersViewLoginPermissions.COURSE,
    usersViewListPermissions.COURSE,
    usersViewEmailPermissions.COURSE,
    viewStatisticsPermissions.COURSE,
    webConferencesPermissions.COURSE
  ])
}
