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

/* eslint-disable */
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
  {title: 'What it Does', key: 'what_it_does'},
  {title: 'Additional Considerations', key: 'additional_considerations'}
]

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
      description: I18n.t('Allows user to view and manage authentication options for the whole account.')
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
        'The Announcements tab is always visible to admins; however, to manage announcements, Global Announcements - add / edit / delete​ must also be enabled.'
      )
    },
    {
      title: I18n.t('Reports (Account Settings)'),
      description: I18n.t(
        'To view the Reports tab, Courses - view usage reports must also be enabled.'
      )
    },
    {
      title: I18n.t('Account Settings (Subaccount Navigation)'),
      description: I18n.t(
        'Not all settings options are available at the subaccount level, including the Notifications tab.'
      )
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
      description: I18n.t(
        'Allows user to access and edit the Admin settings in Commons. Allows user to create and manage Groups. Allows user to manage shared resources in the account.'
      )
    }
  ],
  [],
  [],
  []
)

const blueprintCoursePermissions = generateActionTemplates(
  'manage_master_courses',
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(`Allows user to designate a course as a Blueprint Course.
Allows user to manage Blueprint Course settings in Course Settings.
Allows user to add associated courses.`)
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Blueprint Courses is an account-level feature option. Course roles can only manage Blueprint Courses if they are added to the Blueprint Course as an teacher, TA, or designer role. To access the Blueprint Courses sidebar, Courses - add / edit / delete courses must be enabled. To add an associated course, Courses - view list a​nd Courses - add / edit / delete must also be enabled. To edit lock settings on any blueprint object type, Courses - add / edit / delete must be enabled.'
      )
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'To manage Blueprint Course settings in Course Settings, Courses - add / edit / delete must also be enabled.'
      )
    }
  ],
  [],
  []
)

const courseAddDeletePermissions = generateActionTemplates(
  'manage_courses',
  [
    {
      title: I18n.t('Admin Tools (Restore Courses tab)'),
      description: I18n.t('Allows user to restore a course.')
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Allows user to access the Blueprint Courses Sidebar. Allows user to manage Blueprint Courses content settings in Course Settings. Allows user to remove an associated course. Allows user to edit blueprint lock settings on individual assignments, pages, or discussions'
      )
    },
    {
      title: I18n.t('Courses (Account Navigation)'),
      description: I18n.t('Allows user to view and manage courses in the account.')
    },
    {
      title: I18n.t('Course Settings (Course Details tab)'),
      description: I18n.t(
        'Course Settings (Course Details tab): Allows user to access the Navigation tab in Course Settings. Allows user to access Student View (test student), Copy this Course, Reset Course Content, and Permanently Delete Course buttons. Allows user to edit course image, name, course code, time zone, subaccount, term, and other options in Course Details tab.'
      )
    },
    {
      title: I18n.t('Courses'),
      description: I18n.t(
        'Allows user to view Choose Home Page and Course Setup Checklist buttons in the Home page.'
      )
    },
    {
      title: I18n.t('Course Setup Checklist'),
      description: I18n.t(
        'Determines whether the Course Setup Checklist option is included in the Course Home page.'
      )
    },
    {
      title: I18n.t('Student Context Cards'),
      description: I18n.t(
        'Allows user to view student context cards in announcement and discussion replies.'
      )
    }
  ],
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(
        'If this permission is enabled and Courses - view list is disabled, users can add a new course with the Add a New Course button in Account Settings.'
      )
    },
    {
      title: I18n.t('Admin Tools (Restore Courses tab)'),
      description: I18n.t(
        'To restore a deleted course, Courses - undelete​ and Course Content - view must also both be enabled.'
      )
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Blueprint Courses is an account-level feature option. To edit Blueprint course settings in Course Settings, Blueprint Courses - add / edit / associate / delete​ must also be enabled. To add an associated course, Blueprint Courses - add / edit / associate / delete and Courses - view list must also be enabled. To edit lock settings on any blueprint object, this permission must be enabled. To edit lock settings on files, Course Files - add / edit / delete must also be enabled. To edit lock settings on quizzes, Assignments and Quizzes - add / edit / delete must also be enabled.'
      )
    },
    {
      title: I18n.t('Courses (Account Navigation)'),
      description: I18n.t(
        'To cross-list a section, Course Sections - add / edit / delete ​must also be enabled. To edit the course SIS ID, SIS Data - manage​ must also be enabled. To allow an account-level user to delete a course, Course State - manage​ must also be enabled.'
      )
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'To cross-list a section, Course Sections - add / edit / delete must also be enabled. To edit the course SIS ID, SIS Data - manage must also be enabled. To allow an account-level user to delete a course, Course State - manage must also be enabled.'
      )
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        'To view grades in a course, Grades - view all grades​ must also be enabled.'
      )
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(
        'To publish/unpublish module content, Course Content - add / edit / delete​ must be enabled.'
      )
    },
    {
      title: I18n.t('Student Context Cards'),
      description: I18n.t(
        'Student context cards must be enabled for an account by an admin. If this permission is not enabled, users can still view student context cards through the Gradebook.'
      )
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
      description: I18n.t(`Allows user to filter for blueprint courses as the account level.
Allows user to add associated courses.`)
    },
    {
  title: I18n.t('Courses'),
  description: I18n.t(`Allows user to see the list of courses in the account.`)
    }
  ],
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(`If this permission is disabled and Courses - add / edit / delete​ is enabled,
users can add a new course with the Add a New Course button in Account
Settings.`)
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(`Blueprint Courses is an account-level feature option.

To add associated courses, Blueprint Courses - add / edit / associate / delete and Courses - add / edit / delete​ must also be enabled.`)
    },
    {
      title: I18n.t('Statistics'),
      description: I18n.t(
        `Allows user to see the list of recently started/ended courses in account statistics.`
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
      description: I18n.t(`Allows user to create developer keys for accounts.`)
    }
  ],
  [
    {
      title: I18n.t('Developer Keys'),
      description: I18n.t(
        `Required fields include key name, owner email, tool ID, redirect URL, and icon URL.`
      )
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t(`Not available at the subaccount level.`)
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
      description: I18n.t(`Allows user to add, edit, and delete global announcements.`)
    }
  ],
  [],
  [],
  []
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
      description: I18n.t(
        'Allows user to view course analytics through the course dashboard. Allows user to view student analytics.'
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
      description: I18n.t(`The analytics feature must be enabled in Account Settings to view analytics pages.
To see the Analytics link in the user sidebar from the People page, Profiles must be disabled in your account.`)
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
      description: I18n.t(`The analytics feature must be enabled in Account Settings to view analytics pages.
To see the Analytics link in the user sidebar from the People page, Profiles must be disabled in your account.
`)
    },
    {
      title: I18n.t('People'),
      description: I18n.t(
        'To view student analytics, Users - view list and Grades - view all grades​ must also be enabled.'
      )
    }
  ]
)

const managePermissions = generateActionTemplates(
  'manage_role_overrides',
  [
    {
      title: I18n.t('Permissions'),
      description: I18n.t(`Allows user to view and manage permissions.`)
    }
  ],
  [],
  [],
  []
)

const sisDataImportPermissions = generateActionTemplates(
  'import_sis',
  [
    {
      title: I18n.t('Account Navigation'),
      description: I18n.t(
        `Determines visibility and management of SIS Import tab in account navigation.`
      )
    },
    {
      title: I18n.t('SIS Import'),
      description: I18n.t(`Allows user to import SIS data.`)
    }
  ],
  [
    {
      title: I18n.t('SIS Import'),
      description: I18n.t(`To manage SIS data, SIS Data - manage​ must also be enabled.`)
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t(`Not available at the subaccount level`)
    }
  ],
  [],
  []
)

const sisDataManagePermissions = generateActionTemplates(
  'manage_sis',
  [
    {
      title: I18n.t('Account Navigation'),
      description: I18n.t(`Determines visibility of SIS Import tab in account navigation.
Allows user to view the previous SIS import dates, errors, and imported items.`)
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to edit the course SIS ID.')
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        'Allows user to view and edit the SIS ID and Integration ID in a user’s Login Details'
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
      description: I18n.t(`To edit course settings, Courses - add / edit / delete​ must be enabled.`)
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        `To view or edit a user’s SIS ID or Integration ID, Users - view list​ and Users - manage login details must also both be enabled.`
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(`If this permission is enabled, users do not need the SIS Data - read permission enabled. The account permission overrides the course permission. To disallow users from managing SIS IDs at the course level, SIS Data - manage​ and SIS Data - read must both be disabled.
To add users to courses via SIS ID, Users - add / remove students from courses and/or Users - add / remove teachers, course designers, or TAs from courses​ must also be enabled.`)
    },
    {
      title: I18n.t('SIS Import'),
      description: I18n.t(`To import SIS data, SIS Data - import​ must also be enabled.`)
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t(`Not available at the subaccount level.`)
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
      description: I18n.t(`Allows admin user to view account statistics.`)
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
        `If Statistics - view​ or Users - manage login details is enabled, a user will be able to generate login/logout activity in Admin Tools. To hide the login/logout activity option in Admin Tools, both of these permissions need to be disabled.`
      )
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(`To view user page views, Users - view list ​ must also be enabled.`)
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
        `Allows user to view and manage Quotas tab in account settings. User can set default course, user, and group storage quotes.`
      )
    }
  ],
  [],
  [],
  []
)

const usersActAsPermissions = generateActionTemplates(
  'become_user',
  [
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(`Allows user to act as other users in the account.`)
    },
    {
      title: I18n.t('Student Context Card'),
      description: I18n.t(`Allows a user to access the Act as User link on student context cards`)
    }
  ],
  [
    {
      title: I18n.t('API'),
      description: I18n.t(`Allows user to view Login IDs in a course People page.`)
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        `To view the list of users in an account, Users - view list​ must be enabled.`
      )
    },
    {
      title: I18n.t('Student Context Card'),
      description: I18n.t(`Student Context Cards must be enabled for an account by an admin.`)
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t(`Not available at the subaccount level.`)
    }
  ],
  [
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(`Allows user to act as other users in the account.`)
    },
    {
      title: I18n.t('Student Context Card'),
      description: I18n.t(`Allows a user to access the Act as User link on student context cards`)
    }
  ],
  [
    {
      title: I18n.t('API'),
      description: I18n.t(`The Roles API refers to this permission as become_user.`)
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        `To view the list of users in an account, Users - view list  must be enabled.`
      )
    },
    {
      title: I18n.t('Student Context Card'),
      description: I18n.t(`Student Context Cards must be enabled for an account by an admin.`)
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t(`Not available at the subaccount level.`)
    }
  ]
)

const usersObserverPermissions = generateActionTemplates(
  'manage_user_observers',
  [
    {
      title: I18n.t('People'),
      description: I18n.t(`Allows user to manage observers associated with students in the account.`)
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
      description: I18n.t(`Allows user to create accounts for new users with the account-level Add People button.
Allows user to remove and merge users in an account.
Allows user to modify user account details such as name, email, and time zone. Allows user to view and modify login information for a user.`)
    },
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(`Allows user to generate login/logout activity report in Admin Tools.`)
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(
        `If Users - manage login details or Statistics - view​ is enabled, a user will be able to generate login/logout activity in Admin Tools. To hide the login/logout activity option in Admin Tools, both of these permissions need to be disabled.`
      )
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(`To view users and user account details, Users - view list​ must be enabled.
To change user passwords, Users - view list must also be enabled.
To view a user’s SIS ID, SIS Data - manage​ or SIS Data - read must also be
enabled. To view a user’s Integration ID, SIS Data - manage​ must also be enabled.`)
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(`This permission only controls adding users at the account level. To add users
to a course, Users - add / remove students from courses or Users - add / remove teachers, course designers, or TAs from courses to the course​ must be enabled.`)
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t(`Not available at the subaccount level.`)
    }
  ],
  [],
  []
)

const webHooksPermissions = generateActionTemplates(
  'manage_webhooks',
  [
    {
      title: I18n.t('Canvas Catalog'),
      description: I18n.t(`Placeholder for webhooks access in Canvas Catalog.`)
    }
  ],
  [
    {
      title: I18n.t('Canvas Catalog'),
      description: I18n.t(
        `This permission is available for all Canvas accounts but only in use for institutions associated with a Canvas Catalog account. Permission currently has no front-end effects, but engineering suggests the permission remain enabled for admins. For other roles the permission can be disabled.`
      )
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
      description: I18n.t('Allows user to access the Restore Courses tab in Admin Too')
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Restore Courses tab)'),
      description: I18n.t(`To search for a course in the Restore Courses tab, Course Content - view must also be enabled.
         To restore a deleted course in an account, Courses - add / edit / delete​, Course Content - view, and Courses - undelete​ must all be enabled.`)
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
        'Determines visibility of the Course Activity option in the Admin Tools Logging tab. Allows user to view course activity information for the account.'
      )
    },
  ],
  [],
  [],
  []
)

const gradesViewChangeLogPermissions = generateActionTemplates(
  'view_grade_changes',
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(
        `Determines visibility of the Grade Change Activity option in the Admin Tools Logging tab.`
      )
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(`To search by grader or student ID, Users - view list must also be enabled.
To search by course ID or assignment ID, Grades - edit must also be enabled.
To search by assignment ID only, Grades - view all grades​ must also be enabled.`)
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
      description: I18n.t(
        `Allows user to access the View Notifications tab in Admin Tools.`
      )
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Notifications tab)'),
      description: I18n.t(`To search and view notifications for a user, Users - view list must also be enabled.`)
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t(`Not available at the subaccount level.`)
    }
  ]
)

const alertPermissions = generateActionTemplates(
  'manage_interaction_alerts',
  [
    {
      title: I18n.t('Alerts (Course Settings)'),
      description: I18n.t(
        'Allows user to configure alerts in Course Settings. Alerts are a seldom-used feature designed to send an alert to students, teachers or admins for specific triggers (e.g., no student/teacher interaction for 7 days). They are checked every day, and notifications will be sent to the student and/or the teacher until the triggering problem is resolved.'
      )
    }
  ],
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(
        'This is an account setting that must be turned on by your Customer Success Manager.'
      )
    }
  ],
  [
    {
      title: I18n.t('Alerts (Course Settings)'),
      description: I18n.t(
        'Allows user to configure alerts in course settings. Alerts are a seldom-used feature designed to send an alert to students, teachers or admins for specific triggers (e.g., no student/teacher interaction for 7 days). They are checked every day, and notifications will be sent to the student and/or the teacher until the triggering problem is resolved.'
      )
    }
  ],
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(
        'This is an account setting that must be turned on by your Customer Success Manager.'
      )
    }
  ]
)

const announcementsViewPermissions = generateActionTemplates(
  'read_announcements',
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t(
        'Allows user to view the Announcements link in Course Navigation. Allows user to view course announcements.'
      )
    }
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t(
        'To view recent announcements on the home page, Course content - view must be enabled, and the Show recent announcements on Course home page checkbox must be selected in Course Settings. To manage course announcements, Discussions - moderate ​must also be enabled.'
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
      description: I18n.t(`Allows user to access the Announcements link in Course Navigation.
Allows user to view course announcements.
Allows user to view recent announcements on the course home page.`)
    }
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t(
        `To add announcements, Discussions - moderate must also be enabled. To view recent announcements on the home page, the Show recent announcements on Course home page checkbox must be selected in Course Settings.`
      )
    }
  ]
)

const assignmentsQuizzesPermissions = generateActionTemplates(
  'manage_assignments',
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(`Allows user to add, edit, delete, and publish/unpublish assignments.
Allows user to manage assignment settings.
Allows user to add assignment groups in a course.
Allows user to enable and edit assignment group weighting in a course.`)
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(`Allows user to edit blueprint lock settings on the Assignments and Quizzes index
pages in a Blueprint master course.`)
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t(`Allows user to share a quiz to Commons.`)
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        `Allows user to edit assignment details on individual discussions.`
      )
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(`Allows user to add new assignments to a module.`)
    },
    {
      title: I18n.t('Question Banks (Account Navigation)'),
      description: I18n.t(`Determines visibility and management of the Question Banks account navigation link.`)
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(`Allows user to add, edit, delete, and publish/unpublish quizzes.`)
    }
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(
        'To access the Assignments Index Page, Course Content - view must be enabled. To differentiate assignments to individual students, Users - view list ​must also be enabled.'
      )
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(`Blueprint courses is an account-level feature option.
To edit blueprint lock settings from the Assignments index page, Courses - add / edit / delete​ must also be enabled. If this permission is not enabled, and Courses - add / edit / delete​ is enabled, blueprint lock settings for an assignment can be managed from the assignment’s details page.
To edit blueprint lock settings on an individual quiz, or on the Quizzes index page, Courses - add / edit / delete​ must also be enabled.`)
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(`To import assignments and quizzes using the Course Import Tool, Course Content - add / edit / delete must be enabled.`)
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t(`To moderate grades, Grades - Select final grade for moderation must also be enabled.`)
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t('To moderate a quiz, Grades - edit​ must also be enabled.')
    },
    {
      title: I18n.t('Rubrics'),
      description: I18n.t(`Disabling this permission will override (if enabled) the Rubrics - add / edit / delete ​permission, preventing user from creating or editing rubrics from an
individual assignment. However, if Learning Outcomes - add / edit / delete​ is enabled, user can still add rubrics via Outcomes – Manage Rubrics.`)
    }
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(`Allows user to add, edit, delete, and publish/unpublish assignments.
Allows user to manage assignment settings.
Allows user to add assignment groups in a course.
Allows user to enable and edit assignment group weighting in a course.`)
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(`Allows user to edit blueprint lock settings on the Assignments and Quizzes index
pages in a Blueprint master course.`)
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t(`Allows user to share a quiz to Commons.`)
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        `Allows user to edit assignment details on individual discussions. Modules: Allows user to add new assignments to a module.`
      )
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(`Allows user to add new assignments to a module.`)
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(`Allows user to add, edit, delete, and publish/unpublish quizzes.`)
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
      description: I18n.t(`Blueprint courses is an account-level feature option.
To edit blueprint lock settings from the Assignments index page, Courses - add / edit / delete​ must also be enabled. If this permission is not enabled, and Courses - add / edit / delete​ is enabled, blueprint lock settings for an assignment can be managed from the assignment’s details page.
To edit blueprint lock settings on an individual quiz, or on the Quizzes index page, Courses - add / edit / delete​ must also be enabled.`)
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('To import assignments and quizzes using the Course Import Tool, Course Content - add / edit / delete must be enabled.')
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t(`To moderate grades, Grades - Select final grade for moderation must also be enabled.`)
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t('To moderate a quiz, Grades - edit​ must also be enabled.')
    },
    {
      title: I18n.t('Rubrics'),
      description: I18n.t(`Disabling this permission will override (if enabled) the Rubrics - add / edit / delete ​permission, preventing user from creating or editing rubrics from an
individual assignment. However, if Learning Outcomes - add / edit / delete​ is enabled, user can still add rubrics via Outcomes – Manage Rubrics.`)
    },
  ]
)

const messagesSentEntireClassPermissions = generateActionTemplates(
  'send_messages_all',
  [
    {
      title: I18n.t('Conversations'),
      description: I18n.t(`Allows user to send a message to “All in [course name]”.
Allows user to send a message to “All in [course group]”.`)
    }
  ],
  [],
  [
    {
      title: I18n.t('Conversations'),
      description: I18n.t(
        `Allows user to send a message to “All in [course name],” or “All in [course group].”`
      )
    }
  ],
  []
)

const messagesSentPermissions = generateActionTemplates(
  'send_messages',
  [
    {
      title: I18n.t('Conversations'),
      description: I18n.t(`Allows user to send messages to individual course members.`)
    }
  ],
  [
    {
      title: I18n.t('Conversations'),
      description: I18n.t(
        `When disabled, students can still send individual messages to course teachers, course TAs, and students that belong to the same account-level groups.`
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        `To edit a student’s section, Users - add / remove students from courses and Users - view list must also be enabled.
To edit a section for a teacher, course designer, or TA, Users - add / remove teachers, course designers, or TAs from courses and Users - view list must also be enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Conversations'),
      description: I18n.t(`Allows user to send messages to individual course members.`)
    }
  ],
  [
    {
      title: I18n.t('Conversations'),
      description: I18n.t(
        `When disabled, students can still send individual messages to course teachers, course TAs, and students that belong to the same account-level groups.`
      )
    },
    {
      title: I18n.t('People'),
      description: I18n.t(`To edit a student’s section, Users - add / remove students in courses and Users - view list  must also both be enabled.
To edit a section for a teacher, course designer, or TA, Users - add / remove teachers, course designers, or TAs in courses ​and Users - view list must also both be enabled.`)
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
      title: I18n.t('Attendance'),
      description: I18n.t(`Allows teacher/TA-based roles to access the Attendance tool.`)
    },
    {
      title: I18n.t('Chat'),
      description: I18n.t(`Allows teacher/designer/TA-based roles to access the Chat tool.`)
    },
    {
      title: I18n.t('Collaborations'),
      description: I18n.t(`Allows user to view previously created collaborations.
Allows user to edit title, description, or remove collaborators on all collaborations.`)
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t(`Allows user to import resources from Commons into a course.
Allows user to share assignments to Commons or edit previously shared content.`)
    },
    {
      title: I18n.t('Conferences'),
      description: I18n.t(`Allows users to edit Conferences.`)
    },
    {
      title: I18n.t('Course Home Page'),
      description: I18n.t(`Allows user to view Course Status, Choose Home Page, and Course Setup
Checklist buttons in the Home page.`)
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(`Allows user to import content using the Course Import Tool.`)
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(`Allows user to manage modules (create, add items, edit module settings,
publish/unpublish, etc.).`)
    },
    {
      title: I18n.t('Syllabus'),
      description: I18n.t(`Allows user to edit the course syllabus.`)
    }
  ],
  [
    {
      title: I18n.t('Attendance'),
      description: I18n.t(`The Attendance tool must be enabled by your Canvas admin.`)
    },
    {
      title: I18n.t('Chat'),
      description: I18n.t(`The Chat tool must be enabled by your Canvas admin.`)
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t(
        `To share a Discussion to Commons, Discussions - view​ must also be enabled.`
      )
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        `The Course Status buttons (unpublished and published) are only displayed until a student submission is received. Courses cannot be unpublished with student submissions.`
      )
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(
        `To publish and unpublish module content, Courses - add / edit / delete and Course Content - view​ must also be enabled.
        Module items cannot be unpublished if there are student submissions.`
      )
    }
  ],
  [
    {
      title: I18n.t('Attendance'),
      description: I18n.t(`Allows teacher/TA-based roles to access the Attendance tool.`)
    },
    {
      title: I18n.t('Chat'),
      description: I18n.t(`Allows teacher/designer/TA-based roles to access the Chat tool.`)
    },
    {
      title: I18n.t('Collaborations'),
      description: I18n.t(`Allows user to view previously created collaborations.
Allows user to edit title, description, or remove collaborators on all collaborations.`)
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t(`Allows user to import resources from Commons into a course.
Allows user to share assignments to Commons or edit previously shared content.`)
    },
    {
      title: I18n.t('Course Navigation'),
      description: I18n.t(`Allows user to view Course Status, Choose Home Page, and Course Setup
Checklist buttons in the Home page.`)
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(`Allows user to import content using the Course Import Tool.`)
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(`Allows user to manage modules (create, add items, edit module settings,
publish/unpublish, etc.).`)
    },
    {
      title: I18n.t('Syllabus'),
      description: I18n.t(`Allows user to edit the course syllabus.`)
    }
  ],
  [
    {
      title: I18n.t('Attendance'),
      description: I18n.t(`The Attendance tool must be enabled by your Canvas admin.`)
    },
    {
      title: I18n.t('Chat'),
      description: I18n.t(`The Chat tool must be enabled by your Canvas admin.`)
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t(
        `To share a Discussion to Commons, Discussions - view​ must also be enabled.`
      )
    },
    {
      title: I18n.t('Conferences'),
      description: I18n.t(`Allows users to edit Conferences.`)
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        `The Course Status buttons (unpublished and published) are only displayed until a student submission is received. Courses cannot be unpublished with student submissions.`
      )
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(
        `To publish and unpublish module content, Courses - add / edit / delete and Course Content - view​ must also be enabled.`
      )
    }
  ]
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
        'Regardless of whether this permission is enabled or disabled, the user will still be able to manage events on their personal calendar.'
      )
    },
    {
      title: I18n.t('Courses'),
      description: I18n.t(`If disabled, user will still have access to Course Settings.

        User cannot manage individual course content without the appropriate
        permission for that content item.

        If course visibility is limited to users enrolled in the course, this permission
        allows a user to view course content without being enrolled in the course.`)
    }
  ],
  [],
  []
)

const courseFilesAddPermissions = generateActionTemplates(
  'manage_files',
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Allows user to edit blueprint lock settings on the Files page in a Blueprint master course.'
      )
    },
    {
      title: I18n.t('Course Files'),
      description: I18n.t(`Allows user to add, edit, and delete course files and folders.
Allows user to download files into a zip file, import a zip file, and lock/unlock files.`)
    },
    {
      title: I18n.t('Rich Content Editor'),
      description: I18n.t(`Allows user to access the Files tab in the Content Selector.`)
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(`Blueprint courses must be enabled for an account by an admin.
To edit blueprint lock settings for course files, Courses - add / edit / delete must also be enabled.`)
    },
    {
      title: I18n.t('Course Files'),
      description: I18n.t(`If disabled, user can still view and download files into a zip file.`)
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        `To import files using the Course Import Tool, Course Content - add / edit / delete must also be enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Allows user to edit blueprint lock settings on the Files page in a Blueprint master course.'
      )
    },
    {
      title: I18n.t('Course Files'),
      description: I18n.t(`Allows user to add, edit, and delete course files and folders.
Allows user to download files into a zip file, import a zip file, and lock/unlock files.`)
    },
    {
      title: I18n.t('Rich Content Editor'),
      description: I18n.t(`Allows user to access the Files tab in the Content Selector.`)
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(`Blueprint courses must be enabled for an account by an admin.
Course roles can only manage content in Blueprint Courses if they are added to the Blueprint Course as a teacher, TA, or designer role.`)
    },
    {
      title: I18n.t('Course Files'),
      description: I18n.t(`If disabled, user can still view and download files into a zip file.`)
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        `To import files using the Course Import Tool, Course Content - add / edit / delete must also be enabled.`
      )
    }
  ]
)

const courseSectionsViewPermissions = generateActionTemplates(
  'manage_sections',
  [
    {
      title: I18n.t('Course Settings (Sections tab)'),
      description: I18n.t(`Allows user to add, edit, and delete course sections.
Allows user to cross-list sections.`)
    }
  ],
  [
    {
      title: I18n.t('Course Settings (Sections tab)'),
      description: I18n.t(`To cross-list sections, Course - add / edit / delete must also be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('Course Settings (Sections tab)'),
      description: I18n.t(`Allows user to add, edit, and delete course sections.
Allows user to cross-list sections.`)
    }
  ],
  [
    {
      title: I18n.t('Course Settings (Sections tab)'),
      description: I18n.t(`The user must also be enrolled as an instructor in the courses they are trying to cross-list.`)
    }
  ]
)

const courseStateManagePermissions = generateActionTemplates(
  'change_course_state',
  [
    {
      title: I18n.t('Course Home Page'),
      description: I18n.t(`Determines whether a Publish Course option is included on the Course Home Page.`)
    },
    {
      title: I18n.t('Course Settings'),
      description: `Affects viewing the Publish Course and Conclude Course buttons.`
    }
  ],
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(`For course-level users, deleting a course is part of the Course State - manage permission. However, for account-level users, deleting a course requires this permission and Course - add / edit / delete. `)
    },
    {
      title: I18n.t('Course Setup Checklist'),
      description: I18n.t(`To see the Course Setup Checklist option on the Course Home Page, Manage ( add / edit / delete ) courses must also be enabled.`)
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t
      (
        `The Course State - manage permission allows users to publish courses that do not contain modules. To publish/unpublish module content, Course Content - add / edit / delete​ must be enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Course'),
      description: I18n.t(`Allows user to publish, conclude, and delete courses.`)
    },
    {
      title: I18n.t('Course Setup Checklist, Course Home Page'),
      description: I18n.t(`Determines whether a Publish Course option is included in the Course Setup Checklist and in the Course Home Page.`)
    }
  ],
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(`Affects viewing the Publish Course, Conclude Course, and Permanently Delete this Course buttons.
The Permanently Delete this Course button only appears for manually created courses.`)
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(
        `The Course State - manage permission allows users to publish courses that do not contain modules. To publish/unpublish module content, Course Content - add / edit / delete​ must be enabled.`
      )
    }
  ]
)

const courseViewUsagePermissions = generateActionTemplates(
  'read_reports',
  [
    {
      title: I18n.t('Reports'),
      description: I18n.t(`Allows user to view and configure reports in Account Settings.
Allows user to view Access Reports and Student Interaction reports.
Allows user to view last activity and total activity information on the People page.`)
    }
  ],
  [
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        `To view Last Activity and Total Activity information on the Course People page, Users - view list must also be enabled.
        To access a Course People page, Users - view list must also be enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(`Allows user to view the Course Statistics button in Course Settings.`)
    },
    {
      title: I18n.t('People'),
      description: I18n.t(
        `Allows user to view Last Activity and Total Activity information on the People page.`
      )
    },
    {
      title: I18n.t('Reports'),
      description: I18n.t(
        `Allows user to view Last Activity, Total Activity, and Student Interactions reports.`
      )
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(`To access the People Page, Users - view list​ must be enabled.`)
    }
  ]
)

const discussionscreatePermissions = generateActionTemplates(
  'create_forum',
  [
    {
      title: I18n.t('Discussions'),
      description: I18n.t(`Allows user to add discussions in the Discussions page.`)
    }
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t(`To create announcements, Discussions - moderate must also be enabled.`)
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(`To view discussions in a course, Discussions - view must be enabled.
        Both Discussions - create and Discussions - moderate allow a user to create a discussion in the Discussions page. To manage discussions, Discussions - moderate must also be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('Discussions'),
      description: I18n.t(`Allows user to add discussions in the Discussions page.`)
    }
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t(`To create announcements, Discussions - moderate must also be enabled.`)
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(`To view discussions in a course, Discussions - view must be enabled.
        Both Discussions - create and Discussions - moderate allow a user to create a discussion in the Discussions page. To manage discussions, Discussions - moderate must also be enabled.`)
    }
  ]
)

const discussionsModerateManagePermissions = generateActionTemplates(
  'moderate_forum',
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t(`Allows user to view the New Announcement button in the Home page.
Allows user to add announcements in the Announcements page.`)
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        `Allows user to edit blueprint lock settings on the Discussions index page in a Blueprint master course.`
      )
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(`Allows user to add discussions in the Discussions page.
Allows user to close for comments, move, pin/unpin, edit, and delete discussion topics created by other users.`)
    }
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t(`To view announcements, Announcements - view must also be enabled.`)
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        `Blueprint Courses is an account-level feature option. To edit blueprint lock settings on the Discussions index page, Courses - add / edit / delete​ and Discussions - view​ must also be enabled. If this permission is not enabled, and Courses - add / edit / delete​ and Discussions - view​ are enabled, blueprint lock settings can be edited on individual discussions.`
      )
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(`Both Discussions - create and Discussions - moderate allow a user to create a discussion in the Discussions page. If this permission is enabled, Discussions - create is not required.
        To view discussions in a course, Discussions - view​ must be enabled.
To reply to a discussion, Discussions - post must also be enabled.
To edit assignment details on a discussion, Assignments and Quizzes - add / edit / delete must also be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t(`Allows user to view the New Announcement button in the Home page.
Allows user to add announcements in the Announcements page.`)
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        `Allows user to edit blueprint lock settings on the Discussions index page in a Blueprint master course.`
      )
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(`Allows user to add discussions in the Discussions page.
Allows user to close for comments, move, pin/unpin, edit, and delete discussion topics created by other users.`)
    }
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t(`To view announcements, Announcements - view must also be enabled.`)
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(`Blueprint courses must be enabled for an account by an admin.
Course roles can only manage content in Blueprint Courses if they are added to the Blueprint Course as an teacher, TA, or designer role.
If this setting is disabled, and Discussions - view​ is enabled, a user can still adjust content lock settings on individual discussions in a Blueprint master course.`)
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(`Both Discussions - create and Discussions - moderate allow a user to create a discussion in the Discussions page. If this permission is enabled, Discussions - create is not required.
        To view discussions in a course, Discussions - view​ must be enabled.
To reply to a discussion, Discussions - post​ must also be enabled. To edit assignment details on a discussion, Assignments and Quizzes - add / edit / delete must also be enabled.`)
    }
  ]
)

const discussionPostPermissions = generateActionTemplates(
  'post_to_forum',
  [
    {
      title: I18n.t('Discussions'),
      description: I18n.t(`Allows user to reply to a discussion post.`)
    }
  ],
  [
    {
      title: I18n.t('Discussions'),
      description: I18n.t(`To view discussions in a course, Discussions - view must also be enabled.
To manage discussions, Discussions - moderate must be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('Discussions'),
      description: I18n.t(`Allows user to reply to a discussion post.`)
    }
  ],
  [
    {
      title: I18n.t('Discussions'),
      description: I18n.t(`To view discussions in a course, Discussions - view​ must also be enabled.
To manage discussions, Discussions - moderate must be enabled.`)
    }
  ]
)

const discussionViewPermissions = generateActionTemplates(
  'read_forum',
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(`Allows user to edit blueprint content lock settings on individual discussions.`)
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(`Allows user to view the Discussions link in Course Navigation.
Allows user to view course discussions.`)
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(`Blueprint Courses are an account-level feature option.

To edit blueprint lock settings from the Discussions index page, Course - add / edit / delete and Discussions - moderate must also be enabled. `)
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t(`To share a discussion to Commons, Course Content - add / edit / delete must also be enabled.`)
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(`To manage discussions, Discussions - post and Discussions - moderate must also be enabled. To reply to a discussion, Discussions - post must also be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(`Allows user to edit blueprint content lock settings on individual settings If the user is enrolled in a Blueprint master course.`)
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(`Allows user to view the Discussions link in Course Navigation.
Allows user to view course discussions.`)
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(`Blueprint Courses must be enabled for an account by an admin.

Course roles can only manage content in Blueprint Courses if they are added to the Blueprint Course with a teacher, TA, or designer role.

To edit blueprint lock settings from the Discussions index page, Discussions - moderate must also be enabled.`)
},
{
  title: I18n.t('Commons'),
  description: I18n.t(`To share a discussion to Commons, Course Content - add / edit / delete must also be enabled.`)
},
{
  title: I18n.t('Discussions'),
  description: I18n.t(`To manage discussions, Discussions - moderate must also be enabled.

To reply to a discussion, Discussions - post must also be enabled.`)
}
  ]
)

const featureFlagsPermissions = generateActionTemplates(
  'manage_feature_flags',
  [
    {
      title: I18n.t('Feature Options (Account Settings)'),
      description: I18n.t(`Allows user to manage Feature Options in Account Settings.`)
    }
  ],
  [],
  [],
  []
)

const usernotesPermissions = generateActionTemplates(
  'manage_user_notes',
  [
    {
      title: I18n.t('Global Navigation'),
      description: I18n.t(`Allows user to view the Faculty Journal link in Global Navigation.`)
    },
    {
      title: I18n.t('Student Interaction Report'),
      description: I18n.t(`Allows user to view Faculty Journal entries in the Student Interactions Report.`)
    },
    {
      title: I18n.t('User Details'),
      description: I18n.t(`Allows user to view a link to the Faculty Journal in the User Details page sidebar.
          Allows user to view Faculty Journal information for individual students.
         Allows user to create new entries in the Faculty Journal.`)
    }
  ],
  [
    {
      title: I18n.t('User Details'),
      description: I18n.t(`To view the User Details page for a student, Users - add / remove students in courses must also be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('Student Interaction Report'),
      description: I18n.t(`Allows user to view Faculty Journal entries in the Student Interactions Report.`)
    },
    {
      title: I18n.t('User Details'),
      description: I18n.t(`Allows user to view a link to the Faculty Journal in the User Details page sidebar.
        Allows user to view Faculty Journal information for individual students.
       Allows user to create new entries in the Faculty Journal.`)
    }
  ],
  [
    {
      title: I18n.t('User Details'),
      description: I18n.t(`To view the User Details page for a student, Users - add / remove students in courses must also be enabled.`)
    }
  ]
)

const finalGradePermissions = generateActionTemplates(
  'select_final_grade',
  [
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        `Allows user to select final grade for moderated assignments.`)
    }
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(
        `To allow a user to add students to a moderation set, Grades - view all grades must also be enabled.`
      )
    },
    {
      title: I18n.t('SpeedGrader'),
      description: I18n.t(
        `To allow a user to review a moderated assignment in SpeedGrader, Grades - edit must also be enabled.`
      )
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t(
      `To allow a user to publish final grades for a moderated assignment, Grades - edit must also be enabled.`
    )
    }
  ],
  [
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        `Allows user to select final grade for moderated assignments.`)
    }
  ],
  [
      {
        title: I18n.t('Assignments'),
        description: I18n.t(
          `To allow a user to add students to a moderation set, Grades - view all grades must also be enabled.`)
      },
      {
        title: I18n.t('SpeedGrader'),
        description: I18n.t(
          `To allow a user to review a moderated assignment in SpeedGrader, Grades - edit must also be enabled.`)
      },
      {
        title: I18n.t('Grades'),
        description: I18n.t(
        `To allow a user to publish final grades for a moderated assignment, Grades - edit must also be enabled.`)
      }
    ]
  )

const gradeAuditTrailPermissions = generateActionTemplates(
  'view_audit_trail',
  [
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        `Allows user to review an audit trail in assignments, both moderated and anonymous.`
      )
    }
  ],
  [
    {
      title: I18n.t('Grades'),
      description: I18n.t(`To allow user to moderate grades, Grades - Select final grade for moderation must also be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        `Allows user to review an audit trail in assignments, both moderated and anonymous.`
      )
    }
  ],
  [
    {
      title: I18n.t('Grades'),
      description: I18n.t(`To allow user to moderate grades, Grades - Select final grade for moderation must also be enabled.`)
    }
  ]
)

const gradesEditPermissions = generateActionTemplates(
  'manage_grades',
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(
        `Allows user to search by course ID or assignment ID in grade change logs in Admin Tools.`
      )
    },
    {
      title: I18n.t('Analytics'),
      description: I18n.t(`Allows user to view student-specific data in Analytics.`)
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(`Allows user to view the course grading scheme.`)
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        `Allows user to like discussion posts when the Only Graders Can Like checkbox is selected.`
      )
    },
    {
      title: I18n.t('Gradebook'),
      description: I18n.t(`Allows user to add, edit, and update grades in the Gradebook.
Allows user to access Gradebook History.
Allows user to access the Learning Mastery Gradebook (if enabled).`)
    },
    {
      title: I18n.t('Grading Schemes'),
      description: I18n.t(`Allows user to create and modify grading schemes.`)
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(`Allows user to moderate a quiz.`)
    },
    {
      title: I18n.t('SpeedGrader'),
      description: I18n.t(`Allows user to edit grades and add comments in SpeedGrader.`)
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(
        `To search grade change logs, Grades - view change logs must also be enabled.`
      )
    },
    {
      title: I18n.t('Analytics'),
      description: I18n.t(
        `To view student analytics in course analytics, Analytics - view​ must also be enabled.`
      )
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        `To edit course grading schemes, Courses - add / edit / delete must also be enabled.`
      )
    },
    {
      title: I18n.t('Gradebook, SpeedGrader'),
      description: I18n.t(
        `Gradebook and SpeedGrader will be inaccessible if both Grades - edit​ and Grades - view all grades​ are disabled.`
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        `To view student analytics, Users - view list​ and Analytics - view​ must also be enabled.`
      )
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        `To moderate a quiz, Assignments and Quizzes - add / edit / delete​ must also be enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Analytics'),
      description: I18n.t(
        `Allows user to view student-specific data in Analytics.`
      )
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        `Allows user to edit grading schemes.`
      )
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        `Allows user to like discussion posts when the Only Graders Can Like checkbox is selected.`
      )
    },
    {
      title: I18n.t('Gradebook'),
      description: I18n.t(
        `Allows user to edit grades in the Gradebook.
        Allows user to access Gradebook History.
        Allows user to access the Learning Mastery Gradebook (if enabled).`
      )
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        `Allows user to moderate a quiz.`
      )
    },
    {
      title: I18n.t('SpeedGrader'),
      description: I18n.t(`Allows user to edit grades and add comments in SpeedGrader.`)
    }
  ],
  [
    {
      title: I18n.t('Analytics'),
      description: I18n.t(
        `To view student analytics in course analytics, Analytics - view​ must also be enabled.`
      )
    },
    {
      title: I18n.t('Gradebook, SpeedGrader'),
      description: I18n.t(
        `Gradebook and SpeedGrader will be inaccessible if both Grades - edit and Grades - view all grades​ are disabled.`
      )
    },
    {
      title: I18n.t('People'),
      description: I18n.t(
        `To view student analytics, Users - view list and Analytics - view must also be enabled.`
      )
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        `To moderate a quiz, Assignments and Quizzes - add / edit / delete must also be enabled.`
      )
    },
    {
      title: I18n.t('Settings'),
      description: I18n.t(`Course Grading Schemes can be enabled/disabled in Course Settings.`)
    }
  ]
)

const gradesModeratePermissions = generateActionTemplates(
  'moderate_grades',
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(`Allows user to view the Moderate button for moderated assignments. NOTE: This permission is being deprecated. To enable users to view the Moderate button, enable Grades - Select final grade for moderation.`)
    }
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(
        `To allow a user to add students to a moderation set, Grades - view all grades must also be enabled.`
      )
    },
    {
      title: I18n.t('SpeedGrader'),
      description: I18n.t(
        `To allow a user to review a moderated assignment in SpeedGrader, Grades - edit must also be enabled.`
      )
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        `To allow a user to publish final grades for a moderated assignment, Grades - edit​ must also be enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(`Allows user to view the Moderate button for moderated assignments. NOTE: This permission is being deprecated. To enable users to view the Moderate button, enable Grades - Select final grade for moderation.`)
    }
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(`To allow a user to add students to a moderation set, Grades - view all grades​ must also be enabled.
To allow a user to add students to a moderation set, review a moderated assignment in SpeedGrader, and publish final grades for a moderated assignment, Grades - edit​ must also be enabled.`)
    }
  ]
)

const gradesViewAllPermissions = generateActionTemplates(
  'view_all_grades',
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(`Allows user to search by assignment ID in grade change logs.`)
    },
    {
      title: I18n.t('Analytics'),
      description: I18n.t(`Allows user to view student-specific data in Analytics.`)
    },
    {
      title: I18n.t('Assignments, SpeedGrader'),
      description: I18n.t(`Allows user to view a link to SpeedGrader from assignments.`)
    },
    {
      title: I18n.t('Gradebook'),
      description: I18n.t(`Allows user to view Gradebook.
Allows user to export the Gradebook to a comma separated values (CSV) file.
Allows user to access the Learning Mastery Gradebook (if enabled).`)
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t(`Allows user to view student Grades pages.`)
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(`Allows user to access the Student Progress page.`)
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(`Adds analytics link on the user settings menu.`)
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        `Allows user to view student results and/or access a quiz in SpeedGrader.`
      )
    },
    {
      title: I18n.t('Rubrics, SpeedGrader'),
      description: I18n.t(`Allows user to view grader comments on a rubric in SpeedGrader.`)
    },
    {
      title: I18n.t('Student Context Card'),
      description: I18n.t(`Adds analytics to a student’s context card.`)
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Grade Change Logs)'),
      description: I18n.t(
        `To search grade change logs, Grades - view change logs​ must also be enabled.`
      )
    },
    {
      title: I18n.t('Analytics'),
      description: I18n.t(`To view student analytics, Analytics - view ​must also be enabled.`)
    },
    {
      title: I18n.t('Gradebook'),
      description: I18n.t(`If both Grades - edit and Grades - view all grades are disabled, Gradebook will be hidden from Course Navigation.`)
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(
        `To view module progression, Grades - view all grades​ must also be enabled.`
      )
    },
    {
      title: I18n.t('Student Context Card'),
      description: I18n.t(`Student Context Cards must be enabled for an account by an admin.`)
    }
  ],
  [
    {
      title: I18n.t('Analytics'),
      description: I18n.t(`Allows user to view student-specific data in Analytics.`)
    },
    {
      title: I18n.t('Assignments, SpeedGrader'),
      description: I18n.t(`Allows user to access SpeedGrader from an assignment.`)
    },
    {
      title: I18n.t('Gradebook'),
      description: I18n.t(`Allows user to view Gradebook.
Allows user to export the Gradebook to a comma separated values (CSV) file.
Allows user to access the Learning Mastery Gradebook (if enabled).`)
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t(`Allows user to view student Grades pages.`)
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(`Allows user to access the Student Progress page.`)
    },
    {
      title: I18n.t('People'),
      description: I18n.t(`Adds analytics link on the user settings menu.`)
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        `Allows user to view student results and/or access a quiz in SpeedGrader.`
      )
    },
    {
      title: I18n.t('Rubrics, SpeedGrader'),
      description: I18n.t(`Allows user to view grader comments on a rubric in SpeedGrader.`)
    },
    {
      title: I18n.t('Student Context Card'),
      description: I18n.t(`Adds analytics to a student’s context card.`)
    }
  ],
  [
    {
      title: I18n.t('Analytics'),
      description: I18n.t(`To view student analytics, Analytics - view ​must also be enabled.`)
    },
    {
      title: I18n.t('Gradebook'),
      description: I18n.t(
        `If both Grades - edit​ and Grades - view all grades are disabled, Gradebook will be hidden from the course navigation.`
      )
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(
        `To view module progression, Grades - view all grades​ must also be enabled.`
      )
    },
    {
      title: I18n.t('Student Context Card'),
      description: I18n.t(`Student Context Cards must be enabled for an account by an admin.`)
    }
  ]
)

const gradesAddEditDeletePermissions = generateActionTemplates(
  'manage_groups',
  [
    {
      title: I18n.t('Account Groups'),
      description: I18n.t(`Allows user to create, edit, and delete account groups.`)
    },
    {
      title: I18n.t('Course Groups'),
      description: I18n.t(`Allows user to create, edit, and delete course groups.
Allows user to create, edit, and delete course groups created by students.`)
    }
  ],
  [
    {
      title: I18n.t('Account Groups'),
      description: I18n.t(
        `If this permission is disabled, at the account level, users cannot view any existing account groups. At the course level, users can view, but not access, any existing groups, including groups created by students. To view groups, Users - view list m​ust also be ​enabled. To add account level groups via CSV, SIS Data - import must also be enabled.`
      )
    },
    {
      title: I18n.t('Course Groups'),
      description: I18n.t(
        `By default, students can always create groups in a course. To restrict students from creating groups, Courses - add / edit / delete must be enabled and the Let students organize their own groups checkbox in Course Settings must be deselected.`
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        `To access the People page and view Groups, Users - view list must also be enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('People (Groups tab)'),
      description: I18n.t(
        `Allows user to create, edit, and delete course groups. Allows user to create, edit, and delete course groups created by students.`
      )
    }
  ],
  [
    {
      title: I18n.t('Collaborations'),
      description: I18n.t(
        `Allows user to view all course groups, not just those they are enrolled in, in the Collaborate With window.`
      )
    },
    {
      title: I18n.t('Groups'),
      description: I18n.t(
        `If this permission is disabled, users can only view existing groups, including groups created by students.`
      )
    },
    {
      title: I18n.t('People'),
      description: I18n.t(
        `To access the People page and view Groups, Users - view list must also be enabled.`
      )
    },
    {
      title: I18n.t('Course Settings (Course Details tab)'),
      description: I18n.t(
        `To restrict students from creating groups, deselect the Let students organize their own groups checkbox in Course Settings.`
      )
    }
  ]
)

const groupsViewAllStudentPermissions = generateActionTemplates(
  'view_group_pages',
  [
    {
      title: I18n.t('Groups'),
      description: I18n.t(`Allows user to view the group home pages of all student groups.
Allows students to access other student groups within a group set with a direct link.`)
    }
  ],
  [
    {
      title: I18n.t('Groups'),
      description: I18n.t(`By default students are able to create groups; to restrict students from creating
groups, deselect the Let students organize their own groups checkbox in Course Settings.`)
    }
  ],
  [
    {
      title: I18n.t('Groups'),
      description: I18n.t(`Allows user to view the group home pages of all student groups.
Allows students to access other student groups within a group set with a direct link.`)
    }
  ],
  [
    {
      title: I18n.t('Groups'),
      description: I18n.t(`By default students are able to create groups; to restrict students from creating
groups, deselect the Let students organize their own groups checkbox in Course Settings.`)
    }
  ]
)

const ltiAddEditPermissions = generateActionTemplates(
  'lti_add_edit',
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(`Allows user to manually add and delete an app in Account Settings.`)
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(`Allows user to manually add and delete an app in Course Settings.`)
    },
    {
      title: I18n.t('External Apps'),
      description: I18n.t(`Allows user to edit configurations for manually added external apps.`)
    }
  ],
  [
    {
      title: I18n.t('External Apps (Account/Course Settings)'),
      description: I18n.t(
        'If this permission is disabled, users can still install approved apps through the Canvas App Center (if enabled for your institution). Additionally, if this permission is disabled, users cannot delete manually added external apps.'
      )
    }
  ],
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(`Allows user to manually add and delete an app in Course Settings.`)
    },
    {
      title: I18n.t('External Apps (Course Settings)'),
      description: I18n.t(`Allows user to edit configurations for manually added external apps.`)
    }
  ],
  [
    {
      title: I18n.t('External Apps (Course Settings)'),
      description: I18n.t(
        'If this permission is disabled, users can still install approved apps through the Canvas App Center (if enabled for your institution). Additionally, if this permission is disabled, users cannot delete manually added external apps.'
      )
    }
  ]
)

const learningOutcomesAddEditDeletePermissions = generateActionTemplates(
  'manage_outcomes',
  [
    {
      title: I18n.t('Outcomes'),
      description: I18n.t(`Determines visibility and management of Outcomes tab in account navigation.
Allows user to create, import, edit, and delete outcomes and outcome groups at the account and course levels.`)
    },
    {
      title: I18n.t('Rubrics'),
      description: I18n.t(`Determines visibility and management of Rubrics tab in the account navigation.
Allows user to manage rubrics.`)
    }
  ],
  [
    {
      title: I18n.t('Outcomes and Rubrics'),
      description: I18n.t(
        `To view the Outcomes page as read-only, Course content - view must be enabled.
Users can access individual assignment rubrics through Assignments when Course Content - view and Assignments and Quizzes - add / edit / delete is also enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Outcomes'),
      description: I18n.t(`Allows user to create, import, edit, and delete outcomes and outcome groups at
the course level.`)
    },
    {
      title: I18n.t('Rubrics'),
      description: I18n.t(`Allows user to manage rubrics.`)
    }
  ],
  [
    {
      title: I18n.t('Outcomes and Rubrics'),
      description: I18n.t(
        `If disabled, the Outcomes page becomes read-only and hides the Manage Rubrics button. User can still access individual assignment rubrics through Assignments.`
      )
    }
  ]
)

const learningOutcomesImportPermissions = generateActionTemplates(
  'import_outcomes',
  [
    {
      title: I18n.t('Outcomes and Rubrics (Account/Course)'),
      description: I18n.t(`Allows user to import learning outcomes.`)
    }
  ],
  [],
  [
    {
      title: I18n.t('Outcomes and Rubrics'),
      description: I18n.t(`Allows user to import learning outcomes to rubrics.`)
    }
  ],
  [
    {
      title: I18n.t('Outcomes and Rubrics'),
      description: I18n.t(`To view a Course Outcomes page as read-only, Course Content - view must be enabled.
To import learning outcomes from the Outcomes page, Rubrics - add / edit / delete must also be enabled.
Users can access and create (but not edit) individual assignment rubrics through Assignments when Course Content - view and Assignments and Quizzes - add / edit / delete are enabled.`)
    }
  ]
)

const pagesAddRemovePermissions = generateActionTemplates(
  'manage_wiki',
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        `Allows user to edit blueprint lock settings on the Pages index page in a Blueprint master course.`
      )
    },
    {
      title: I18n.t('Pages'),
      description: I18n.t(
        `Allows user to view, create, edit, delete, and publish/unpublish pages.
Allows user to view page history and set front page. `
      )
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(`Blueprint Courses is an account-level feature option.
To edit blueprint lock settings on the Pages index page, Courses - add / edit / delete must also be enabled. If this permission is not enabled, and Courses - add / edit / delete​ is enabled, blueprint lock settings can be edited on individual pages.`)
    },
    {
      title: I18n.t('Pages'),
      description: I18n.t(
        `Students can edit and view page history if allowed in the individual page options.`
      )
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        `Allows user to edit blueprint lock settings on the Pages index page in a Blueprint master course.`
      )
    },
    {
      title: I18n.t('Pages'),
      description: I18n.t(`Allows user to view, create, edit, delete, and publish/unpublish pages.
Allows user to view page history and set front page.`)
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(`Blueprint courses must be enabled for an account by an admin.
Course roles can only manage content in Blueprint Courses if they are added to the Blueprint Course as an teacher, TA, or designer role.
If this permission is disabled, a user can still adjust content lock settings on individual pages in a Blueprint master course.`)
    },
    {
      title: I18n.t('Pages'),
      description: I18n.t(
        `Students can edit and view page history if allowed in the individual page options.`
      )
    }
  ]
)

const questionBankPermissions = generateActionTemplates(
  'read_question_banks',
  [
    {
      title: I18n.t('Question Banks'),
      description: I18n.t(
        `Allows user to view and link questions in a quiz to account-level question banks. If disabled, user will only be able to view and link to course question banks.`
      )
    }
  ],
  [
    {
      title: I18n.t('Quizzes and Question Banks'),
      description: I18n.t(
        `Users can access the Manage Question Banks link on the Quizzes Index Page when Course content - view and Assignments and Quizzes - add / edit / delete are enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Question Banks'),
      description: I18n.t(`Allows user to view and link questions in a quiz to account-level question
banks. If disabled, user will only be able to view and link to course question banks. Enables the Manage Question Banks link on the Quizzes Index Page`)
    }
  ],
  [
    {
      title: I18n.t('Quizzes and Question Banks'),
      description: I18n.t(`This permission does not affect ability to manage course level question banks in Quizzes. Instead, Manage Question Banks is dependent on the Assignments and Quizzes - add / edit / delete permission.
For full management of course question banks, this permission and Assignments and Quizzes - add / edit / delete must both be enabled.`)
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
      title: I18n.t('Quizzes'),
      description: I18n.t('The Quiz Log Auditing feature option must be enabled in Course Settings.')
    }
  ],
  [],
  []
)

const rubricsAddPermissions = generateActionTemplates(
  'manage_rubrics',
  [
    {
      title: I18n.t('Rubrics'),
      description: I18n.t(`Allows user to create, edit, and delete rubrics.`)
    }
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(
        `If this permission is disabled, users can still create or add rubrics to assignments if Assignments and Quizzes - add / edit / delete is enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Rubrics'),
      description: I18n.t(
        `Allows user to create, edit, and delete course rubrics in the Rubrics link.`
      )
    }
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(
        `If this permission is disabled, users can still create or add rubrics to assignments if Assignments and Quizzes - add / edit / delete is enabled.`
      )
    }
  ]
)

const sisDataReadPermissions = generateActionTemplates(
  'read_sis',
  [
    {
      title: I18n.t('SIS'),
      description: I18n.t(`Governs account-related SIS IDs (i.e., subaccount SIS ID).`)
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to view a course’s SIS ID.')
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t('Allows a user to view the SIS ID in a user’s login details.')
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t('Allows a user to view user SIS IDs in a course People page.')
    }
  ],
  [
    {
      title: I18n.t('Account and Subaccount'),
      description: I18n.t(`Users and terms are located at the account, so the SIS endpoint always confirms the user’s permissions according to account. Subaccounts only have ownership of courses and sections; they do not own user data.
Subaccount admins are not able to view SIS information unless they are also granted an instructor role in a course. Subaccount admins cannot view SIS information without the course association, as the instructor role has permission to read SIS data at the account level.`)
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        `To view a user’s login details, Users - view list and Modify login details for users must also both be enabled.`
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(`To view the list of users in the course, Users - view list  must also be enabled.
To add users via SIS ID, Users - add / remove students from courses ​and/or Users - add / remove teachers, course designers, or TAs from courses must also be enabled.`)
    },
    {
      title: I18n.t('SIS Import'),
      description: I18n.t(
        `To manage SIS data, SIS Data - manage​ must be enabled. If SIS Data - manage ​is enabled and SIS Data - read is disabled, the account permission overrides the course permission. If SIS Data - manage ​is disabled and SIS Data - read​ is enabled, users can only view course, user, and subaccount SIS IDs. To disallow users from viewing any SIS IDs at the course level, SIS Data - manage​ and SIS Data - read​ must both be disabled.`
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
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        'To view the list of users in the course, Users - view list must also be enabled. To add users via SIS ID, Users - add / remove students from courses​ and/or Users - add / remove teachers, course designers, or TAs from courses ​ to the course must also be enabled.'
      )
    }
  ]
)

const studentCollabPermissions = generateActionTemplates(
  'create_collaborations',
  [
    {
      title: I18n.t('Collaborations'),
      description: I18n.t(
        `Allows user to create collaborations. Allows user to view, edit, and delete collaborations they created.`
      )
    }
  ],
  [
    {
      title: I18n.t('Collaborations'),
      description: I18n.t(
        `To allow view/edit/delete functionality of collaborations created by other users, Course Content - add / edit / delete must also be enabled. If Course Content - add / edit / delete​ is enabled and Student Collaborations - create is disabled, user will not be able to create new collaborations but will be able to view/edit/delete all collaborations. To add students to a collaboration, Users - view list​​ must also be enabled. To add a course group to a collaboration, Group view all student groups​ must also be enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Collaborations'),
      description: I18n.t(
        `Allows user to create collaborations. Allows user to view, edit, and delete conferences they created.`
      )
    }
  ],
  [
    {
      title: I18n.t('Collaborations'),
      description: I18n.t(
        `To allow view, edit, and delete functionality of collaborations created by other users, Course Content - add / edit / delete must also be enabled.
If Course Content - add / edit / delete is enabled and Student Collaborations - create is disabled, user will not be able to create new collaborations but will be able to view, edit, and delete all collaborations.
To add students to a collaboration, Users - view list must also be enabled. To add a course group to a collaboration, Groups - add / edit / delete must also be enabled.`
      )
    }
  ]
)

const submissionViewCommentsPermissions = generateActionTemplates(
  'comment_on_others_submissions',
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(`Allows user to view all student assignment submissions and add comments.`)
    },
    {
      title: I18n.t('SpeedGrader'),
      description: I18n.t(`Allows user to download all comments in a student’s submission.`)
    }
  ],
  [
    {
      title: I18n.t('Assignments, Gradebook'),
      description: I18n.t(`To access assignment submissions through Assignments and the
Gradebook, Grades - view all grades​ must also be enabled.`)
    },
    {
      title: I18n.t('Assignments, SpeedGrader'),
      description: I18n.t(`To access assignment submissions through Assignments and SpeedGrader, Grades - edit​ must also be enabled.
To edit a grade or add comments in SpeedGrader or the Gradebook, Grades - edit must also be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(`Allows user to view all student assignment submissions and add comments.`)
    },
    {
      title: I18n.t('SpeedGrader'),
      description: I18n.t(`Allows user to download all comments in a student’s submission.`)
    }
  ],
  [
    {
      title: I18n.t('Assignments, Gradebook'),
      description: I18n.t(
        `To access assignment submissions through Assignments or the Gradebook and view in SpeedGrader, Grades - view all grades ​or Grades - edit must also be enabled.`
      )
    },
    {
      title: I18n.t('Gradebook, SpeedGrader'),
      description: I18n.t(
        `To edit a grade or add comments in SpeedGrader or Gradebook, Grades - edit must be enabled.`
      )
    }
  ]
)

const pairingCodePermissions = generateActionTemplates(
  'generate_observer_pairing_code',
  [
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        `Allows user to generate a pairing code on behalf of a student to share with an observer.`
      )
    }
  ],
  [
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(`To generate a pairing code from a student's User Settings page, the User - act as permission must also be enabled.
To generate a pairing code from a student's User Details page, the Users - add / remove students from courses permission must also be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        `Allows user to generate a pairing code on behalf of a student to share with an observer.`
      )
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(`To generate a pairing code from a student's User Details page, the Users - add / remove students in courses permission must also be enabled.`)
    }
  ]
)

const courseAddRemovePermissions = generateActionTemplates(
  'manage_students',
  [
    {
      title: I18n.t('Courses (Account)'),
      description: I18n.t('Allows user to add students to a course from the account Courses page.')
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'Allows user to add/remove students. Allows user to add/remove observers.Allows user to view login ID information for students. Allows user to view prior enrollments. Allows user to access a user’s settings menu and user details. Allows user to edit a student’s section or role. Allows user to resend course invitations from the Course People page.'
      )
    }
  ],
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(
        'If the Open Registration account setting is enabled, users with this permission can add students or observers to a course via email address or login ID even if the student or observer does not already have a Canvas account.'
      )
    },
    {
      title: I18n.t('Courses (Account)'),
      description: I18n.t(
        'To access the account Courses page, Courses - view list must be enabled.'
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        `To view the list of users in the course, Users - view list​ must be enabled.
To view SIS IDs, SIS Data - read​ must be enabled. To add a user to a course via SIS ID, SIS Data - manage​ must also be enabled.
To edit a student's section and course role, Users - view list and Conversations - send messages to individual course members​ must also be enabled.
To unenroll users the user details page, View the list of courses and See the list of users must also be enabled.
Allows user to resend course invitations from the Course People page.
If the Open Registration account setting is enabled, users with this permission can add students to a course from the Course People page via email addresses if the user does not already have a Canvas account.
To link an observer to a student, Users - manage login details and Conversations - send to individual course members must be enabled.
`
      )
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(`Allows user to add/remove students to the course.
Allows user to add/remove observers to the course.
Allows user to view login ID information for students.
Allows user to view prior enrollments.
Allows user to access a user’s settings menu and user details.
Allows user to conclude or delete enrollments on a student’s details page.
Allows user to resend course invitations.`)
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        `To access the People Page, Users - view list​ must be enabled.
If the Open Registration account setting is enabled, users with this permission can add students to a course via email address if the user does not already have a Canvas account.
To view SIS IDs, SIS Data - read​ must be enabled. To add a user to a course via SIS ID, SIS Data - manage​ must also be enabled.
To edit a student’s section, Users - view list and Conversations - send messages to individual course members must also be enabled.
To link an observer to a student, Conversations - send messages to individual course members must also be enabled.`
   )
    }
  ]
)

const courseAddRemoveDesignerPermissions = generateActionTemplates(
  'manage_admin_users',
  [
    {
      title: I18n.t('Courses (Account)'),
      description: I18n.t(
        'Allows user to add teachers, course designers, or TAs to a course from the account Courses page.'
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(`Allows user to add/remove other teachers, course designers, or TAs.
Allows user to add/remove observers.
Allows user to view login ID information for teachers, designers, and TAs.
Allows user to view user details for any user.
Allows user to edit a user’s section or role.`)
    }
  ],
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(
        `If the Open Registration account setting is enabled, users with this permission can add students or observers to a course via email address or login ID even if the student or observer does not already have a Canvas account.`
      )
    },
    {
      title: I18n.t('Courses (Account)'),
      description: I18n.t(
        'To access the account Courses page, Courses - view list must be enabled.'
      )
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(`To view the list of users in the course, Users - view list​ must be enabled.
To view SIS IDs, SIS Data - read​ must be enabled. To add a user to a course via SIS ID, SIS Data - manage​ must also be enabled.
To edit a teacher or TA's section, Conversations - send messages to individual course members must also be enabled.
To link an observer to a student, Conversations - send messages to individual course members must also be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(`Allows user to add/remove other teachers, course designers, or TAs.
Allows user to add/remove observers to the course.
Allows user to view login ID information for teachers, designers, and TAs.
Allows user to view settings menu for teachers, course designers, TAs, and observers.
Allows user to view user details for teachers, course designers, and TAs.
Allows user to limit students to only view fellow section members.`)
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(`To view the list of users in the course, Users - view list​ must be enabled.
To view SIS IDs, SIS Data - read​ must be enabled.
To edit a teacher or TAs section, Users - view list and Conversations - send messages to individual course members must also be enabled.
To link an observer to a student, Conversations - send messages to individual course members must also be enabled.`)
    }
  ]
)

const usersViewListPermissions = generateActionTemplates(
  'read_roster',
  [
    {
      title: I18n.t('Account Navigation'),
      description: I18n.t(`Allows user to access the Users link in Account Navigation.`)
    },
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(`Allows user to view login/logout activity of users in Admin Tools.
Allows user to search grade change logs by grader or student in Admin Tools`)
    },
    {
      title: I18n.t('Assignments'),
      description: I18n.t(`Allows user to differentiate assignments to individual students.`)
    },
    {
      title: I18n.t('Collaborations'),
      description: I18n.t(`Allows user to view and add users in a collaboration.`)
    },
    {
      title: I18n.t('Conversations'),
      description: I18n.t(
        `Allows user to send a message in Conversations without selecting a course.`
      )
    },
    {
      title: I18n.t('Course Navigation'),
      description: I18n.t(`Allows user to view the People link in Course Navigation.`)
    },
    {
      title: I18n.t('Groups (Course)'),
      description: I18n.t(`Allows user to view groups in a course.`)
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(`Allows user to view list of users in the account.`)
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(`Allows user to view list of users in the course People page.
Allows user to view the Prior Enrollments button in the course People page.`)
    },
  ],
  [
    {
      title: I18n.t('Account Groups'),
      description: I18n.t(
        `To view account-level groups, Groups - add / edit / delete must also be enabled.`
      )
    },
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(
        `To generate login/logout activity in Admin Tools, Users - manage login details​ or Statistics - view must also be enabled.To generate grade change logs in Admin Tools, Grades - view change logs must also be enabled.`
      )
    },
    {
      title: I18n.t('Courses'),
      description: I18n.t(`To add users to a course, Users - add / remove students from courses for the course ​and/or Users - add / remove teachers, course designers, or TAs from courses  ​must
also be enabled.`)
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(`To edit user details, modify login details, or change user passwords, Users - manage login details ​must also be enabled.
To view user page views, Statistics - view must also be enabled.
To act as other users, Users - act as must also be enabled.`)
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(`To edit a student’s section, Users - add / remove students from courses​ and Send messages to individual course members​ must also be enabled.
To edit a teacher, TA, or course designer’s section, Users - add / remove teachers, course designers, or TAs from courses to the course​ and Conversations - send messages to individual course members must also be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(`Allows user to differentiate assignments to individual students.`)
    },
    {
      title: I18n.t('Collaborations'),
      description: I18n.t(`Allows user to view and add users in a collaboration.`)
    },
    {
      title: I18n.t('Course'),
      description: I18n.t(`Navigation Allows user to view the People link in Course Navigation.`)
    },
    {
      title: I18n.t('Groups'),
      description: I18n.t(`Allows user to view groups in a course.`)
    },
    {
      title: I18n.t('People'),
      description: I18n.t(`Allows user to view list of users in the course People page.
Allows user to view the Prior Enrollments button in the course People page.`)
    },
    {
      title: I18n.t('Settings'),
      description: I18n.t(`Allows user to view enrollments on the Sections tab.`)
    }
  ],
  [
    {
      title: I18n.t('Conversations'),
      description: I18n.t(
        `To send a message to an individual user, Conversations - send messages to individual course members must also be enabled.`
      )
    },
    {
      title: I18n.t('Groups'),
      description: I18n.t(
        `To add, edit, or delete groups, Groups - add / edit / delete must also be enabled.`
      )
    },
    {
      title: I18n.t('People'),
      description: I18n.t(`To add users to a course, Users - add / remove students from courses and/or Users - add / remove teachers, course designers, or TAs from courses must also be enabled.
To edit a student’s section, Conversations - send messages to individual course members and Users - add / remove students from courses​ must also both be enabled.
To edit a teacher, course designer, or TAs section, Conversations - send messages to individual course members ​ and Users - add / remove teachers, course designers, or TAs from courses​ must also both be enabled.`)
    }
  ]
)

const usersViewLoginPermissions = generateActionTemplates(
  'view_user_logins',
  [
    {
      title: I18n.t('People (Account/Course)'),
      description: I18n.t(`Allows user to search for other users by Login ID in the account People page.`)
    }
  ],
  [
    {
      title: I18n.t('People (Account/Course)'),
      description: I18n.t(`To access the People page, Users - view list must be enabled. If this permission is enabled, and if Users - view primary email address is disabled, users will see email addresses used as login IDs. To view login IDs, Users - add / remove students in courses and Users - add / remove teachers, course designers, or TAs in courses must also be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(`Allows user to search for other users by Login ID in the course People page.`)
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(`To access the People page, Users - view list must be enabled. If this permission is enabled, and if Users - view primary email address is disabled, users will see email addresses used as login IDs. To view login IDs, Users - add / remove students in courses and Users - add / remove teachers, course designers, or TAs in courses must also be enabled.`)
    }
  ]
)

const usersViewEmailPermissions = generateActionTemplates(
  'read_email_addresses',
  [
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        `Allows user to search for account users via primary email address in the account People page.
Allows user to search for other users via primary email address in a course People page.`
      )
    }
  ],
  [
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(`To view the account People page, Users - view list must be enabled. If this permission is disabled, and Users - view login IDs is enabled, users will still see email addresses used as login IDs.`)
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        `Allows user to search for other users via primary email addresses in the People page.`
      )
    }
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(`To access the People page, Users - view list must be enabled.

If this permission is disabled, and Users - view login IDs is enabled, users will still see email addresses used as login IDs.`)
    }
  ]
)

const webConferencesPermissions = generateActionTemplates(
  'create_conferences',
  [
    {
      title: I18n.t('Conferences'),
      description: I18n.t(
        `Allows user to create new conferences. Allows user to start conferences they created.`
      )
    }
  ],
  [
    {
      title: I18n.t('Conferences'),
      description: I18n.t(`To allow full management of conferences created by the user or others, Course Content - add / edit / delete​ must also be enabled.
To end a long-running conference, Course Content - add / edit / delete​ must be enabled.
If Course Content - add / edit / delete is enabled and Web Conferences - create is disabled, user can still manage conferences.
This permission controls a user’s ability to create conferences in courses and groups.`)
    }
  ],
  [
    {
      title: I18n.t('Conferences'),
      description: I18n.t(
        `Allows user to create new conferences. Allows user to start conferences they created.`
      )
    }
  ],
  [
    {
      title: I18n.t('Conferences'),
      description: I18n.t(`To allow full management of conferences created by the user or others, Course Content - add / edit / delete​ must also be enabled.
  To end a long-running conference, Course Content - add / edit / delete​ must be enabled.
  If Course Content - add / edit / delete is enabled and Web Conferences - create is disabled, user can still manage conferences.
  This permission controls a user’s ability to create conferences in courses and groups.`)
    }
  ]
)

export const PERMISSION_DETAILS_ACCOUNT_TEMPLATES = {
  ...deepMergeAll([
    accountLevelPermissions.ACCOUNT,
    courseCalenderPermissions.ACCOUNT,
    adminsLevelPermissions.ACCOUNT,
    alertPermissions.ACCOUNT,
    analyticsViewPermissions.ACCOUNT,
    announcementsViewPermissions.ACCOUNT,
    assignmentsQuizzesPermissions.ACCOUNT,
    assignmentsAndQuizzes.ACCOUNT,
    blueprintCoursePermissions.ACCOUNT,
    courseAddDeletePermissions.ACCOUNT,
    courseAddRemovePermissions.ACCOUNT,
    courseAddRemoveDesignerPermissions.ACCOUNT,
    courseUndeletePermissions.ACCOUNT,
    courseViewChangePermissions.ACCOUNT,
    courseViewUsagePermissions.ACCOUNT,
    courseContentAddPermissions.ACCOUNT,
    courseCalenderPermissions.ACCOUNT,
    courseContentViewPermissions.ACCOUNT,
    courseFilesAddPermissions.ACCOUNT,
    courseListViewPermissions.ACCOUNT,
    courseSectionsViewPermissions.ACCOUNT,
    courseStateManagePermissions.ACCOUNT,
    developerKeysManagePermissions.ACCOUNT,
    discussionscreatePermissions.ACCOUNT,
    discussionsModerateManagePermissions.ACCOUNT,
    discussionPostPermissions.ACCOUNT,
    discussionViewPermissions.ACCOUNT,
    featureFlagsPermissions.ACCOUNT,
    finalGradePermissions.ACCOUNT,
    globalAnnouncementsPermissions.ACCOUNT,
    gradeAuditTrailPermissions.ACCOUNT,
    gradesEditPermissions.ACCOUNT,
    gradesModeratePermissions.ACCOUNT,
    gradesViewAllPermissions.ACCOUNT,
    gradesViewChangeLogPermissions.ACCOUNT,
    gradesAddEditDeletePermissions.ACCOUNT,
    groupsViewAllStudentPermissions.ACCOUNT,
    learningOutcomesAddEditDeletePermissions.ACCOUNT,
    learningOutcomesImportPermissions.ACCOUNT,
    ltiAddEditPermissions.ACCOUNT,
    messagesSentPermissions.ACCOUNT,
    messagesSentEntireClassPermissions.ACCOUNT,
    notificationsPermissions.ACCOUNT,
    pagesAddRemovePermissions.ACCOUNT,
    pairingCodePermissions.ACCOUNT,
    managePermissions.ACCOUNT,
    questionBankPermissions.ACCOUNT,
    rubricsAddPermissions.ACCOUNT,
    sisDataImportPermissions.ACCOUNT,
    sisDataManagePermissions.ACCOUNT,
    sisDataReadPermissions.ACCOUNT,
    viewStatisticsPermissions.ACCOUNT,
    storageQuotasPermissions.ACCOUNT,
    studentCollabPermissions.ACCOUNT,
    submissionViewCommentsPermissions.ACCOUNT,
    usernotesPermissions.ACCOUNT,
    usersActAsPermissions.ACCOUNT,
    usersManageLoginPermissions.ACCOUNT,
    usersObserverPermissions.ACCOUNT,
    usersViewLoginPermissions.ACCOUNT,
    usersViewListPermissions.ACCOUNT,
    usersViewEmailPermissions.ACCOUNT,
    webHooksPermissions.ACCOUNT,
    webConferencesPermissions.ACCOUNT
  ])
}

export const PERMISSION_DETAILS_COURSE_TEMPLATES = {
  ...deepMergeAll([
    accountLevelPermissions.COURSE,
    courseCalenderPermissions.COURSE,
    adminsLevelPermissions.COURSE,
    alertPermissions.COURSE,
    analyticsViewPermissions.COURSE,
    announcementsViewPermissions.COURSE,
    assignmentsQuizzesPermissions.COURSE,
    assignmentsAndQuizzes.COURSE,
    blueprintCoursePermissions.COURSE,
    courseAddDeletePermissions.COURSE,
    courseAddRemovePermissions.COURSE,
    courseAddRemoveDesignerPermissions.COURSE,
    courseUndeletePermissions.COURSE,
    courseViewChangePermissions.COURSE,
    courseViewUsagePermissions.COURSE,
    courseContentAddPermissions.COURSE,
    courseCalenderPermissions.COURSE,
    courseContentViewPermissions.COURSE,
    courseFilesAddPermissions.COURSE,
    courseListViewPermissions.COURSE,
    courseSectionsViewPermissions.COURSE,
    courseStateManagePermissions.COURSE,
    developerKeysManagePermissions.COURSE,
    discussionscreatePermissions.COURSE,
    discussionsModerateManagePermissions.COURSE,
    discussionPostPermissions.COURSE,
    discussionViewPermissions.COURSE,
    featureFlagsPermissions.COURSE,
    finalGradePermissions.COURSE,
    globalAnnouncementsPermissions.COURSE,
    gradeAuditTrailPermissions.COURSE,
    gradesEditPermissions.COURSE,
    gradesModeratePermissions.COURSE,
    gradesViewAllPermissions.COURSE,
    gradesViewChangeLogPermissions.COURSE,
    gradesAddEditDeletePermissions.COURSE,
    groupsViewAllStudentPermissions.COURSE,
    learningOutcomesAddEditDeletePermissions.COURSE,
    learningOutcomesImportPermissions.COURSE,
    ltiAddEditPermissions.COURSE,
    messagesSentPermissions.COURSE,
    messagesSentEntireClassPermissions.COURSE,
    pagesAddRemovePermissions.COURSE,
    pairingCodePermissions.COURSE,
    managePermissions.COURSE,
    questionBankPermissions.COURSE,
    rubricsAddPermissions.COURSE,
    sisDataImportPermissions.COURSE,
    sisDataManagePermissions.COURSE,
    sisDataReadPermissions.COURSE,
    viewStatisticsPermissions.COURSE,
    storageQuotasPermissions.COURSE,
    studentCollabPermissions.COURSE,
    submissionViewCommentsPermissions.COURSE,
    usernotesPermissions.COURSE,
    usersActAsPermissions.COURSE,
    usersManageLoginPermissions.COURSE,
    usersViewLoginPermissions.COURSE,
    usersViewListPermissions.COURSE,
    usersViewEmailPermissions.COURSE,
    webHooksPermissions.COURSE,
    webConferencesPermissions.COURSE
  ])
}
