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

const I18n = useI18nScope('permissions_templates_33')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(
        'Allows user to search by course ID or assignment ID in grade change logs in Admin Tools (not available at the subaccount level.)'
      ),
    },
    {
      title: I18n.t('Analytics'),
      description: I18n.t('Allows user to view student-specific data in Analytics.'),
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to view the course grading scheme.'),
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        'Allows user to like discussion posts when the Only Graders Can Like checkbox is selected.'
      ),
    },
    {
      title: I18n.t('Gradebook'),
      description: I18n.t('Allows user to add, edit, and update grades in the Gradebook.'),
    },
    {
      description: I18n.t(
        'Allows user to access Gradebook History. Allows user to access the Learning Mastery Gradebook (if enabled).'
      ),
    },
    {
      title: I18n.t('Grading Schemes'),
      description: I18n.t('Allows user to create and modify grading schemes.'),
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t('Allows user to moderate a quiz and view the quiz statistics page.'),
    },
    {
      title: I18n.t('SpeedGrader'),
      description: I18n.t('Allows user to edit grades and add comments in SpeedGrader.'),
    },
  ],
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(
        'To search grade change logs, Grades - view change logs must also be enabled.'
      ),
    },
    {
      title: I18n.t('Analytics'),
      description: I18n.t(
        'To view student analytics in course analytics, Analytics - view must also be enabled.'
      ),
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('To edit course grading schemes, Courses - manage must also be enabled.'),
    },
    {
      title: I18n.t('Gradebook, SpeedGrader'),
      description: I18n.t(
        'Gradebook and SpeedGrader will be inaccessible if both Grades - edit and Grades - view all grades are disabled.'
      ),
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'To view student analytics, Users - view list and Analytics - view must also be enabled.'
      ),
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        'To moderate a quiz, Assignments and Quizzes - manage / edit must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To view the user SIS ID column in the Quiz Item Analysis CSV file, SIS Data - read must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To view the submission log, Quizzes - view submission log must also be enabled.'
      ),
    },
    {
      title: I18n.t('Reports'),
      description: I18n.t(
        'To access the Student Interactions report, Reports - manage must also be enabled.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Analytics'),
      description: I18n.t('Allows user to view student-specific data in Analytics.'),
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to edit grading schemes.'),
    },
    {
      title: I18n.t('Discussions'),
      description: I18n.t(
        'Allows user to like discussion posts when the Only Graders Can Like checkbox is selected.'
      ),
    },
    {
      title: I18n.t('Gradebook'),
      description: I18n.t('Allows user to edit grades in the Gradebook.'),
    },
    {
      description: I18n.t('Allows user to access Gradebook History.'),
    },
    {
      description: I18n.t('Allows user to access the Learning Mastery Gradebook (if enabled).'),
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t('Allows user to moderate a quiz and view the quiz statistics page.'),
    },
    {
      title: I18n.t('SpeedGrader'),
      description: I18n.t('Allows user to edit grades and add comments in SpeedGrader.'),
    },
  ],
  [
    {
      title: I18n.t('Analytics'),
      description: I18n.t(
        'To view student analytics in course analytics, Analytics - view must also be enabled.'
      ),
    },
    {
      title: I18n.t('Gradebook, SpeedGrader'),
      description: I18n.t(
        'Gradebook and SpeedGrader will be inaccessible if both Grades - edit and Grades - view all grades are disabled.'
      ),
    },
    {
      title: I18n.t('People'),
      description: I18n.t(
        'To view student analytics, Users - view list and Analytics - view must also be enabled.'
      ),
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        'To moderate a quiz, Assignments and Quizzes - manage / edit must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To view the user SIS ID column in the Quiz Item Analysis CSV file, SIS Data - read must also be enabled.'
      ),
    },
    {
      title: I18n.t('Settings'),
      description: I18n.t('Course Grading Schemes can be enabled/disabled in Course Settings.'),
    },
  ]
)
