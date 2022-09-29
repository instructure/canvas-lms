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

const I18n = useI18nScope('permissions_templates_16')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(
        'Allows user to add, edit, delete, and publish and unpublish assignments.'
      ),
    },
    {
      description: I18n.t('Allows user to manage assignment settings.'),
    },
    {
      description: I18n.t('Allows user to add assignment groups in a course.'),
    },
    {
      description: I18n.t('Allows user to enable and edit assignment group weighting in a course.'),
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Allows user to edit Blueprint lock settings on the Assignments and Quizzes index pages in a Blueprint master course.'
      ),
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t('Allows user to share a quiz to Commons.'),
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t('Allows user to add new assignments to a module.'),
    },
    {
      title: I18n.t('Question Banks (Account Navigation)'),
      description: I18n.t(
        'Determines visibility and management of the Question Banks link in Account Navigation.'
      ),
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t('Allows user to add, edit, delete, and publish and unpublish quizzes.'),
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
        'To differentiate assignments to individual students, Users - view list ​must also be enabled.'
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
        'If these additional permissions are enabled, but Assignments and Quizzes - add / edit / delete is not enabled, Blueprint lock settings for an assignment can be managed from the assignment’s details page.'
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
        'To edit assignment details on individual discussions, Discussions - manage must also be enabled.'
      ),
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        'To moderate grades, Grades - Select final grade for moderation must also be enabled.'
      ),
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t('To moderate a quiz, Grades - edit​ must also be enabled.'),
    },
    {
      title: I18n.t('Rubrics'),
      description: I18n.t(
        'Disabling this permission will override (if enabled) the Rubrics - add / edit / delete permission, preventing user from creating or editing rubrics from an individual assignment.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(
        'Allows user to add, edit, delete, and publish and unpublish assignments.'
      ),
    },
    {
      description: I18n.t('Allows user to manage assignment settings.'),
    },
    {
      description: I18n.t('Allows user to add assignment groups in a course.'),
    },
    {
      description: I18n.t('Allows user to enable and edit assignment group weighting in a course.'),
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Allows user to edit Blueprint lock settings on the Assignments and Quizzes index pages in a Blueprint master course.'
      ),
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t('Allows user to share a quiz to Commons.'),
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t('Allows user to add new assignments to a module.'),
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t('Allows user to add, edit, delete, and publish and unpublish quizzes.'),
    },
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t(
        'To differentiate assignments to individual students, Users - view list ​must also be enabled.'
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
        'If these additional permissions are enabled, but Assignments and Quizzes - add / edit / delete is not enabled, Blueprint lock settings for an assignment can be managed from the assignment’s details page.'
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
        'To edit assignment details on individual discussions, Discussions - manage must also be enabled.'
      ),
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t(
        'To moderate grades, Grades - Select final grade for moderation must also be enabled.'
      ),
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t('To moderate a quiz, Grades - edit​ must also be enabled.'),
    },
    {
      title: I18n.t('Rubrics'),
      description: I18n.t(
        'Disabling this permission will override (if enabled) the Rubrics - add / edit / delete permission, preventing user from creating or editing rubrics from an individual assignment.'
      ),
    },
  ]
)
