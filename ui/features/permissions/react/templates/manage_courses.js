/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import {generateActionTemplates} from '../generateActionTemplates'

const I18n = useI18nScope('permissions_templates_27')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Courses - add'),
      description: I18n.t('Allows user to add new courses to an account.'),
    },
    {
      title: I18n.t('Courses - manage'),
      description: I18n.t('Allows user to sync Blueprint Courses.'),
    },
    {
      description: I18n.t('Allows user to view Blueprint Sync history.'),
    },
    {
      description: I18n.t('Allows user to view and manage courses in the account.'),
    },
    {
      description: I18n.t('Allows user to view the Course Setup Checklist button.'),
    },
    {
      description: I18n.t('Allows user to access the Navigation tab.'),
    },
    {
      description: I18n.t(
        'Allows user to edit course image, name, course code, time zone, subaccount, term, and other options in Course Details tab.'
      ),
    },
    {
      description: I18n.t(
        'Allows user to access Student View (test student), Copy this Course, and Permanently Delete Course buttons.'
      ),
    },
    {
      description: I18n.t(
        'Allows user to view student context cards in announcement and discussion replies.'
      ),
    },
    {
      title: I18n.t('Courses - conclude'),
      description: I18n.t('Allows user to view the Conclude Course button.'),
    },
    {
      title: I18n.t('Courses - delete'),
      description: I18n.t('Allows user to view the Delete this Course button.'),
    },
    {
      title: I18n.t('Courses - publish'),
      description: I18n.t(
        'Allows user to view the Publish Course and Unpublish Course buttons in the Course Home page. Allows user to view the Publish button in a course card for an unpublished course (Card View Dashboard).'
      ),
    },
    {
      title: I18n.t('Courses - reset'),
      description: I18n.t('Allows user to view the Reset Course Content button.'),
    },
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'If Courses - manage is enabled, but Blueprint Courses - add / edit / associate / delete is not enabled, users can still sync Blueprint Courses and view Sync history.'
      ),
    },
    {
      title: I18n.t('Courses - Account Settings'),
      description: I18n.t(
        'To access the Courses link in Account Navigation, Courses - view list must be enabled.'
      ),
    },
    {
      description: I18n.t('To add a course, Courses - add must also be enabled.'),
    },
    {
      description: I18n.t(
        'To restore a deleted course, Courses - delete, Courses - undelete, and Course Content - view must also be enabled.'
      ),
    },
    ({
      description: I18n.t(
        'To allow other users to create courses in an account, select the appropriate user role in the Account Settings page: teachers, students, and/or users with no enrollments.'
      ),
    },
    {
      description: I18n.t(
        'If this permission is enabled and Courses - view list is disabled, users can add a new course with the Add a New Course button in Account Settings.'
      ),
    }),
    {
      title: I18n.t('Course Content'),
      description: I18n.t(
        'To manage course content, Courses - manage and Course Content - add / edit / delete must be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To view Choose Home Page and Course Setup Checklist buttons, Courses - manage and Course Content - view must also be enabled. (Teachers, designers, and TAs can set the home page of a course, regardless of their permissions.)'
      ),
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'The Courses - delete permission affects viewing the Permanently Delete this Course button, which only appears for manually created courses.'
      ),
    },
    {
      description: I18n.t(
        'To cross-list a section, Courses - manage and Manage Course Sections - edit must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To edit the course SIS ID, Courses - manage and SIS Data - manage must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'The Courses - Reset permission resets course content for both manually created and SIS-managed courses. (For SIS-managed courses, the SIS Data - manage permission does not apply.)'
      ),
    },
    {
      title: I18n.t('Courses - Account Navigations'),
      description: I18n.t(
        'To access the Courses link in Account Navigation, Courses - manage and Courses - view list must be enabled.'
      ),
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        'To view grades in a course, Courses - manage and Grades - view all grades must also be enabled.'
      ),
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(
        'The Courses - publish permission allows the user to publish courses that do not contain modules. To publish/unpublish module content, Course Content - add / edit / delete must be enabled.'
      ),
    },
    {
      title: I18n.t('Student Context Cards'),
      description: I18n.t(
        'Student context cards must be enabled for an account by an admin. If Courses - manage is not enabled, users can still view context cards through the Gradebook.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Courses - conclude'),
      description: I18n.t('Allows user to view the Conclude Course button.'),
    },
    {
      title: I18n.t('Courses - delete'),
      description: I18n.t('Allows user to view the Delete this Course button.'),
    },
    {
      title: I18n.t('Courses - publish'),
      description: I18n.t(
        'Allows user to view the Publish Course and Unpublish Course buttons in the Course Home page.'
      ),
    },
    {
      description: I18n.t(
        'Allows user to view the Publish button in a course card for an unpublished course (Card View Dashboard).'
      ),
    },
    {
      title: I18n.t('Courses - reset'),
      description: I18n.t('Allows user to view the Reset Course Content button.'),
    },
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Blueprint courses must be enabled for an account by an admin. Course roles can only manage content in Blueprint Courses if they are added to the Blueprint Course as a teacher, TA, or designer role.'
      ),
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'The Courses - delete permission affects viewing the Permanently Delete this Course button, which only appears for manually created courses.'
      ),
    },
    {
      description: I18n.t(
        'The Courses - Reset permission resets course content for both manually created and SIS-managed courses. (For SIS-managed courses, the SIS Data - manage permission does not apply.)'
      ),
    },
    {
      title: I18n.t('Courses'),
      description: I18n.t(
        'Courses can only be created at the course level if allowed by a Canvas admin. If allowed, courses can be created in the Dashboard.'
      ),
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(
        'The Courses - publish permission allows the user to publish courses that do not contain modules. To publish/unpublish module content, Course Content - add / edit / delete must be enabled.'
      ),
    },
  ]
)
