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

const I18n = useI18nScope('permissions_templates_manage_course_content')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Course Content - add'),
      description: I18n.t('Allows user to share course items directly with other users.'),
    },
    {
      description: I18n.t('Allows user to copy individual course items to another course.'),
    },
    {
      description: I18n.t('Allows user to view course copy status.'),
    },
    {
      description: I18n.t('Allows user to create content migrations.'),
    },
    {
      description: I18n.t('Allows user to create blackout dates.'),
    },
    {
      description: I18n.t(
        'Allows user to add events to Calendar List View Dashboard via the Add to Student To-Do checkbox. '
      ),
    },
    {
      description: I18n.t('Allows user to create a course pace via Course Pacing.'),
    },
    {
      description: I18n.t('Allows user to import resources from Commons into a course.'),
    },
    {
      description: I18n.t('Allows user to import content using the Course Import Tool.'),
    },
    {
      description: I18n.t(
        'Allows user to add non-graded discussions to List View Dashboard via the Add to Student To-Do checkbox.'
      ),
    },
    {
      description: I18n.t('Allows user to create, add items, and duplicate modules.'),
    },
    {
      description: I18n.t(
        'Allows user to add pages to List View Dashboard via the Add to Student To-Do checkbox.'
      ),
    },
    {
      title: I18n.t('Course Content - edit'),
      description: I18n.t(
        'Allows user to lock / unlock selected announcements individually or in bulk.'
      ),
    },
    {
      description: I18n.t('Allows user to edit a list of assignment blackout dates.'),
    },
    {
      description: I18n.t(
        'Allows user to share assignments to Commons or edit previously shared content.'
      ),
    },
    {
      description: I18n.t('Allows user to edit to-do date on a course Page that supports it.'),
    },
    {
      description: I18n.t('Allows user to edit Conferences.'),
    },
    {
      description: I18n.t('Allows user to edit title, and description on all collaborations.'),
    },
    {
      description: I18n.t(
        'Allows user to update modules (edit module settings, publish, unpublish, batch edit).'
      ),
    },
    {
      description: I18n.t('Allows user to edit content migrations.'),
    },
    {
      description: I18n.t('Allows user to edit and publish a course pace via Course Pacing.'),
    },
    {
      description: I18n.t('Allows user to edit the course syllabus.'),
    },
    {
      description: I18n.t('Allows user to edit course tabs.'),
    },
    {
      title: I18n.t('Course Content - delete'),
      description: I18n.t('Allows user to remove selected announcements individually or in bulk.'),
    },
    {
      description: I18n.t('Allows user to remove assignment blackout dates.'),
    },
    {
      description: I18n.t('Allows user to remove collaborators on all collaborations.'),
    },
    {
      title: I18n.t('Course Content - add / edit / or delete'),
      description: I18n.t(
        'Allows user to have full section visibility when viewing announcements.'
      ),
    },
    {
      description: I18n.t('Allows user to access the Attendance tool.'),
    },
    {
      description: I18n.t(
        'Allows user to view Course Status, Choose Home Page, and Course Setup Checklist buttons in the Home page.'
      ),
    },
    {
      description: I18n.t('Allows user to access the Chat tool.'),
    },
    {
      description: I18n.t('Allows user to view course Conferences.'),
    },
    {
      description: I18n.t('Allows user to view and list content migrations.'),
    },
    {
      description: I18n.t('Allows user to view a content migration content list by type.'),
    },
    {
      description: I18n.t(
        'Allows user access to LTI sub navigation tool selection for assignment syllabus configuration.'
      ),
    },
    {
      description: I18n.t('Allows user to view or retrieve a list of assignment blackout dates.'),
    },
    {
      description: I18n.t(
        'Allows user to view a content migration notice to an "import in progress".'
      ),
    },
    {
      description: I18n.t('Allows user to view previously created collaborations.'),
    },
    {
      description: I18n.t('Allows user to view and list course paces via Course Pacing.'),
    },
    {
      description: I18n.t('Allows user to view and initiate course link validation.'),
    },
  ],
  [
    {
      title: I18n.t('Attendance'),
      description: I18n.t('The Attendance tool must be enabled by your Canvas admin.'),
    },
    {
      title: I18n.t('Chat'),
      description: I18n.t('The Chat tool must be enabled by your Canvas admin.'),
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t(
        'To share a Discussion to Commons, Discussions - view must also be enabled.'
      ),
    },
    {
      title: I18n.t('Course Home Page'),
      description: I18n.t(
        'Teachers, designers, and TAs can select a course home page without the Course content - add / edit / delete permission.'
      ),
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'The Course Status buttons (unpublished and published) are only displayed until a student submission is received. Courses cannot be unpublished with student submissions.'
      ),
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t('Module items cannot be unpublished if there are student submissions.'),
    },
    {
      title: I18n.t('Course Pacing'),
      description: I18n.t('Course Pacing feature preview must be enabled in your institution.'),
    },
  ],
  [
    {
      title: I18n.t('Course Content - add'),
      description: I18n.t('Allows user to share course items directly with other users.'),
    },
    {
      description: I18n.t('Allows user to copy individual course items to another course.'),
    },
    {
      description: I18n.t('Allows user to view course copy status.'),
    },
    {
      description: I18n.t('Allows user to create content migrations.'),
    },
    {
      description: I18n.t('Allows user to create blackout dates.'),
    },
    {
      description: I18n.t(
        'Allows user to add events to Calendar List View Dashboard via the Add to Student To-Do checkbox. '
      ),
    },
    {
      description: I18n.t('Allows user to create a course pace via Course Pacing.'),
    },
    {
      description: I18n.t('Allows user to import resources from Commons into a course.'),
    },
    {
      description: I18n.t('Allows user to import content using the Course Import Tool.'),
    },
    {
      description: I18n.t(
        'Allows user to add non-graded discussions to List View Dashboard via the Add to Student To-Do checkbox.'
      ),
    },
    {
      description: I18n.t('Allows user to create, add items, and duplicate modules.'),
    },
    {
      description: I18n.t(
        'Allows user to add pages to List View Dashboard via the Add to Student To-Do checkbox.'
      ),
    },
    {
      title: I18n.t('Course Content - edit'),
      description: I18n.t(
        'Allows user to lock / unlock selected announcements individually or in bulk.'
      ),
    },
    {
      description: I18n.t('Allows user to edit a list of assignment blackout dates.'),
    },
    {
      description: I18n.t(
        'Allows user to share assignments to Commons or edit previously shared content.'
      ),
    },
    {
      description: I18n.t('Allows user to edit to-do date on a course Page that supports it.'),
    },
    {
      description: I18n.t('Allows user to edit Conferences.'),
    },
    {
      description: I18n.t('Allows user to edit title, and description on all collaborations.'),
    },
    {
      description: I18n.t(
        'Allows user to update modules (edit module settings, publish, unpublish, batch edit).'
      ),
    },
    {
      description: I18n.t('Allows user to edit content migrations.'),
    },
    {
      description: I18n.t('Allows user to edit and publish a course pace via Course Pacing.'),
    },
    {
      description: I18n.t('Allows user to edit the course syllabus.'),
    },
    {
      description: I18n.t('Allows user to edit course tabs.'),
    },
    {
      title: I18n.t('Course Content - delete'),
      description: I18n.t('Allows user to remove selected announcements individually or in bulk.'),
    },
    {
      description: I18n.t('Allows user to remove assignment blackout dates.'),
    },
    {
      description: I18n.t('Allows user to remove collaborators on all collaborations.'),
    },
    {
      title: I18n.t('Course Content - add / edit / or delete'),
      description: I18n.t(
        'Allows user to have full section visibility when viewing announcements.'
      ),
    },
    {
      description: I18n.t('Allows user to access the Attendance tool.'),
    },
    {
      description: I18n.t(
        'Allows user to view Course Status, Choose Home Page, and Course Setup Checklist buttons in the Home page.'
      ),
    },
    {
      description: I18n.t('Allows user to access the Chat tool.'),
    },
    {
      description: I18n.t('Allows user to view course Conferences.'),
    },
    {
      description: I18n.t('Allows user to view and list content migrations.'),
    },
    {
      description: I18n.t('Allows user to view a content migration content list by type.'),
    },
    {
      description: I18n.t(
        'Allows user access to LTI sub navigation tool selection for assignment syllabus configuration.'
      ),
    },
    {
      description: I18n.t('Allows user to view or retrieve a list of assignment blackout dates.'),
    },
    {
      description: I18n.t(
        'Allows user to view a content migration notice to an "import in progress".'
      ),
    },
    {
      description: I18n.t('Allows user to view previously created collaborations.'),
    },
    {
      description: I18n.t('Allows user to view and list course paces via Course Pacing.'),
    },
    {
      description: I18n.t('Allows user to view and initiate course link validation.'),
    },
  ],
  [
    {
      title: I18n.t('Attendance'),
      description: I18n.t('The Attendance tool must be enabled by your Canvas admin.'),
    },
    {
      title: I18n.t('Chat'),
      description: I18n.t('The Chat tool must be enabled by your Canvas admin.'),
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t(
        'To share a Discussion to Commons, Discussions - view must also be enabled.'
      ),
    },
    {
      title: I18n.t('Course Home Page'),
      description: I18n.t(
        'Teachers, designers, and TAs can select a course home page without the Course content - add / edit / delete permission.'
      ),
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'The Course Status buttons (unpublished and published) are only displayed until a student submission is received. Courses cannot be unpublished with student submissions.'
      ),
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t('Module items cannot be unpublished if there are student submissions.'),
    },
    {
      title: I18n.t('Course Pacing'),
      description: I18n.t('Course Pacing feature preview must be enabled in your institution.'),
    },
  ]
)
