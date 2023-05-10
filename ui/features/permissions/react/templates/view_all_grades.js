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

const I18n = useI18nScope('permissions_templates_66')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t('Allows user to search by assignment ID in grade change logs.'),
    },
    {
      title: I18n.t('Analytics'),
      description: I18n.t('Allows user to view student-specific data in Analytics.'),
    },
    {
      title: I18n.t('Assignments, SpeedGrader'),
      description: I18n.t('Allows user to view a link to SpeedGrader from assignments.'),
    },
    {
      title: I18n.t('Gradebook'),
      description: I18n.t(
        'Allows user to export the Gradebook to a comma separated values (CSV) file.'
      ),
    },
    {
      description: I18n.t('Allows user to access the Learning Mastery Gradebook (if enabled).'),
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t('Allows user to view student Grades pages.'),
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t('Allows user to access the Student Progress page.'),
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t('Allows user to view analytics link in the user settings menu.'),
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        'Allows user to view student results, view quiz statistics, and access a quiz in SpeedGrader.'
      ),
    },
    {
      title: I18n.t('Rubrics, SpeedGrader'),
      description: I18n.t('Allows user to view grader comments on a rubric in SpeedGrader.'),
    },
    {
      title: I18n.t('Student Context Card'),
      description: I18n.t('Adds analytics to a student’s context card.'),
    },
  ],
  [
    {
      title: I18n.t('Admin Tools (Grade Change Logs)'),
      description: I18n.t(
        'To search grade change logs, Grades - view change logs must also be enabled.'
      ),
    },
    {
      title: I18n.t('Analytics'),
      description: I18n.t('To view student analytics, Analytics - view must also be enabled.'),
    },
    {
      title: I18n.t('Gradebook'),
      description: I18n.t('To view the Gradebook, Course Content - view must also be enabled.'),
    },
    {
      description: I18n.t(
        'If both Grades - edit and Grades - view all grades are disabled, Gradebook will be hidden from Course Navigation.'
      ),
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t('To post or hide grades, Grades - edit must also be enabled.'),
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(
        'To view module progression, Grades - view all grades must also be enabled.'
      ),
    },
    {
      title: I18n.t('Reports'),
      description: I18n.t(
        'To access the Student Interactions report, Reports - manage must also be enabled.'
      ),
    },
    {
      title: I18n.t('Student Context Card'),
      description: I18n.t('Student Context Cards must be enabled for an account by an admin.'),
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t('Not available at the subaccount level.'),
    },
  ],
  [
    {
      title: I18n.t('Analytics'),
      description: I18n.t('Allows user to view student-specific data in Analytics.'),
    },
    {
      title: I18n.t('Assignments, SpeedGrader'),
      description: I18n.t('Allows user to access SpeedGrader from an assignment.'),
    },
    {
      title: I18n.t('Gradebook'),
      description: I18n.t('Allows user to view Gradebook.'),
    },
    {
      description: I18n.t(
        'Allows user to export the Gradebook to a comma separated values (CSV) file.'
      ),
    },
    {
      description: I18n.t('Allows user to access the Learning Mastery Gradebook (if enabled).'),
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t('Allows user to view student Grades pages.'),
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t('Allows user to access the Student Progress page.'),
    },
    {
      title: I18n.t('People'),
      description: I18n.t('Adds analytics link on the user settings menu.'),
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        'Allows user to view student results, view quiz statistics, and access a quiz in SpeedGrader.'
      ),
    },
    {
      title: I18n.t('Rubrics, SpeedGrader'),
      description: I18n.t('Allows user to view grader comments on a rubric in SpeedGrader.'),
    },
    {
      title: I18n.t('Student Context Card'),
      description: I18n.t('Adds analytics to a student’s context card.'),
    },
  ],
  [
    {
      title: I18n.t('Analytics'),
      description: I18n.t('To view student analytics, Analytics - view must also be enabled.'),
    },
    {
      title: I18n.t('Gradebook'),
      description: I18n.t(
        'If both Grades - edit and Grades - view all grades are disabled, Gradebook will be hidden from Course Navigation.'
      ),
    },
    {
      title: I18n.t('Grades'),
      description: I18n.t('To post or hide grades, Grades - edit must also be enabled.'),
    },
    {
      title: I18n.t('Modules'),
      description: I18n.t(
        'To view module progression, Grades - view all grades must also be enabled.'
      ),
    },
    {
      title: I18n.t('Reports'),
      description: I18n.t(
        'To access the Student Interactions report, Reports - manage must also be enabled.'
      ),
    },
    {
      title: I18n.t('Student Context Card'),
      description: I18n.t('Student Context Cards must be enabled for an account by an admin.'),
    },
  ]
)
