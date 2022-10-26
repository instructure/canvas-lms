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

const I18n = useI18nScope('permissions_templates_19')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t('Allows user to share course items directly with other users.'),
    },
    {
      description: I18n.t('Allows user to copy individual course items to another course.'),
    },
    {
      title: I18n.t('Attendance'),
      description: I18n.t('Allows user to access the Attendance tool.'),
    },
    {
      title: I18n.t('Calendar'),
      description: I18n.t(
        'Allows user to add events to List View Dashboard via the Add to Student To-Do checkbox.'
      ),
    },
    {
      title: I18n.t('Chat'),
      description: I18n.t('Allows user to access the Chat tool.'),
    },
    {
      title: I18n.t('Collaborations'),
      description: I18n.t('Allows user to view previously created collaborations.'),
    },
    {
      description: I18n.t(
        'Allows user to edit title, description, or remove collaborators on all collaborations.'
      ),
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t('Allows user to import resources from Commons into a course.'),
    },
    {
      description: I18n.t(
        'Allows user to share assignments to Commons or edit previously shared content.'
      ),
    },
    {
      title: I18n.t('Conferences'),
      description: I18n.t('Allows user to edit Conferences.'),
    },
    {
      title: I18n.t('Course Home Page'),
      description: I18n.t(
        'Allows user to view Course Status, Choose Home Page, and Course Setup Checklist buttons in the Home page.'
      ),
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to import content using the Course Import Tool.'),
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        'Allows user to add non-graded discussions to List View Dashboard via the Add to Student To-Do checkbox.'
      ),
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(
        'Allows user to manage modules (create, add items, edit module settings, publish, unpublish, etc.).'
      ),
    },
    {
      title: I18n.t('Pages'),
      description: I18n.t(
        'Allows user to add pages to List View Dashboard via the Add to Student To-Do checkbox.'
      ),
    },
    {
      title: I18n.t('Syllabus'),
      description: I18n.t('Allows user to edit the course syllabus.'),
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
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'The Course Status buttons (unpublished and published) are only displayed until a student submission is received. Courses cannot be unpublished with student submissions.'
      ),
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(
        'To publish and unpublish module content, Courses - manage and Course Content - view must also be enabled. Module items cannot be unpublished if there are student submissions.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t('Allows user to share course items directly with other users.'),
    },
    {
      description: I18n.t('Allows user to copy individual course items to another course.'),
    },
    {
      title: I18n.t('Attendance'),
      description: I18n.t('Allows user to access the Attendance tool.'),
    },
    {
      title: I18n.t('Calendar'),
      description: I18n.t(
        'Allows user to add events to List View Dashboard via the Add to Student To-Do checkbox. '
      ),
    },
    {
      title: I18n.t('Chat'),
      description: I18n.t('Allows user to access the Chat tool.'),
    },
    {
      title: I18n.t('Collaborations'),
      description: I18n.t('Allows user to view previously created collaborations.'),
    },
    {
      description: I18n.t(
        'Allows user to edit title, description, or remove collaborators on all collaborations.'
      ),
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t('Allows user to import resources from Commons into a course.'),
    },
    {
      description: I18n.t(
        'Allows user to share assignments to Commons or edit previously shared content.'
      ),
    },
    {
      title: I18n.t('Conferences'),
      description: I18n.t('Allows user to edit Conferences.'),
    },
    {
      title: I18n.t('Course Home Page'),
      description: I18n.t(
        'Allows user to view Course Status, Choose Home Page, and Course Setup Checklist buttons in the Home page.'
      ),
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to import content using the Course Import Tool.'),
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        'Allows user to add non-graded discussions to List View Dashboard via the Add to Student To-Do checkbox.'
      ),
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(
        'Allows user to manage modules (create, add items, edit module settings, publish, unpublish, etc.).'
      ),
    },
    {
      title: I18n.t('Pages'),
      description: I18n.t(
        'Allows user to add pages to List View Dashboard via the Add to Student To-Do checkbox.'
      ),
    },
    {
      title: I18n.t('Syllabus'),
      description: I18n.t('Allows user to edit the course syllabus.'),
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
  ]
)
