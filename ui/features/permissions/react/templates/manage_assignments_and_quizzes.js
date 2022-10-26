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

const I18n = useI18nScope('permissions_templates_17')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Assignments and Quizzes - add'),
      description: I18n.t('Allows user to add assignments in a course.'),
    },
    {
      description: I18n.t('Allows user to add assignment groups in a course.'),
    },
    {
      description: I18n.t('Allows user to duplicate assignments in a course.'),
    },
    {
      description: I18n.t('Allows user to add new assignments to a module.'),
    },
    {
      description: I18n.t('Allows user to add new question banks to a course or account.'),
    },
    {
      description: I18n.t(
        'Allows user to add new questions to new or existing question banks in a course or account.'
      ),
    },
    {
      description: I18n.t('Allows user to add quizzes in a course.'),
    },
    {
      description: I18n.t('Allows user to duplicate quizzes in a course.'),
    },
    {
      title: I18n.t('Assignments and Quizzes - edit'),
      description: I18n.t('Allows user to edit and publish/unpublish assignments.'),
    },
    {
      description: I18n.t('Allows user to manage assignment settings.'),
    },
    {
      description: I18n.t('Allows user to weight assignment groups.'),
    },
    {
      description: I18n.t(
        'Allows user to edit lock settings on the Assignments and Quizzes index pages.'
      ),
    },
    {
      description: I18n.t('Allows user to share an assignment to Commons.'),
    },
    {
      description: I18n.t('Allows user to share a quiz to Commons.'),
    },
    {
      description: I18n.t(
        'Determines visibility and management of the Question Banks link in Account Navigation.'
      ),
    },
    {
      description: I18n.t('Allows user to edit and publish/unpublish quizzes.'),
    },
    {
      description: I18n.t('Allows user to edit question banks in a course or account.'),
    },
    {
      title: I18n.t('Assignments and Quizzes - delete'),
      description: I18n.t('Allows user to delete assignments in a course.'),
    },
    {
      description: I18n.t('Allows user to delete assignment groups in a course.'),
    },
    {
      description: I18n.t('Allows user to delete quizzes in a course.'),
    },
    {
      description: I18n.t('Allows user to delete question banks in a course or account.'),
    },
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(
        'To access the Assignments Index Page, Course Content - view must be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To differentiate assignments to individual students, Users - view list must also be enabled.'
      ),
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'To edit lock settings from the Assignments index page, Blueprint Courses - add / edit / associate / delete and Courses - manage must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'If Blueprint Courses - add / edit / associate / delete and Courses - manage are enabled, but Assignments and Quizzes - edit is not enabled, blueprint lock settings for an assignment can be managed from the assignment’s details page.'
      ),
    },
    {
      description: I18n.t(
        'To edit lock settings on an individual quiz, or on the Quizzes index page, Blueprint Courses - add / edit / associate / delete and Courses - manage must also be enabled.'
      ),
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'To import assignments and quizzes using the Course Import Tool, Course Content - add / edit / delete must be enabled.'
      ),
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        'These permissions do not manage Discussions. Discussions are managed via individual Discussion permissions.'
      ),
    },
    {
      description: I18n.t(
        'To edit assignment details on individual discussions, Discussions - manage must also be enabled.'
      ),
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        'To manage moderated grading, Grades - Select final grade for moderation must also be enabled.'
      ),
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        'To access the Quizzes Index Page, Course Content - view must be enabled.'
      ),
    },
    {
      description: I18n.t('To moderate a quiz, Grades - edit must also be enabled.'),
    },
    {
      description: I18n.t(
        'To access item banks for a course or account, Item Banks - manage account must also be enabled.'
      ),
    },
    {
      title: I18n.t('Rubrics'),
      description: I18n.t(
        'Disabling the Assignments and Quizzes - add permission will override (if enabled) the Rubrics - add / edit / delete permission, preventing user from creating rubrics for an individual assignment.'
      ),
    },
    {
      description: I18n.t(
        'Disabling the Assignments and Quizzes - edit permission will override (if enabled) the Rubrics - add / edit / delete permission, preventing users from editing rubrics from an individual assignment.'
      ),
    },
    {
      description: I18n.t(
        'Disabling the Assignments and Quizzes - delete permission will override (if enabled) the Rubrics - add / edit / delete permission, preventing user from deleting rubrics for an individual assignment.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Assignments and Quizzes - add'),
      description: I18n.t('Allows user to add assignments in a course.'),
    },
    {
      description: I18n.t('Allows user to add assignment groups in a course.'),
    },
    {
      description: I18n.t('Allows user to duplicate assignments in a course.'),
    },
    {
      description: I18n.t('Allows user to add new assignments to a module.'),
    },
    {
      description: I18n.t('Allows user to add new question banks to a course.'),
    },
    {
      description: I18n.t(
        'Allows user to add new questions to new or existing question banks in a course.'
      ),
    },
    {
      description: I18n.t('Allows user to add quizzes in a course.'),
    },
    {
      description: I18n.t('Allows user to duplicate quizzes in a course.'),
    },
    {
      title: I18n.t('Assignments and Quizzes - edit'),
      description: I18n.t('Allows user to edit and publish/unpublish assignments.'),
    },
    {
      description: I18n.t('Allows user to manage assignment settings.'),
    },
    {
      description: I18n.t('Allows user to weight assignment groups.'),
    },
    {
      description: I18n.t(
        'Allows user to edit lock settings on the Assignments and Quizzes index pages.'
      ),
    },
    {
      description: I18n.t('Allows user to share an assignment to Commons.'),
    },
    {
      description: I18n.t('Allows user to share a quiz to Commons.'),
    },
    {
      description: I18n.t('Allows user to edit and publish/unpublish quizzes.'),
    },
    {
      title: I18n.t('Assignments and Quizzes - delete'),
      description: I18n.t('Allows user to delete assignments in a course.'),
    },
    {
      description: I18n.t('Allows user to delete assignment groups in a course.'),
    },
    {
      description: I18n.t('Allows user to delete quizzes in a course.'),
    },
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(
        'To access the Assignments Index Page, Course Content - view must be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To differentiate assignments to individual students, Users - view list must also be enabled.'
      ),
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'To edit lock settings from the Assignments index page, Blueprint Courses - add / edit / associate / delete and Courses - manage must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'If Blueprint Courses - add / edit / associate / delete and Courses - manage are enabled, but Assignments and Quizzes - edit is not enabled, blueprint lock settings for an assignment can be managed from the assignment’s details page.'
      ),
    },
    {
      description: I18n.t(
        'To edit lock settings on an individual quiz, or on the Quizzes index page, Blueprint Courses - add / edit / associate / delete and Courses - manage must also be enabled.'
      ),
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'To import assignments and quizzes using the Course Import Tool, Course Content - add / edit / delete must be enabled.'
      ),
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        'These permissions do not manage Discussions. Discussions are managed via individual Discussion permissions.'
      ),
    },
    {
      description: I18n.t(
        'To edit assignment details on individual discussions, Discussions - manage must also be enabled.'
      ),
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        'To manage moderated grading, Grades - Select final grade for moderation must also be enabled.'
      ),
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        'To access the Quizzes Index Page, Course Content - view must be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To edit quizzes, Assignments and Quizzes - manage / edit must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To access item banks for a course, Item Banks - manage account must also be enabled.'
      ),
    },
    {
      description: I18n.t('To moderate a quiz, Grades - edit must also be enabled.'),
    },
    {
      title: I18n.t('Rubrics'),
      description: I18n.t(
        'Disabling the Assignments and Quizzes - add permission will override (if enabled) the Rubrics - add / edit / delete permission, preventing user from creating rubrics for an individual assignment.'
      ),
    },
    {
      description: I18n.t(
        'Disabling the Assignments and Quizzes - edit permission will override (if enabled) the Rubrics - add / edit / delete permission, preventing users from editing rubrics from an individual assignment.'
      ),
    },
    {
      description: I18n.t(
        'Disabling the Assignments and Quizzes - delete permission will override (if enabled) the Rubrics - add / edit / delete permission, preventing user from deleting rubrics for an individual assignment.'
      ),
    },
  ]
)
