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
      title: I18n.t('Account Settings:'),
      description: I18n.t(
        'Allows user to view and manage the Settings and Notifications tabs in account settings.'
      )
    },
    {
      title: I18n.t('Authentication (Account Navigation):'),
      description: I18n.t('Allows user to view and manage Authentication for the whole account.')
    },
    {
      title: I18n.t('Subaccounts:'),
      description: I18n.t('Allows user to view and manage subaccounts for the root account.')
    },
    {
      title: I18n.t('Terms:'),
      description: I18n.t('Allows user to view and manage terms for the root account.')
    },
    {
      title: I18n.t('Theme Editor:'),
      description: I18n.t('Allows user to access the Theme Editor.')
    }
  ],
  [
    {
      title: I18n.t('Announcements:'),
      description: I18n.t(
        'The Announcements tab is always visible to admins; however, to manage announcements, Global Announcements - add / edit / delete​ must also be enabled.'
      )
    },
    {
      title: I18n.t('Reports (Account Settings):'),
      description: I18n.t(
        'To view the Reports tab, Course - view usage reports must also be enabled.'
      )
    },
    {
      title: I18n.t('Account Settings (Subaccount Navigation):'),
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
      title: I18n.t('Account Settings:'),
      description: I18n.t('Allows user to add and remove other account admins.')
    },
    {
      title: I18n.t('Commons:'),
      description: I18n.t(
        'Allows user to access and edit the Admin settings in Commons. Allows user to create and manage Groups. Allows user to manage shared resources in the account.'
      )
    }
  ],
  [],
  [],
  []
)

const alertPermissions = generateActionTemplates(
  'manage_interaction_alerts',
  [
    {
      title: I18n.t('Alerts (Course Settings):'),
      description: I18n.t(
        'Allows user to configure alerts in course settings. Alerts are a seldom-used feature designed to send an alert to students, teachers or admins for specific triggers (e.g., no student/teacher interaction for 7 days). They are checked every day, and notifications will be sent to the student and/or the teacher until the triggering problem is resolved.'
      )
    }
  ],
  [
    {
      title: I18n.t('Account Settings:'),
      description: I18n.t(
        'This is an account setting that must be turned on by your Customer Success Manager.'
      )
    }
  ],
  [
    {
      title: I18n.t('Alerts (Course Settings):'),
      description: I18n.t(
        'Allows user to configure alerts in course settings. Alerts are a seldom-used feature designed to send an alert to students, teachers or admins for specific triggers (e.g., no student/teacher interaction for 7 days). They are checked every day, and notifications will be sent to the student and/or the teacher until the triggering problem is resolved.'
      )
    }
  ],
  [
    {
      title: I18n.t('Account Settings:'),
      description: I18n.t(
        'This is an account setting that must be turned on by your Customer Success Manager.'
      )
    }
  ]
)

const analyticsViewPermissions = generateActionTemplates(
  'view_analytics',
  [
    {
      title: I18n.t('Analytics (Account):'),
      description: I18n.t('Allows user to view account analytics.')
    },
    {
      title: I18n.t('Analytics (Course):'),
      description: I18n.t(
        'Allows user to view course analytics through the course dashboard. Allows user to view student analytics.'
      )
    }
  ],
  [],
  [
    {
      title: I18n.t('Analytics (Course):'),
      description: I18n.t(
        'Allows user to view course analytics through the course dashboard. Allows user to view student analytics.'
      )
    }
  ],
  [
    {
      title: I18n.t('Analytics:'),
      description: I18n.t(
        'To view student analytics in course analytics, Grades - view all grades must also be enabled'
      )
    },
    {
      title: I18n.t('Account Settings:'),
      description: I18n.t(`The analytics feature must be enabled in Account Settings to view analytics pages
To see the Analytics link in the user sidebar from the People page, Profiles must be disabled in your account`)
    },
    {
      title: I18n.t('People (Course):'),
      description: I18n.t(
        'To view student analytics, Users - view list and Grades - view all grades​ must also be enabled.'
      )
    }
  ]
)

const announcementsViewPermissions = generateActionTemplates(
  'read_announcements',
  [
    {
      title: I18n.t('Announcements:'),
      description: I18n.t(
        'Allows user to view the Announcements link in Course Navigation. Allows user to view course announcements.'
      )
    }
  ],
  [
    {
      title: I18n.t('Announcements:'),
      description: I18n.t(
        'To manage course announcements, Discussions - moderate ​must also be enabled.'
      )
    },
    {
      title: I18n.t('Global Announcements:'),
      description: I18n.t(
        'This permission only affects course announcements; to manage global announcements, Global Announcements - add / edit / delete​ must be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('Announcements:'),
      description: I18n.t(`Allows user to access the Announcements link in Course Navigation
Allows user to view course announcements
Allows user to view recent announcements on the home page`)
    }
  ],
  [
    {
      title: I18n.t('Announcements:'),
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
      title: I18n.t('Assignments:'),
      description: I18n.t(`Allows user to add, edit, delete, and publish/unpublish assignments.
Allows user to manage assignment settings.
Allows user to add assignment groups in a course.
Allows user to enable and edit assignment group weighting in a course.`)
    },
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(`Allows user to edit blueprint lock settings on the Assignments and Quizzes index
pages in a Blueprint Master Course.`)
    },
    {
      title: I18n.t('Commons:'),
      description: I18n.t(`Allows user to share a quiz to Commons.`)
    },
    {
      title: I18n.t('Discussions:'),
      description: I18n.t(
        `Allows user to edit assignment details on individual discussions. Modules: Allows user to add new assignments to a module.`
      )
    },
    {
      title: I18n.t('Modules:'),
      description: I18n.t(`Allows user to add new assignments to a module.`)
    },
    {
      title: I18n.t('Quizzes:'),
      description: I18n.t(`Allows user to add, edit, delete, and publish/unpublish quizzes.`)
    }
  ],
  [
    {
      title: I18n.t('Assignments:'),
      description: I18n.t(
        'To differentiate assignments to individual students, Users - view list ​must also be enabled.'
      )
    },
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(`Blueprint courses is an account-level feature option.
To edit blueprint lock settings from the Assignments index page, Course - add / edit / delete​ must also be enabled. If this permission is not enabled, and Course - add / edit / delete​ is enabled, blueprint lock settings for an assignment can be managed from the assignment’s details page.
To edit blueprint lock settings on an individual quiz, or on the Quizzes index page, Course - add / edit / delete​ must also be enabled.`)
    },
    {
      title: I18n.t('Grades:'),
      description: I18n.t('To manage moderated grading, Grades - moderate ​must also be enabled.')
    },
    {
      title: I18n.t('Quizzes:'),
      description: I18n.t('To moderate a quiz, Grades - edit​ must also be enabled.')
    },
    {
      title: I18n.t('Rubrics:'),
      description: I18n.t(`Disabling this permission will override (if enabled) the Rubrics - add / edit / delete ​permission, preventing user from creating or editing rubrics from an
individual assignment. However, if Learning Outcomes - add / edit / delete​ is enabled, user can still add rubrics via Outcomes – Manage Rubrics.`)
    },
    {
      title: I18n.t('Global Announcements:'),
      description: I18n.t(
        'This permission only affects course announcements; to manage global announcements, Global Announcements - add / edit / delete​ must be enabled.'
      )
    }
  ],
  [
    {
      title: I18n.t('Assignments:'),
      description: I18n.t(`Allows user to add, edit, delete, and publish/unpublish assignments.
Allows user to manage assignment settings.
Allows user to add assignment groups in a course.
Allows user to enable and edit assignment group weighting in a course.`)
    },
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(`Allows user to edit blueprint lock settings on the Assignments and Quizzes index
pages in a Blueprint Master Course.`)
    },
    {
      title: I18n.t('Commons:'),
      description: I18n.t(`Allows user to share a quiz to Commons.`)
    },
    {
      title: I18n.t('Discussions:'),
      description: I18n.t(
        `Allows user to edit assignment details on individual discussions. Modules: Allows user to add new assignments to a module.`
      )
    },
    {
      title: I18n.t('Modules:'),
      description: I18n.t(`Allows user to add new assignments to a module.`)
    },
    {
      title: I18n.t('Quizzes:'),
      description: I18n.t(`Allows user to add, edit, delete, and publish/unpublish quizzes.`)
    }
  ],
  [
    {
      title: I18n.t('Assignments:'),
      description: I18n.t(
        'To differentiate assignments to individual students, Users - view list ​must also be enabled.'
      )
    },
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(`Blueprint courses is an account-level feature option.
To edit blueprint lock settings from the Assignments index page, Course - add / edit / delete​ must also be enabled. If this permission is not enabled, and Course - add / edit / delete​ is enabled, blueprint lock settings for an assignment can be managed from the assignment’s details page.
To edit blueprint lock settings on an individual quiz, or on the Quizzes index page, Course - add / edit / delete​ must also be enabled.`)
    },
    {
      title: I18n.t('Grades:'),
      description: I18n.t('To manage moderated grading, Grades - moderate ​must also be enabled.')
    },
    {
      title: I18n.t('Quizzes:'),
      description: I18n.t('To moderate a quiz, Grades - edit​ must also be enabled.')
    },
    {
      title: I18n.t('Rubrics:'),
      description: I18n.t(`Disabling this permission will override (if enabled) the Rubrics - add / edit / delete ​permission, preventing user from creating or editing rubrics from an
individual assignment. However, if Learning Outcomes - add / edit / delete​ is enabled, user can still add rubrics via Outcomes – Manage Rubrics.`)
    },
    {
      title: I18n.t('Global Announcements:'),
      description: I18n.t(
        'This permission only affects course announcements; to manage global announcements, Global Announcements - add / edit / delete​ must be enabled.'
      )
    }
  ]
)

const assignmentsAndQuizzes = generateActionTemplates(
  'view_quiz_answer_audits',
  [
    {
      title: I18n.t('Quizzes:'),
      description: I18n.t('Allows user to view student quiz logs.')
    }
  ],
  [
    {
      title: I18n.t('Quizzes:'),
      description: I18n.t('The Quiz Log Auditing feature option must be enabled in Course Settings')
    }
  ],
  [],
  []
)

const blueprintCoursePermissions = generateActionTemplates(
  'manage_master_courses',
  [
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(`Allows user to designate a course as a Blueprint Course.
Allows user to manage Blueprint Course settings in Course Settings.
Allows user to add associated courses.`)
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(
        'Blueprint Courses is an account-level feature option. Course roles can only manage Blueprint Courses if they are added to the Blueprint Course as an teacher, TA, or designer role. To access the Blueprint Courses sidebar, Course - add / edit / delete courses must be enabled. To add an associated course, Course list - view a​nd Course - add / edit / delete must also be enabled. To edit lock settings on any blueprint object type, Course - add / edit / delete must be enabled.'
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
      title: I18n.t('Admin Tools (Restore Courses tab):'),
      description: I18n.t('Allows user to restore a course.')
    },
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(
        'Allows user to access the Blueprint Courses Sidebar. Allows user to manage Blueprint Courses content settings in Course Settings. Allows user to remove an associated course. Allows user to edit blueprint lock settings on individual assignments, pages, or discussions'
      )
    },
    {
      title: I18n.t('Courses (Account Navigation):'),
      description: I18n.t('Allows user to view and manage courses in the account.')
    },
    {
      title: I18n.t('Course Settings (Course Details tab):'),
      description: I18n.t(
        'Course Settings (Course Details tab): Allows user to access the Navigation tab in Course Settings. Allows user to access Student View (test student), Copy this Course, Reset Course Content, and Permanently Delete Course buttons. Allows user to edit course image, name, course code, time zone, subaccount, term, and other options in Course Details tab.'
      )
    },
    {
      title: I18n.t('Course:'),
      description: I18n.t(
        'Allows user to view Choose Home Page and Course Setup Checklist buttons in the Home page.'
      )
    },
    {
      title: I18n.t('Student Context Cards:'),
      description: I18n.t(
        'Allows user to view student context cards in announcement and discussion replies.'
      )
    }
  ],
  [
    {
      title: I18n.t('Account Settings:'),
      description: I18n.t(
        'If this permission is enabled and Course list - view​ is disabled, users can add a new course with the Add a New Course button in Account Settings.'
      )
    },
    {
      title: I18n.t('Admin Tools (Restore Courses tab):'),
      description: I18n.t(
        'To restore a deleted course, Course - undelete​ and Course Content - view must also both be enabled.'
      )
    },
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(
        'Blueprint Courses is an account-level feature option. To edit Blueprint Course settings in course settings, Blueprint Courses - add / edit / associate / delete​ must also be enabled. To add an associated course, Blueprint Courses - add / edit / associate / delete and Course list - view​ must also be enabled. To edit lock settings on any blueprint object, this permission must be enabled. To edit lock settings on files, Course Files - add / edit / delete must also be enabled. To edit lock settings on quizzes, Assignments and Quizzes - add / edit / delete must also be enabled.'
      )
    },
    {
      title: I18n.t('Courses (Account Navigation):'),
      description: I18n.t(
        'To cross-list a section, Course Sections - add / edit / delete ​must also be enabled. To edit the course SIS ID, SIS Data - manage​ must also be enabled. To allow an account-level user to delete a course, Course State - manage​ must also be enabled.'
      )
    },
    {
      title: I18n.t('Grades:'),
      description: I18n.t(
        'To view grades in a course, Grades - view all grades​ must also be enabled.'
      )
    },
    {
      title: 'Modules:',
      description:
        'To publish/unpublish module content, Course Content - add / edit / delete​ must be enabled.'
    },
    {
      title: I18n.t('Student Context Cards:'),
      description: I18n.t(
        'Student context cards must be enabled for an account by an admin. If this permission is not enabled, users can still view student context cards through the Gradebook.'
      )
    }
  ],
  [],
  []
)

const courseAddRemovePermissions = generateActionTemplates(
  'manage_students',
  [
    {
      title: I18n.t('Courses (Account):'),
      description: I18n.t('Allows user to add students to a course from the account Courses page.')
    },
    {
      title: I18n.t('People (Course):'),
      description: I18n.t(
        'Allows user to add/remove students to the course. Allows user to add/remove observers to the course. Allows user to view login ID information for students. Allows user to view prior enrollments. Allows user to view settings menu for students. Allows user to view user details for students. Allows user to edit a student’s section or role in the course.'
      )
    }
  ],
  [
    {
      title: I18n.t('Account Settings:'),
      description: I18n.t(
        'If the Open Registration account setting is enabled, users with this permission can add students or observers to a course via email address or login ID even if the student or observer does not already have a Canvas account.'
      )
    },
    {
      title: I18n.t('Courses (Account):'),
      description: I18n.t(
        'To access the account Courses page, Course list - view​ must be enabled.'
      )
    },
    {
      title: I18n.t('People (Course):'),
      description: I18n.t(`To view the list of users in the course, Users - view list​ must be enabled.
To view SIS IDs, SIS Data - read​ must be enabled. To add a user to a course via SIS ID, SIS Data - manage​ must also be enabled.
To edit a student’s section, Messages - send to individual course members​ must also be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('People (Course):'),
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
      title: I18n.t('People:'),
      description: I18n.t(`To access the People Page, Users - view list​ must be enabled.
If the Open Registration account setting is enabled, users with this permission can add students to a course via email address if the user does not already have a Canvas account.
To view SIS IDs, SIS Data - read​ must be enabled. To add a user to a course via SIS ID, SIS Data - manage​ must also be enabled.
To edit a student’s section, Users - view list and Messages - send to individual course members​ must also be enabled.
To link an observer to a student, Messages - send to individual course members​ must also be enabled.`)
    }
  ]
)

const courseAddRemoveDesignerPermissions = generateActionTemplates(
  'manage_admin_users',
  [
    {
      title: I18n.t('Courses (Account):'),
      description: I18n.t(
        'Allows user to add teachers, course designers or TAs to a course from the account Courses page.'
      )
    },
    {
      title: I18n.t('People (Course):'),
      description: I18n.t(`Allows user to add/remove other teachers, course designers, or TAs to the course.
Allows user to add/remove observers to the course.
Allows user to view login ID information for teachers, designers, and TAs.
Allows user to view user details for any user in the course.
Allows user to edit a user’s section or role in the course.`)
    }
  ],
  [
    {
      title: I18n.t('Account Settings:'),
      description: I18n.t(
        `If the Open Registration account setting is enabled, users with this permission can add students or observers to a course via email address or login ID even if the student or observer does not already have a Canvas account.`
      )
    },
    {
      title: I18n.t('Courses (Account):'),
      description: I18n.t(
        'To access the account Courses page, Course list - view​ must be enabled.'
      )
    },
    {
      title: I18n.t('People (Course):'),
      description: I18n.t(`To view the list of users in the course, Users - view list​ must be enabled.
To view SIS IDs, SIS Data - read​ must be enabled. To add a user to a course via SIS ID, SIS Data - manage​ must also be enabled.
To edit a teacher or TA's section, Messages - send to individual course members​ must also be enabled.
To link an observer to a student, Messages - send to individual course members must also be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('People:'),
      description: I18n.t(`Allows user to add/remove other teachers, course designers, or TAs to the course.
Allows user to add/remove observers to the course.
Allows user to view login ID information for teachers, designers, and TAs.
Allows user to view settings menu for teachers, course designers, TAs, and observers.
Allows user to view user details for teachers, course designers, and TAs in the course.
Allows user to limit students to only view fellow section members.`)
    }
  ],
  [
    {
      title: I18n.t('People:'),
      description: I18n.t(`To view the list of users in the course, Users - view list​ must be enabled.
To view SIS IDs, SIS Data - read​ must be enabled.
To edit a teahcer or TAs section, Users - view list and Messages - send to individual course members​ must also be enabled.
To link an observer to a student, Messages - send to individual course members must also be enabled.`)
    }
  ]
)

const courseUndeletePermissions = generateActionTemplates(
  'undelete_courses',
  [
    {
      title: I18n.t('Admin Tools (Restore Courses tab):'),
      description: I18n.t('Allows user to access the Restore Courses tab in Admin Too')
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Restore Courses tab):'),
      description: I18n.t(`To search for a course in the Restore Courses tab, Course Content - view must also be enabled.
         To restore a deleted course in an account, Course - add / edit / delete​, Course Content - view, and Course - undelete​ must all be enabled.`)
    }
  ],
  [],
  []
)

const courseViewChangePermissions = generateActionTemplates(
  'view_course_changes',
  [
    {
      title: I18n.t('Admin Tools (Logging tab):'),
      description: I18n.t(
        'Determines visibility of the Course Activity option in the Admin Tools Logging tab. Allows user to view course activity information for the account.'
      )
    },
    {
      title: I18n.t('Scheduler:'),
      description: I18n.t(
        'Allows user to create and manage appointments on the calendar using Scheduler.'
      )
    }
  ],
  [],
  [],
  []
)

const courseViewUsagePermissions = generateActionTemplates(
  'read_reports',
  [
    {
      title: I18n.t('Reports:'),
      description: I18n.t(`Allows user to view and configure reports in Account Settings.
Allows user to view Access Reports and Student Interaction reports.
Allows user to view last activity and total activity information on the People page.`)
    }
  ],
  [
    {
      title: I18n.t('People (Course):'),
      description: I18n.t(
        `To access the course people page, Users - view list must also be enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Course Settings:'),
      description: I18n.t(`Allows user to view the Course Statistics button in Course Settings.`)
    },
    {
      title: I18n.t('People:'),
      description: I18n.t(
        `Allows user to view Last Activity and Total Activity information on the People page`
      )
    },
    {
      title: I18n.t('Reports:'),
      description: I18n.t(
        `Allows user to view Last Activity, Total Activity, and Student Interactions reports`
      )
    }
  ],
  [
    {
      title: I18n.t('People:'),
      description: I18n.t(`To access the People Page, Users - view list​ must be enabled.`)
    }
  ]
)

const courseContentAddPermissions = generateActionTemplates(
  'manage_content',
  [
    {
      title: I18n.t('Attendance:'),
      description: I18n.t(`Allows teacher/TA-based roles to access the Attendance tool.`)
    },
    {
      title: I18n.t('Chat:'),
      description: I18n.t(`Allows teacher/designer/TA-based roles to access the Chat tool.`)
    },
    {
      title: I18n.t('Collaborations:'),
      description: I18n.t(`Allows user to view previously created collaborations.
Allows user to edit title, description, or remove collaborators on all collaborations.`)
    },
    {
      title: I18n.t('Commons:'),
      description: I18n.t(`Allows user to import resources from Commons into a course.
Allows user to share assignments to Commons or edit previously shared content.`)
    },
    {
      title: I18n.t('Conferences:'),
      description: I18n.t(`Allows users to edit Conferences.`)
    },
    {
      title: I18n.t('Course Navigation:'),
      description: I18n.t(`Allows user to view Course Status, Choose Home Page, and Course Setup
Checklist buttons in the Home page.`)
    },
    {
      title: I18n.t('Course Settings:'),
      description: I18n.t(`Allows user to import content using the Course Import Tool.`)
    },
    {
      title: I18n.t('Modules:'),
      description: I18n.t(`Allows user to manage modules (create, add items, edit module settings,
publish/unpublish, etc.).`)
    },
    {
      title: I18n.t('Syllabus:'),
      description: I18n.t(`Allows user to edit the course syllabus.`)
    }
  ],
  [
    {
      title: I18n.t('Attendance:'),
      description: I18n.t(`The Attendance tool must be enabled by your Canvas admin.`)
    },
    {
      title: I18n.t('Chat:'),
      description: I18n.t(`The Chat tool must be enabled by your Canvas admin.`)
    },
    {
      title: I18n.t('Commons:'),
      description: I18n.t(
        `To share a Discussion to Commons, Discussions - view​ must also be enabled.`
      )
    },
    {
      title: I18n.t('Conferences:'),
      description: I18n.t(`Allows users to edit Conferences.`)
    },
    {
      title: I18n.t('Course Settings:'),
      description: I18n.t(
        `The Course Status buttons (unpublished and published) are only displayed until a student submission is received. Courses cannot be unpublished with student submissions.`
      )
    },
    {
      title: I18n.t('Modules:'),
      description: I18n.t(
        `To publish and unpublish module content, Course - add / edit / delete and Course Content - view​ must also be enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Attendance:'),
      description: I18n.t(`Allows teacher/TA-based roles to access the Attendance tool.`)
    },
    {
      title: I18n.t('Chat:'),
      description: I18n.t(`Allows teacher/designer/TA-based roles to access the Chat tool.`)
    },
    {
      title: I18n.t('Collaborations:'),
      description: I18n.t(`Allows user to view previously created collaborations.
Allows user to edit title, description, or remove collaborators on all collaborations.`)
    },
    {
      title: I18n.t('Commons:'),
      description: I18n.t(`Allows user to import resources from Commons into a course.
Allows user to share assignments to Commons or edit previously shared content.`)
    },
    {
      title: I18n.t('Conferences:'),
      description: I18n.t(`Allows users to edit Conferences.`)
    },
    {
      title: I18n.t('Course Navigation:'),
      description: I18n.t(`Allows user to view Course Status, Choose Home Page, and Course Setup
Checklist buttons in the Home page.`)
    },
    {
      title: I18n.t('Course Settings:'),
      description: I18n.t(`Allows user to import content using the Course Import Tool.`)
    },
    {
      title: I18n.t('Modules:'),
      description: I18n.t(`Allows user to manage modules (create, add items, edit module settings,
publish/unpublish, etc.).`)
    },
    {
      title: I18n.t('Syllabus:'),
      description: I18n.t(`Allows user to edit the course syllabus.`)
    }
  ],
  [
    {
      title: I18n.t('Attendance:'),
      description: I18n.t(`The Attendance tool must be enabled by your Canvas admin.`)
    },
    {
      title: I18n.t('Chat:'),
      description: I18n.t(`The Chat tool must be enabled by your Canvas admin.`)
    },
    {
      title: I18n.t('Commons:'),
      description: I18n.t(
        `To share a Discussion to Commons, Discussions - view​ must also be enabled.`
      )
    },
    {
      title: I18n.t('Conferences:'),
      description: I18n.t(`Allows users to edit Conferences.`)
    },
    {
      title: I18n.t('Course Settings:'),
      description: I18n.t(
        `The Course Status buttons (unpublished and published) are only displayed until a student submission is received. Courses cannot be unpublished with student submissions.`
      )
    },
    {
      title: I18n.t('Modules:'),
      description: I18n.t(
        `To publish and unpublish module content, Course - add / edit / delete and Course Content - view​ must also be enabled.`
      )
    }
  ]
)

const courseCalenderPermissions = generateActionTemplates(
  'manage_calendar',
  [
    {
      title: I18n.t('Calendar:'),
      description: I18n.t('Allows user to add, edit, and delete events in the course calendar.')
    },
    {
      title: I18n.t('Scheduler:'),
      description: I18n.t(
        'Allows user to create and manage appointments on the calendar using Scheduler.'
      )
    }
  ],
  [
    {
      title: I18n.t('Calendar:'),
      description: I18n.t(
        'Regardless of whether this permission is enabled or disabled, the user will still be able to manage events on their personal calendar.'
      )
    },
    {
      title: I18n.t('Scheduler:'),
      description: I18n.t('Scheduler must be enabled by your Canvas admin.')
    }
  ],
  [
    {
      title: I18n.t('Calendar:'),
      description: I18n.t('Allows user to add, edit, and delete events in the course calendar.')
    },
    {
      title: I18n.t('Scheduler:'),
      description: I18n.t(
        'Allows user to create and manage appointments on the calendar using Scheduler.'
      )
    }
  ],
  [
    {
      title: I18n.t('Scheduler:'),
      description: I18n.t('Scheduler must be enabled by your Canvas admin.')
    }
  ]
)

const courseContentViewPermissions = generateActionTemplates(
  'read_course_content',
  [
    {
      title: I18n.t('Courses:'),
      description: I18n.t('Allows user to view published and unpublished course content.')
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Undelete Courses):'),
      description: I18n.t(
        'Regardless of whether this permission is enabled or disabled, the user will still be able to manage events on their personal calendar.'
      )
    },
    {
      title: I18n.t('Courses:'),
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
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(
        'Allows user to edit blueprint lock settings on the Files page in a Blueprint Master Course.'
      )
    },
    {
      title: I18n.t('Files:'),
      description: I18n.t(`Allows user to add, edit, and delete course files and folders.
Allows user to download files into a zip file, import a zip file, and lock/unlock files.`)
    },
    {
      title: I18n.t('Rich Content Editor:'),
      description: I18n.t(`Allows user to access the Files tab in the Content Selector`)
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(`Blueprint courses must be enabled for an account by an admin.
To edit blueprint lock settings for files, Course - add / edit / delete must
also be enabled.`)
    },
    {
      title: I18n.t('Files:'),
      description: I18n.t(`If disabled, user can still view and download files into a zip file.`)
    },
    {
      title: I18n.t('Settings:'),
      description: I18n.t(
        `To import files using the Course Import Tool, Course Content - add / edit / delete must also be enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(
        'Allows user to edit blueprint lock settings on the Files page in a Blueprint Master Course.'
      )
    },
    {
      title: I18n.t('Files:'),
      description: I18n.t(`Allows user to add, edit, and delete course files and folders.
Allows user to download files into a zip file, import a zip file, and lock/unlock files.`)
    },
    {
      title: I18n.t('Rich Content Editor:'),
      description: I18n.t(`Allows user to access the Files tab in the Content Selector`)
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(`Blueprint courses must be enabled for an account by an admin.
To edit blueprint lock settings for files, Course - add / edit / delete must
also be enabled.`)
    },
    {
      title: I18n.t('Files:'),
      description: I18n.t(`If disabled, user can still view and download files into a zip file.`)
    },
    {
      title: I18n.t('Settings:'),
      description: I18n.t(
        `To import files using the Course Import Tool, Course Content - add / edit / delete must also be enabled.`
      )
    }
  ]
)

const courseListViewPermissions = generateActionTemplates(
  'Course list - view',
  [
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(`Allows user to filter for blueprint courses as the account-level.
Allows user to add associated courses.`)
    }
  ],
  [
    {
      title: I18n.t('Account Settings:'),
      description: I18n.t(`If this permission is disabled and Course - add / edit / delete​ is enabled,
users can add a new course with the Add a New Course button in Account
Settings.`)
    },
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(`Blueprint Courses is an account-level feature option.

To add associated courses, Blueprint Courses - add / edit / associate / delete and Course - add / edit / delete​ must also be enabled.`)
    },
    {
      title: I18n.t('Statistics:'),
      description: I18n.t(
        `Allows user to see the list of recently started/ended courses in account statistics.`
      )
    }
  ],
  [],
  []
)

const courseSectionsViewPermissions = generateActionTemplates(
  'manage_sections',
  [
    {
      title: I18n.t('Course Settings (Sections tab):'),
      description: I18n.t(`Allows user to add, edit, and delete course sections.
Allows user to cross-list sections.`)
    }
  ],
  [
    {
      title: I18n.t('Course Settings (Sections tab):'),
      description: I18n.t(`The user must also be enrolled as an instructor in the courses they are trying to cross-list.
To cross-list sections, Course - add / edit / delete​ must also be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('Course Settings (Sections tab):'),
      description: I18n.t(`Allows user to add, edit, and delete course sections.
Allows user to cross-list sections.`)
    }
  ],
  [
    {
      title: I18n.t('Course Settings (Sections tab):'),
      description: I18n.t(`The user must also be enrolled as an instructor in the courses they are trying to cross-list.
To cross-list sections, Course - add / edit / delete​ must also be enabled.`)
    }
  ]
)

const courseStateManagePermissions = generateActionTemplates(
  'change_course_state',
  [
    {
      title: I18n.t('Course Home Page and Course Setup Checklist:'),
      description: I18n.t(`Determines whether a Publish Course option is included in the Course Setup
Checklist and in the Course Home Page.`)
    },
    {
      title: I18n.t('Course Settings:'),
      description: `For course-level users, deleting a course is part of the Change Course State permission. However, for account-level users, deleting a course requires this permission and Course - add / edit / delete​.`
    }
  ],
  [
    {
      title: I18n.t('Course Settings:'),
      description: I18n.t(`Affects viewing the Publish Course and Conclude Course buttons.`)
    },
    {
      title: I18n.t('Modules:'),
      description: I18n.t(
        `The Change Course State permission allows users to publish courses that do not contain modules. To publish/unpublish module content, Course Content - add / edit / delete​ must be enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Course:'),
      description: I18n.t(`Allows user to publish, conclude, and delete courses.`)
    }
  ],
  [
    {
      title: I18n.t('Course Settings:'),
      description: I18n.t(`Affects viewing the Publish Course, Conclude Course, and Permanently Delete this Course buttons.
The Permanently Delete this Course button only appears for manually created courses.`)
    },
    {
      title: I18n.t('Course Setup Checklist, Course Homepage:'),
      description: I18n.t(
        `Determines whether a Publish Course option is included in the Course Setup Checklist and in the Course Home Page.`
      )
    }
  ]
)

const developerKeysManagePermissions = generateActionTemplates(
  'manage_developer_keys',
  [
    {
      title: I18n.t('Developer Keys (Account Navigation):'),
      description: I18n.t(`Allows user to create developer keys for root accounts.`)
    }
  ],
  [
    {
      title: I18n.t('Developer Keys:'),
      description: I18n.t(
        `Required fields include key name, owner email, tool ID, redirect URL, and icon URL.`
      )
    },
    {
      title: I18n.t('Subaccounts:'),
      description: I18n.t(`Not available at the subaccount level.`)
    }
  ],
  [],
  []
)

const discussionsModerateManagePermissions = generateActionTemplates(
  'moderate_forum',
  [
    {
      title: I18n.t('Announcements:'),
      description: I18n.t(`Allows user to view the New Announcement button in the Home page.
Allows user to add announcements in the Announcements page.`)
    },
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(
        `Allows user to edit blueprint lock settings on the Discussions index page in a Blueprint Master Course.`
      )
    },
    {
      title: I18n.t('Discussions:'),
      description: I18n.t(`Allows user to add discussions in the Discussions page.
Allows user to close for comments, move, pin/unpin, edit, and delete discussion topics created by other users.`)
    }
  ],
  [
    {
      title: I18n.t('Announcements:'),
      description: I18n.t(`To view announcements, Announcements - view must also be enabled.`)
    },
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(
        `Blueprint Courses is an account-level feature option. To edit blueprint lock settings on the Discussions index page, Course - add / edit / delete​ and Discussions - view​ must also be enabled. If this permission is not enabled, and Course - add / edit / delete​ and Discussions - view​ are enabled, blueprint lock settings can be edited on individual discussions.`
      )
    },
    {
      title: I18n.t('Discussions:'),
      description: I18n.t(`To view discussions in a course, Discussions - view​ must be enabled.
To reply to a discussion, Discussions - post must also be enabled.
To edit assignment details on a discussion, Assignments and Quizzes - add / edit / delete must also be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('Announcements:'),
      description: I18n.t(`Allows user to view the New Announcement button in the Home page.
Allows user to add announcements in the Announcements page.`)
    },
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(
        `Allows user to edit blueprint lock settings on the Discussions index page in a Blueprint Master Course.`
      )
    },
    {
      title: I18n.t('Discussions:'),
      description: I18n.t(`Allows user to add discussions in the Discussions page.
Allows user to close for comments, move, pin/unpin, edit, and delete discussion topics created by other users.`)
    }
  ],
  [
    {
      title: I18n.t('Announcements:'),
      description: I18n.t(`To view announcements, Announcements - view must also be enabled.`)
    },
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(`Blueprint courses must be enabled for an account by an admin.
Course roles can only manage content in Blueprint Courses if they are added to the Blueprint Course as an teacher, TA, or designer role.
If this setting is disabled, and Discussions - view​ is enabled, a user can still adjust content lock settings on individual discussions in a Blueprint Master Course`)
    },
    {
      title: I18n.t('Discussions:'),
      description: I18n.t(`To view discussions in a course, Discussions - view​ must be enabled.
To reply to a discussion, Discussions - post​ must also be enabled. To edit assignment details on a discussion, Assignments and Quizzes - add / edit / delete must also be enabled.`)
    }
  ]
)

const discussionPostPermissions = generateActionTemplates(
  'post_to_forum',
  [
    {
      title: I18n.t('Discussions:'),
      description: I18n.t(`Allows user to reply to a discussion post.`)
    }
  ],
  [
    {
      title: I18n.t('Discussions:'),
      description: I18n.t(`To view discussions in a course, Discussions - view must also be enabled.
To manage discussions, Discussions - moderate must be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('Discussions:'),
      description: I18n.t(`Allows user to reply to a discussion post.`)
    }
  ],
  [
    {
      title: I18n.t('Discussions:'),
      description: I18n.t(`To view discussions in a course, Discussions - view​ must also be enabled.
To manage discussions, Discussions - moderate must be enabled.`)
    }
  ]
)

const discussionViewPermissions = generateActionTemplates(
  'read_forum',
  [
    {
      title: I18n.t('Discussions:'),
      description: I18n.t(`Allows user to reply to a discussion post.`)
    }
  ],
  [
    {
      title: I18n.t('Discussions:'),
      description: I18n.t(`To view discussions in a course, Discussions - view must also be enabled.
To manage discussions, Discussions - moderate must be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('Groups:'),
      description: I18n.t(`Allows user to view the group home pages of all student groups
Allows students to access other student groups within a group set with a direct
link`)
    }
  ],
  [
    {
      title: I18n.t('Groups:'),
      description: I18n.t(`By default students are able to create groups; to restrict students from creating
groups, deselect the Let students organize their own groups checkbox in
course settings.`)
    }
  ]
)

const featureFlagsPermissions = generateActionTemplates(
  'manage_feature_flags',
  [
    {
      title: I18n.t('Feature Options (Account Settings):'),
      description: I18n.t(`Allows user to manage Feature Options in Account Settings.`)
    }
  ],
  [],
  [],
  []
)

const globalAnnouncementsPermissions = generateActionTemplates(
  'manage_alerts',
  [
    {
      title: I18n.t('Announcements:'),
      description: I18n.t(`Allows user to add, edit, and delete global announcements.`)
    }
  ],
  [],
  [],
  []
)

const gradesEditPermissions = generateActionTemplates(
  'manage_grades',
  [
    {
      title: I18n.t('Admin Tools (Logging tab):'),
      description: I18n.t(
        `Allows user to search by course ID or assignment ID in grade change logs in Admin Tools.`
      )
    },
    {
      title: I18n.t('Analytics:'),
      description: I18n.t(`Allows user to view student-specific data in Analytics.`)
    },
    {
      title: I18n.t('Course Settings:'),
      description: I18n.t(`Allows user to view the course grading scheme.`)
    },
    {
      title: I18n.t('Discussions:'),
      description: I18n.t(
        `Allows user to like discussion posts when the Only Graders Can Like checkbox is selected.`
      )
    },
    {
      title: I18n.t('Gradebook and SpeedGrader:'),
      description: I18n.t(`Allows user to add, edit, and update grades in the Gradebook and in SpeedGrader.
Allows user to access Gradebook History.`)
    },
    {
      title: I18n.t('Grading Schemes (Account Navigation):'),
      description: I18n.t(`Allows user to create and modify grading schemes.`)
    },
    {
      title: I18n.t('Quizzes:'),
      description: I18n.t(`Allows user to moderate a quiz.`)
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Logging tab):'),
      description: I18n.t(
        `To search grade change logs, Grades - view change logs must also be enabled.`
      )
    },
    {
      title: I18n.t('Analytics:'),
      description: I18n.t(
        `To view student analytics in course analytics, Analytics - view​ must also be enabled.`
      )
    },
    {
      title: I18n.t('Course Settings:'),
      description: I18n.t(
        `To edit course grading schemes, Course - add / edit / delete must also be enabled.`
      )
    },
    {
      title: I18n.t('Gradebook and SpeedGrader:'),
      description: I18n.t(
        `Gradebook and SpeedGrader will be inaccessible if both Grades - edit​ and Grades - view all grades​ are disabled.`
      )
    },
    {
      title: I18n.t('People (Course):'),
      description: I18n.t(
        `To view student analytics, Users - view list​ and Analytics - view​ must also be enabled.`
      )
    },
    {
      title: I18n.t('Quizzes:'),
      description: I18n.t(
        `To moderate a quiz, Assignemtns and Quizzes - add / edit / delete​ must also be enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Gradebook:'),
      description: I18n.t(
        `Allows user to edit grades in the Gradebook. Allows user to access Gradebook History.`
      )
    },
    {
      title: I18n.t('Quizzes:'),
      description: I18n.t(
        `Allows user to moderate a quiz. Settings: Allows user to edit grading schemes.`
      )
    },
    {
      title: I18n.t('SpeedGrader:'),
      description: I18n.t(`Allows user to edit grades and add comments in SpeedGrader.`)
    }
  ],
  [
    {
      title: I18n.t('Gradebook, SpeedGrader:'),
      description: I18n.t(
        `Gradebook and SpeedGrader will be inaccessible if both Grades - edit and Grades - view all grades​ are disabled.`
      )
    },
    {
      title: I18n.t('Quizzes:'),
      description: I18n.t(
        `To moderate a quiz, Assignments and Quizzes - add / edit / delete must also be enabled.`
      )
    },
    {
      title: I18n.t('Settings:'),
      description: I18n.t(`Course Grading Schemes can be enabled/disabled in course settings.`)
    }
  ]
)

const gradesModeratePermissions = generateActionTemplates(
  'moderate_grades',
  [
    {
      title: I18n.t('Assignments:'),
      description: I18n.t(`Allows user to view the Moderate button for moderated assignments.`)
    }
  ],
  [
    {
      title: I18n.t('Assignments:'),
      description: I18n.t(
        `To allow a user to add students to a moderation set, Grades - view all grades must also be enabled.`
      )
    },
    {
      title: I18n.t('SpeedGrader:'),
      description: I18n.t(
        `To allow a user to review a moderated assignment in SpeedGrader, Grades - edit must also be enabled.`
      )
    },
    {
      title: I18n.t('Grades:'),
      description: I18n.t(
        `To allow a user to publish final grades for a moderated assignment, Grades - edit​ must also be enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Assignments:'),
      description: I18n.t(`Allows user to view the Moderate button for moderated assignments.`)
    }
  ],
  [
    {
      title: I18n.t('Assignments:'),
      description: I18n.t(`To allow a user to add students to a moderation set, Grades - view all grades​ must also be enabled.
To allow a user to add students to a moderation set, review a moderated assignment in SpeedGrader, and publish final grades for a moderated assignment, Grades - edit​ must also be enabled.`)
    }
  ]
)

const gradesViewAllPermissions = generateActionTemplates(
  'view_all_grades',
  [
    {
      title: I18n.t('Admin Tools (Logging tab):'),
      description: I18n.t(`Allows user to search by assignment ID in grade change logs.`)
    },
    {
      title: I18n.t('Analytics:'),
      description: I18n.t(`Allows user to view student-specific data in Analytics.`)
    },
    {
      title: I18n.t('Assignments:'),
      description: I18n.t(`Allows user to view a link to SpeedGrader from assignments.`)
    },
    {
      title: I18n.t('Gradebook:'),
      description: I18n.t(`Allows user to view Gradebook.
Allows user to export the Gradebook to a comma separated values (CSV) file.`)
    },
    {
      title: I18n.t('Grades:'),
      description: I18n.t(`Allows user to view student Grades pages.`)
    },
    {
      title: I18n.t('Modules:'),
      description: I18n.t(`Allows user to access the Student Progress page.`)
    },
    {
      title: I18n.t('People (Course):'),
      description: I18n.t(`Adds analytics link on the user settings menu.`)
    },
    {
      title: I18n.t('Quizzes:'),
      description: I18n.t(
        `Allows user to view student results and/or access a quiz in SpeedGrader.`
      )
    },
    {
      title: I18n.t('Rubrics:'),
      description: I18n.t(`Allows user to view grader comments on a rubric in SpeedGrader.`)
    },
    {
      title: I18n.t('Student Context Card:'),
      description: I18n.t(`Adds analytics to a student’s context card.`)
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Grade Change Logs):'),
      description: I18n.t(
        `To search grade change logs, Grades - view change logs​ must also be enabled.`
      )
    },
    {
      title: I18n.t('Analytics:'),
      description: I18n.t(`To view student analytics, Analytics - view ​must also be enabled.`)
    },
    {
      title: I18n.t('Modules:'),
      description: I18n.t(
        `To view module progression, Grades - view all grades​ must also be enabled.`
      )
    },
    {
      title: I18n.t('Student Context Card:'),
      description: I18n.t(`Student Context Cards must be enabled for an account by an admin.`)
    }
  ],
  [
    {
      title: I18n.t('Analytics:'),
      description: I18n.t(`Allows user to view student-specific data in Analytics.`)
    },
    {
      title: I18n.t('Assignments:'),
      description: I18n.t(`Allows user to access SpeedGrader from an assignment.`)
    },
    {
      title: I18n.t('Gradebook:'),
      description: I18n.t(`Allows user to view Gradebook.
Allows user to export the Gradebook to a comma separated values (CSV) file.`)
    },
    {
      title: I18n.t('Grades:'),
      description: I18n.t(`Allows user to view student Grades pages.`)
    },
    {
      title: I18n.t('Modules:'),
      description: I18n.t(`Allows user to access the Student Progress page.`)
    },
    {
      title: I18n.t('People (Course):'),
      description: I18n.t(`Adds analytics link on the user settings menu.`)
    },
    {
      title: I18n.t('Quizzes:'),
      description: I18n.t(
        `Allows user to view student results and/or access a quiz in SpeedGrader.`
      )
    },
    {
      title: I18n.t('Rubrics:'),
      description: I18n.t(`Allows user to view grader comments on a rubric in SpeedGrader.`)
    },
    {
      title: I18n.t('Student Context Card:'),
      description: I18n.t(`Adds analytics to a student’s context card.`)
    }
  ],
  [
    {
      title: I18n.t('Analytics:'),
      description: I18n.t(`To view student analytics, Analytics - view ​must also be enabled.`)
    },
    {
      title: I18n.t('Gradebook:'),
      description: I18n.t(
        `If both Grades - edit​ and Grades - view all grades are disabled, Gradebook will be hidden from the course navigation.`
      )
    },
    {
      title: I18n.t('Modules:'),
      description: I18n.t(
        `To view module progression, Grades - view all grades​ must also be enabled.`
      )
    },
    {
      title: I18n.t('Student Context Card:'),
      description: I18n.t(`Student Context Cards must be enabled for an account by an admin.`)
    }
  ]
)

const gradesViewChangeLogPermissions = generateActionTemplates(
  'Grades - view change logs',
  [
    {
      title: I18n.t('Admin Tools (Logging tab):'),
      description: I18n.t(
        `Determines visibility of the Grade Change Activity option in the Admin Tools Logging tab.`
      )
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Logging tab):'),
      description: I18n.t(`To search by grader or student ID, Users - view list must also be enabled.
To search by course ID or assignment ID, Grades - edit must also be enabled.
To search by assignment ID only, Grades - view all grades​ must also be enabled.`)
    }
  ],
  [],
  []
)

const gradesAddEditDeletePermissions = generateActionTemplates(
  'manage_groups',
  [
    {
      title: I18n.t('Account Groups:'),
      description: I18n.t(`Allows user to create, edit, and delete account groups.`)
    },
    {
      title: I18n.t('Course Groups:'),
      description: I18n.t(`Allows user to create, edit, and delete course groups.
Allows user to create, edit, and delete course groups created by students.`)
    }
  ],
  [
    {
      title: I18n.t('Account Groups:'),
      description: I18n.t(
        `If this permission is disabled, at the account level, users cannot view any existing account groups. At the course level, users can view, but not access, any existing groups, including groups created by students. To view groups, Users - view list m​ust also be ​enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('People (Groups tab):'),
      description: I18n.t(
        `Allows user to create, edit, and delete course groups. Allows user to create, edit, and delete course groups created by students.`
      )
    }
  ],
  [
    {
      title: I18n.t('Collaborations:'),
      description: I18n.t(
        `Allows user to view all course groups, not just those they are enrolled in, in the Collaborate With window.`
      )
    },
    {
      title: I18n.t('Groups:'),
      description: I18n.t(
        `If this permission is disabled, users can only view existing groups, including groups created by students.`
      )
    },
    {
      title: I18n.t('People:'),
      description: I18n.t(
        `To access the People page and view Groups, Users - view list  must also be enabled.`
      )
    },
    {
      title: I18n.t('Course Settings (Course Details tab):'),
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
      title: I18n.t('Groups:'),
      description: I18n.t(`Allows user to view the group home pages of all student groups.
Allows students to access other student groups within a group set with a direct link.`)
    }
  ],
  [
    {
      title: I18n.t('Groups:'),
      description: I18n.t(`By default students are able to create groups; to restrict students from creating
groups, deselect the Let students organize their own groups checkbox in
course settings.`)
    }
  ],
  [
    {
      title: I18n.t('Groups:'),
      description: I18n.t(`Allows user to view the group home pages of all student groups
Allows students to access other student groups within a group set with a direct link`)
    }
  ],
  [
    {
      title: I18n.t('Groups:'),
      description: I18n.t(`By default students are able to create groups; to restrict students from creating
groups, deselect the Let students organize their own groups checkbox in
course settings.`)
    }
  ]
)

const learningOutcomesAddEditDeletePermissions = generateActionTemplates(
  'manage_outcomes',
  [
    {
      title: I18n.t('Outcomes:'),
      description: I18n.t(`Determines visibility and management of Outcomes tab in account navigation.
Allows user to create, import, edit, and delete outcomes and outcome groups
at the course level.`)
    },
    {
      title: I18n.t('Rubrics:'),
      description: I18n.t(`Determines visibility and management of Rubrics tab in the account navigation.
Allows user to manage rubrics.`)
    }
  ],
  [
    {
      title: I18n.t('Outcomes and Rubrics:'),
      description: I18n.t(
        `If disabled, Outcomes page becomes read-only and hides the Manage Rubrics button. User can still access individual assignment rubrics through Assignments. For full rights to create an outcome, Course Content - view and Assignments and Quizzes - add / edit / delete​ must also be enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Outcomes:'),
      description: I18n.t(`Allows user to create, import, edit, and delete outcomes and outcome groups at
the course level.`)
    },
    {
      title: I18n.t('Rubrics:'),
      description: I18n.t(`Allows user to manage rubrics.`)
    }
  ],
  [
    {
      title: I18n.t('Outcomes and Rubrics:'),
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
      title: I18n.t('Learning Outcomes:'),
      description: I18n.t(`Allows user to import learning outcomes`)
    }
  ],
  [],
  [
    {
      title: I18n.t('Learning Outcomes:'),
      description: I18n.t(`Allows user to import learning outcomes`)
    }
  ],
  []
)

const ltiAddEditPermissions = generateActionTemplates(
  'lti_add_edit',
  [
    {
      title: I18n.t('Account Settings:'),
      description: I18n.t(`Allows user to manually add an app in Account Settings.`)
    },
    {
      title: I18n.t('Course Settings:'),
      description: I18n.t(`Allows user to manually add and delete an app in Course Settings.`)
    },
    {
      title: I18n.t('External Apps:'),
      description: I18n.t(`Allows user to edit configurations for manually added external apps.`)
    }
  ],
  [
    {
      title: I18n.t('External Apps:'),
      description: I18n.t(
        '(Account and Course Settings) If this permission is disabled, users can still install approved apps through the Canvas App Center (if enabled for your institution). Additionally, if this permission is disabled, users cannot delete manually added external apps.'
      )
    }
  ],
  [
    {
      title: I18n.t('Course Settings:'),
      description: I18n.t(`Allows user to manually add and delete an app in Course Settings.`)
    },
    {
      title: I18n.t('External Apps:'),
      description: I18n.t(`Allows user to edit configurations for manually added external apps.`)
    }
  ],
  [
    {
      title: I18n.t('External Apps:'),
      description: I18n.t(
        'If this permission is disabled, users can still install approved apps through the Canvas App Center (if enabled for your institution). Additionally, if this permission is disabled, users cannot delete manually added external apps.'
      )
    }
  ]
)

const messagesSentPermissions = generateActionTemplates(
  'send_messages',
  [
    {
      title: I18n.t('Conversations:'),
      description: I18n.t(`Allows user to send a message to “All in [course name]”.
Allows user to send a message to “All in [course group]”`)
    }
  ],
  [
    {
      title: I18n.t('Conversations:'),
      description: I18n.t(
        `When disabled, students can still send individual messages to course teachers, course TAs, and students that belong to the same account-level groups.`
      )
    },
    {
      title: I18n.t('People:'),
      description: I18n.t(
        `To edit a student’s section, Course - add / remove students ​and Users - view list must also be enabled. To edit a teacher’s, TA’s, or course designer’s section, Course - add / remove teachers, course designers or TA's​ and Users - view list​ must also be enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Conversations:'),
      description: I18n.t(`Allows user to send a message to “All in [course name]”.
Allows user to send a message to “All in [course group]”`)
    }
  ],
  [
    {
      title: I18n.t('Conversations:'),
      description: I18n.t(
        `When disabled, students can still send individual messages to course teachers, course TAs, and students that belong to the same account-level groups.`
      )
    },
    {
      title: I18n.t('People:'),
      description: I18n.t(`To edit a student’s section, Course - add / remove students and Users - view list  must also both be enabled.
To edit a teacher, course designer, or TAs section, Course - add / remove teachers, course designers or TAs ​ and Users - view list must also both be enabled.`)
    }
  ]
)

const messagesSentEntireClassPermissions = generateActionTemplates(
  'send_messages_all',
  [
    {
      title: I18n.t('Conversations:'),
      description: I18n.t(`Allows user to send a message to “All in [course name]”.
Allows user to send a message to “All in [course group]”`)
    }
  ],
  [],
  [
    {
      title: I18n.t('Conversations:'),
      description: I18n.t(
        `Allows user to send a message to “All in [course name],” or “All in [course group].”`
      )
    }
  ],
  []
)

const observersAddRemovePermissions = generateActionTemplates(
  'send_messages',
  [
    {
      title: I18n.t('People (Account):'),
      description: I18n.t(`Allows user to manage observers associated with students in the account`)
    }
  ],
  [],
  [],
  []
)

const pagesAddRemovePermissions = generateActionTemplates(
  'manage_wiki',
  [
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(
        `Allows user to edit blueprint lock settings on the Pages index page in a Blueprint Master Course.`
      )
    },
    {
      title: I18n.t('Pages:'),
      description: I18n.t(
        `Index page. Pages Allows user to view, create, edit, delete, and publish/unpublish pages. Allows user to view page history and set front page.`
      )
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(`Blueprint Courses is an account-level feature option.
To edit blueprint lock settings on the Pages index page, Course - add / edit / delete must also be enabled. If this permission is not enabled, and Course - add / edit / delete​ is enabled, blueprint lock settings can be edited on individual pages.`)
    },
    {
      title: I18n.t('Pages:'),
      description: I18n.t(
        `Students can edit and view page history if allowed in the individual page options.`
      )
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(
        `Allows user to edit blueprint lock settings on the Pages index page in a Blueprint Master Course.`
      )
    },
    {
      title: I18n.t('Pages:'),
      description: I18n.t(`Allows user to view, create, edit, delete, and publish/unpublish pages.
Allows user to view page history and set front page.`)
    }
  ],
  [
    {
      title: I18n.t('Blueprint Courses:'),
      description: I18n.t(`Blueprint courses must be enabled for an account by an admin.
Course roles can only manage content in Blueprint Courses if they are added to the Blueprint Course as an teacher, TA, or designer role.
If this permission is disabled, a user can still adjust content lock settings on individual pages in a Blueprint Master Course.`)
    },
    {
      title: I18n.t('Pages:'),
      description: I18n.t(
        `Students can edit and view page history if allowed in the individual page options.`
      )
    }
  ]
)

const managePermissions = generateActionTemplates(
  'manage_role_overrides',
  [
    {
      title: I18n.t('People (Account):'),
      description: I18n.t(`Allows user to edit blueprint lock settings on the`)
    }
  ],
  [],
  [],
  []
)

const questionBankPermissions = generateActionTemplates(
  'read_question_banks',
  [
    {
      title: I18n.t('Question Banks:'),
      description: I18n.t(
        `Allows user to view and link questions in a quiz to account level question banks. If disabled, user will only be able to view and link to course question banks.`
      )
    }
  ],
  [
    {
      title: I18n.t('Quizzes, Question Banks:'),
      description: I18n.t(
        `This permission does not affect ability to manage course level question banks in Quizzes. Instead, Manage Question Banks is dependent on the Assignments and Quizzes - add / edit / delete permission.`
      )
    }
  ],
  [
    {
      title: I18n.t('Question Banks:'),
      description: I18n.t(`Allows user to view and link questions in a quiz to account-level question
banks. If disabled, user will only be able to view and link to course question banks. Enables the Manage Question Banks link on the Quizzes Index Page`)
    }
  ],
  [
    {
      title: I18n.t('Quizzes, Question Banks:'),
      description: I18n.t(`This permission does not affect ability to manage course level question banks in Quizzes. Instead, Manage Question Banks is dependent on the Assignments and Quizzes - add / edit / delete permission.
For full management of course question banks, this permission and Assignments and Quizzes - add / edit / delete​ must both be enabled.`)
    }
  ]
)

const rubricsAddPermissions = generateActionTemplates(
  'manage_rubrics',
  [
    {
      title: I18n.t('Rubrics:'),
      description: I18n.t(`Allows user to create, edit, and delete rubrics`)
    }
  ],
  [
    {
      title: I18n.t('Rubrics:'),
      description: I18n.t(
        `If this permission is disabled, users can still create or add rubrics to assignments if Assignments and Quizzes - add / edit / delete is enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Rubrics:'),
      description: I18n.t(
        `Allows user to create, edit and delete course rubrics in the Rubrics link.`
      )
    }
  ],
  [
    {
      title: I18n.t('Assignments:'),
      description: I18n.t(
        `If this permission is disabled, users can still create or add rubrics to assignments if Assignments and Quizzes - add / edit / delete is enabled.`
      )
    }
  ]
)

const sisDataImportPermissions = generateActionTemplates(
  'import_sis',
  [
    {
      title: I18n.t('Account Navigation:'),
      description: I18n.t(
        `Determines visibility and management of SIS Import tab in account navigation.`
      )
    },
    {
      title: I18n.t('SIS Import:'),
      description: I18n.t(`Allows user to import SIS data.`)
    }
  ],
  [
    {
      title: I18n.t('SIS Import:'),
      description: I18n.t(`To manage SIS data, SIS Data - manage​ must also be enabled.`)
    },
    {
      title: I18n.t('Subaccounts:'),
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
      title: I18n.t('Account Navigation:'),
      description: I18n.t(`Determines visibility of SIS Import tab in account navigation.
Allows user to view the previous SIS import dates, errors, and imported items.`)
    },
    {
      title: I18n.t('SIS Import:'),
      description: I18n.t('Allows user to edit the course SIS ID.')
    },
    {
      title: I18n.t('People (Account):'),
      description: I18n.t(
        'Allows user to view and edit the SIS ID and Integration ID in a user’s Login Details'
      )
    },
    {
      title: I18n.t('People (Course):'),
      description: I18n.t('Allows user to edit the course SIS ID.')
    },
    {
      title: I18n.t('Subaccount Settings:'),
      description: I18n.t('Allows user to view and insert data in the SIS ID field.')
    }
  ],
  [
    {
      title: I18n.t('Course Settings:'),
      description: I18n.t(`To edit course settings, Course - add / edit / delete​ must be enabled.`)
    },
    {
      title: I18n.t('People (Account):'),
      description: I18n.t(
        `To view or edit a user’s SIS ID or Integration ID, Users - view list​ and Users - manage log in details must also both be enabled.`
      )
    },
    {
      title: I18n.t('People (Course):'),
      description: I18n.t(`If this permission is enabled, users do not need the SIS Data - read permission enabled. The account permission overrides the course permission. To disallow users from managing SIS IDs at the course level, SIS Data - manage​ and SIS Data - read must both be disabled.
To add users to courses via SIS ID, Course - add / remove students and/or Course - add / remove teachers, course designers or TAs​ must also be enabled.`)
    },
    {
      title: I18n.t('SIS Import:'),
      description: I18n.t(`To import SIS data, SIS Data - import​ must also be enabled.`)
    },
    {
      title: I18n.t('Subaccounts:'),
      description: I18n.t(`Not available at the subaccount level.`)
    }
  ],
  [],
  []
)

const sisDataReadPermissions = generateActionTemplates(
  'read_sis',
  [
    {
      title: I18n.t('SIS:'),
      description: I18n.t(`Governs account-related SIS IDs (i.e., subaccount SIS ID).`)
    },
    {
      title: I18n.t('Course Settings:'),
      description: I18n.t('Allows user to view a course’s SIS ID.')
    },
    {
      title: I18n.t('People (Account):'),
      description: I18n.t('Allows a user to view the SIS ID in a user’s login details.')
    },
    {
      title: I18n.t('People (Course):'),
      description: I18n.t('Allows a user to view user SIS IDs in a course People page.')
    }
  ],
  [
    {
      title: I18n.t('Account and Subaccount:'),
      description: I18n.t(`Users and terms are located at the root account, so the SIS endpoint always confirms the user’s permissions according to root account. Subaccounts only have ownership of courses and sections; they do not own user data.
Subaccount admins are not able to view SIS information unless they are also granted an instructor role in a course. Subaccount admins cannot view SIS information without the course association, as the instructor role has permission to read SIS data at the root level.`)
    },
    {
      title: I18n.t('People (Account):'),
      description: I18n.t(
        `To view a user’s login details, Users - view list and Modify login details for users must also both be enabled.`
      )
    },
    {
      title: I18n.t('People (Course):'),
      description: I18n.t(`To view the list of users in the course, Users - view list  must also be enabled.
To add users via SIS ID, Course - add / remove students ​and/or Course - add / remove teachers, course designers or TAs must also be enabled.`)
    },
    {
      title: I18n.t('SIS Import:'),
      description: I18n.t(
        `To manage SIS data, SIS Data - manage​ must be enabled. If SIS Data - manage ​is enabled and SIS Data - read is disabled, the account permission overrides the course permission. If SIS Data - manage ​is disabled and SIS Data - read​ is enabled, users can only view course, user, and subaccount SIS IDs. To disallow users from viewing any SIS IDs at the course level, SIS Data - manage​ and SIS Data - read​ must both be disabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Course Settings:'),
      description: I18n.t('Allows user to view course SIS ID')
    },
    {
      title: I18n.t('People:'),
      description: I18n.t('Allows user to view user SIS IDs.')
    }
  ],
  [
    {
      title: I18n.t('People:'),
      description: I18n.t(
        'To view the list of users in the course, Users - view list must also be enabled. To add users via SIS ID, Course - add / remove students​ and/or Course - add / remove teachers, course designers or TAs ​ to the course must also be enabled.'
      )
    }
  ]
)

const viewStatisticsPermissions = generateActionTemplates(
  'view_statistics',
  [
    {
      title: I18n.t('Account Statistics:'),
      description: I18n.t(`Allows admin user to view account statistics.`)
    },
    {
      title: I18n.t('Admin Tools (Logging tab):'),
      description: I18n.t('Allows user to generate login/logout activity report in Admin Tools.')
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Logging tab):'),
      description: I18n.t(
        `If Statistics - view​ or Users - manage log in details is enabled, a user will be able to generate login/logout activity in Admin Tools. To hide the login/logout activity option in Admin Tools, both of these permissions need to be disabled.`
      )
    },
    {
      title: I18n.t('People (Account):'),
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
      title: I18n.t('Quotas (Account Settings):'),
      description: I18n.t(
        `Allows user to view and manage Quotas tab in account settings. User can set default course, user, and group storage quotes.`
      )
    }
  ],
  [],
  [],
  []
)

const studentCollabPermissions = generateActionTemplates(
  'create_collaborations',
  [
    {
      title: I18n.t('Collaborations:'),
      description: I18n.t(
        `Allows user to create collaborations. Allows user to view/edit/delete collaborations they created.`
      )
    }
  ],
  [
    {
      title: I18n.t('Collaborations:'),
      description: I18n.t(
        `To allow view/edit/delete functionality of collaborations created by other users, Course Content - add / edit / delete must also be enabled. If Course Content - add / edit / delete​ is enabled and Student Collaborations - create is disabled, user will not be able to create new collaborations but will be able to view/edit/delete all collaborations. To add students to a collaboration, Users - view list​​ must also be enabled. To add a course group to a collaboration, Group view all student groups​ must also be enabled.`
      )
    }
  ],
  [
    {
      title: I18n.t('Collaborations:'),
      description: I18n.t(
        `Allows user to create collaborations. Allows user to start conferences they created.`
      )
    }
  ],
  [
    {
      title: I18n.t('Collaborations:'),
      description: I18n.t(
        `To allow full management of conferences created by the user or others, Course Content - add / edit / delete​ must also be enabled. To end a long-running conference, Course Content - add / edit / delete​ must be enabled. If Course Content - add / edit / delete is enabled and Web Conferences - create is disabled, user can still manage conferences. This permission controls a user’s ability to create conferences in courses and groups.`
      )
    }
  ]
)

const submissionViewCommentsPermissions = generateActionTemplates(
  'comment_on_others_submissions',
  [
    {
      title: I18n.t('Assignments:'),
      description: I18n.t(`Allows user to view all student assignment submissions and make
comments on them.`)
    }
  ],
  [
    {
      title: I18n.t('Assignments, Gradebook:'),
      description: I18n.t(`To access assignment submissions through Assignments and the
Gradebook, Grades - view all grades​ must also be enabled.`)
    },
    {
      title: I18n.t('Assignments, SpeedGrader:'),
      description: I18n.t(`To access assignment submissions through Assignments and SpeedGrader, Grades - edit​ must also be enabled.
To edit a grade or add comments in SpeedGrader or the Gradebook, Grades - edit must also be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('Assignments:'),
      description: I18n.t(`Allows user to view all student assignment submissions and make
  comments on them.`)
    }
  ],
  [
    {
      title: I18n.t('Assignments, Gradebook:'),
      description: I18n.t(
        `To access assignment submissions through Assignments or the Gradebook and view in SpeedGrader, Grades - view all grades ​or Grades - edit must also be enabled.`
      )
    },
    {
      title: I18n.t('Gradebook, SpeedGrader:'),
      description: I18n.t(
        `To edit a grade or add comments in SpeedGrader or Gradebook, Grades - edit must be enabled.`
      )
    }
  ]
)

const usersActAsPermissions = generateActionTemplates(
  'become_user',
  [
    {
      title: I18n.t('People (Account):'),
      description: I18n.t(`Allows user to act as other users in the account.`)
    },
    {
      title: I18n.t('Student Context Card:'),
      description: I18n.t(`Allows a user to access the Act as User link on student context cards`)
    }
  ],
  [
    {
      title: I18n.t('API:'),
      description: I18n.t(`Allows user to view Login IDs in a course People page.`)
    },
    {
      title: I18n.t('People (Account):'),
      description: I18n.t(
        `To view the list of users in an account, Users - view list​ must be enabled.`
      )
    },
    {
      title: I18n.t('Student Context Card:'),
      description: I18n.t(`Student Context Cards must be enabled for an account by an admin.`)
    },
    {
      title: I18n.t('Subaccounts:'),
      description: I18n.t(`Not available at the subaccount level.`)
    }
  ],
  [
    {
      title: I18n.t('People (Account):'),
      description: I18n.t(`Allows user to act as other users in the account.`)
    },
    {
      title: I18n.t('Student Context Card:'),
      description: I18n.t(`Allows a user to access the Act as User link on student context cards`)
    }
  ],
  [
    {
      title: I18n.t('API:'),
      description: I18n.t(`The Roles API refers to this permission as become_user.`)
    },
    {
      title: I18n.t('People (Account):'),
      description: I18n.t(
        `To view the list of users in an account, Users - view list  must be enabled.`
      )
    },
    {
      title: I18n.t('Student Context Card:'),
      description: I18n.t(`Student Context Cards must be enabled for an account by an admin.`)
    },
    {
      title: I18n.t('Subaccounts:'),
      description: I18n.t(`Not available at the subaccount level.`)
    }
  ]
)

const usersManageLoginPermissions = generateActionTemplates(
  'manage_user_logins',
  [
    {
      title: I18n.t('People (Account):'),
      description: I18n.t(`Allows user to create accounts for new users with the account-level Add People button.
Allows user to remove and merge users in an account.
Allows user to modify user account details such as name, email, and time zone. Allows user to view and modify login information for a user.`)
    },
    {
      title: I18n.t('Admin Tools (Logging tab):'),
      description: I18n.t(`Allows user to generate login/logout activity report in Admin Tools.`)
    }
  ],
  [
    {
      title: I18n.t('Admin Tools (Logging tab):'),
      description: I18n.t(
        `If Users - manage log in details or Statistics - view​ is enabled, a user will be able to generate login/logout activity in Admin Tools. To hide the login/logout activity option in Admin Tools, both of these permissions need to be disabled.`
      )
    },
    {
      title: I18n.t('People (Account):'),
      description: I18n.t(`To view users and user account details, Users - view list​ must be enabled.
To change user passwords, Users - view list must also be enabled.
To view a user’s SIS ID, SIS Data - manage​ or SIS Data - read must also be
enabled. To view a user’s Integration ID, SIS Data - manage​ must also be enabled.`)
    },
    {
      title: I18n.t('People (Course):'),
      description: I18n.t(`This permission only controls adding users at the account-level. To add users
to a course, Course - add / remove students or Course - add / remove teachers, course designers or TAs to the course​ must be enabled.`)
    }
  ],
  [],
  []
)

const usersViewLoginPermissions = generateActionTemplates(
  'view_user_logins',
  [
    {
      title: I18n.t('People:'),
      description: I18n.t(`Allows user to view Login IDs in a course People page.`)
    }
  ],
  [
    {
      title: I18n.t('People:'),
      description: I18n.t(`To access the People page, Users - view list must be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('People:'),
      description: I18n.t(`Allows user to view Login IDs in a course People page.`)
    }
  ],
  [
    {
      title: I18n.t('People:'),
      description: I18n.t(`To access the People page, Users - view list must be enabled.`)
    }
  ]
)

const usersViewListPermissions = generateActionTemplates(
  'read_roster',
  [
    {
      title: I18n.t('Account Navigation:'),
      description: I18n.t(`Allows user to access the Users link in Account Navigation.`)
    },
    {
      title: I18n.t('Admin Tools (Logging tab):'),
      description: I18n.t(`Allows user to view login/logout activity of users in Admin Tools.
Allows user to search grade change logs by grader or student in Admin Tools`)
    },
    {
      title: I18n.t('Assignments:'),
      description: I18n.t(`Allows user to differentiate assignments to individual students.`)
    },
    {
      title: I18n.t('Collaborations:'),
      description: I18n.t(`Allows user to view and add users in a collaboration.`)
    },
    {
      title: I18n.t('Conversations:'),
      description: I18n.t(
        `Allows user to send a message in Conversations without selecting a course.`
      )
    },
    {
      title: I18n.t('Course Navigation:'),
      description: I18n.t(`Allows user to view the People link in Course Navigation.`)
    },
    {
      title: I18n.t('Groups (Course):'),
      description: I18n.t(`Allows user to view groups in a course.`)
    },
    {
      title: I18n.t('People (Course):'),
      description: I18n.t(`Allows user to view list of users in the course People page.
Allows user to view the Prior Enrollments button in the course People page.`)
    },
    {
      title: I18n.t('People (Account):'),
      description: I18n.t(`Allows user to view list of users in the account.`)
    }
  ],
  [
    {
      title: I18n.t('Account Groups:'),
      description: I18n.t(
        `To view account-level groups, Groups - add / edit / delete must also be enabled.`
      )
    },
    {
      title: I18n.t('Admin Tools (Logging tab):'),
      description: I18n.t(
        `To generate login/logout activity in Admin Tools, Users - manage log in details​ or Statistics - view must also be enabled.To generate grade change logs in Admin Tools, Grades - view change logs must also be enabled.`
      )
    },
    {
      title: I18n.t('Courses:'),
      description: I18n.t(`To add users to a course, Course - add / remove students for the course ​and/or Course - add / remove teachers, course designers or TAs  ​must
also be enabled.`)
    },
    {
      title: I18n.t('People (Account):'),
      description: I18n.t(`To edit user details, modify login details, or change user passwords, Users - manage log in details ​must also be enabled.
To view user page views, Statistics - view must also be enabled.
To act as other users, Users - act as must also be enabled.`)
    },
    {
      title: I18n.t('People (Course):'),
      description: I18n.t(`To edit a student’s section, Course - add / remove students​ and Send messages to individual course members​ must also be enabled.
To edit a teacher, TA, or course designer’s section, Course - add / remove teachers, course designers or TAs to the course​ and Messages - send to individual course members​ must also be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('Assignments:'),
      description: I18n.t(`Allows user to differentiate assignments to individual students.`)
    },
    {
      title: I18n.t('Collaborations:'),
      description: I18n.t(`Allows user to view and add users in a collaboration.`)
    },
    {
      title: I18n.t('Course:'),
      description: I18n.t(`Navigation Allows user to view the People link in Course Navigation`)
    },
    {
      title: I18n.t('Groups'),
      description: I18n.t(`Allows user to view groups in a course`)
    },
    {
      title: I18n.t('People:'),
      description: I18n.t(`Allows user to view list of users in the course People page.
Allows user to view the Prior Enrollments button in the course People page.`)
    },
    {
      title: I18n.t('Settings:'),
      description: I18n.t(`Allows user to view enrollments on the Sections tab`)
    }
  ],
  [
    {
      title: I18n.t('Conversations:'),
      description: I18n.t(
        `To send a message to an individual user, Messages - send to individual course members​ must also be enabled.`
      )
    },
    {
      title: I18n.t('Groups:'),
      description: I18n.t(
        `To add, edit, or delete groups, Groups - add / edit / delete must also be enabled.`
      )
    },
    {
      title: I18n.t('People:'),
      description: I18n.t(`To add users to a course, Course - add / remove students and/or Course - add / remove teachers, course designers or TAs must also be enabled.
To edit a student’s section, Messages - send to individual course members​ and Course - add / remove students​ must also both be enabled.
To edit a teacher, course designer, or TAs section, Messages - send to individual course members​​ and Course - add / remove teachers, course designers or TAs​ must also both be enabled.`)
    }
  ]
)

const usersViewEmailPermissions = generateActionTemplates(
  'read_email_addresses',
  [
    {
      title: I18n.t('People:'),
      description: I18n.t(
        `Allows user to search for other users via primary email addresses in the People page.`
      )
    }
  ],
  [
    {
      title: I18n.t('People:'),
      description: I18n.t(`To view the account People page, Users - view list must be enabled.`)
    }
  ],
  [
    {
      title: I18n.t('People:'),
      description: I18n.t(
        `Allows user to search for other users via primary email addresses in the People page.`
      )
    }
  ],
  [
    {
      title: I18n.t('People:'),
      description: I18n.t(`To view the account People page, Users - view list must be enabled.`)
    }
  ]
)

const webConferencesPermissions = generateActionTemplates(
  'create_conferences',
  [
    {
      title: I18n.t('Conferences:'),
      description: I18n.t(
        `Allows user to create new conferences. Allows user to start conferences they created.`
      )
    }
  ],
  [
    {
      title: I18n.t('Conferences:'),
      description: I18n.t(`To allow full management of conferences created by the user or others, Course Content - add / edit / delete​ must also be enabled.
To end a long-running conference, Course Content - add / edit / delete​ must be enabled.
If Course Content - add / edit / delete is enabled and Web Conferences - create is disabled, user can still manage conferences.
This permission controls a user’s ability to create conferences in courses and groups.`)
    }
  ],
  [
    {
      title: I18n.t('Conferences:'),
      description: I18n.t(
        `Allows user to create new conferences. Allows user to start conferences they created.`
      )
    }
  ],
  [
    {
      title: I18n.t('Conferences:'),
      description: I18n.t(`To allow full management of conferences created by the user or others, Course Content - add / edit / delete​ must also be enabled.
  To end a long-running conference, Course Content - add / edit / delete​ must be enabled.
  If Course Content - add / edit / delete is enabled and Web Conferences - create is disabled, user can still manage conferences.
  This permission controls a user’s ability to create conferences in courses and groups.`)
    }
  ]
)

const webHooksPermissions = generateActionTemplates(
  'Webhooks - manage',
  [
    {
      title: I18n.t('Canvas Catalog:'),
      description: I18n.t(`Placeholder for webhooks access in Canvas Catalog.`)
    }
  ],
  [
    {
      title: I18n.t('Canvas Catalog:'),
      description: I18n.t(
        `Appears for all Canvas accounts but only in use for institutions associated with a Canvas Catalog account. Permission currently has no front-end effects, but engineering suggests the permission remain enabled for admins. For other roles the permission can be disabled.`
      )
    }
  ],
  [],
  []
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
    discussionsModerateManagePermissions.ACCOUNT,
    discussionPostPermissions.ACCOUNT,
    discussionViewPermissions.ACCOUNT,
    featureFlagsPermissions.ACCOUNT,
    globalAnnouncementsPermissions.ACCOUNT,
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
    observersAddRemovePermissions.ACCOUNT,
    pagesAddRemovePermissions.ACCOUNT,
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
    usersActAsPermissions.ACCOUNT,
    usersManageLoginPermissions.ACCOUNT,
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
    discussionsModerateManagePermissions.COURSE,
    discussionPostPermissions.COURSE,
    discussionViewPermissions.COURSE,
    featureFlagsPermissions.COURSE,
    globalAnnouncementsPermissions.COURSE,
    gradesEditPermissions.COURSE,
    gradesModeratePermissions.COURSE,
    gradesViewAllPermissions.COURSE,
    gradesViewChangeLogPermissions.COURSE,
    gradesAddEditDeletePermissions.COURSE,
    groupsViewAllStudentPermissions.COURSE,
    learningOutcomesAddEditDeletePermissions.COURSE,
    learningOutcomesImportPermissions.COURSE,
    messagesSentPermissions.COURSE,
    messagesSentEntireClassPermissions.COURSE,
    observersAddRemovePermissions.COURSE,
    pagesAddRemovePermissions.COURSE,
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
    usersActAsPermissions.COURSE,
    usersManageLoginPermissions.COURSE,
    usersViewLoginPermissions.COURSE,
    usersViewListPermissions.COURSE,
    usersViewEmailPermissions.COURSE,
    webHooksPermissions.COURSE,
    webConferencesPermissions.COURSE
  ])
}
