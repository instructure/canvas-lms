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

const I18n = useI18nScope('permissions_templates_47')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Global Navigation'),
      description: I18n.t('Allows user to view the Faculty Journal link in Global Navigation.'),
    },
    {
      title: I18n.t('Student Interaction Report'),
      description: I18n.t(
        'Allows user to view Faculty Journal entries in the Student Interactions Report.'
      ),
    },
    {
      title: I18n.t('User Details'),
      description: I18n.t(
        'Allows user to view a link to the Faculty Journal in the User Details page sidebar.'
      ),
    },
    {
      description: I18n.t(
        'Allows user to view Faculty Journal information for individual students.'
      ),
    },
    {
      description: I18n.t('Allows user to create new entries in the Faculty Journal.'),
    },
  ],
  [
    {
      title: I18n.t('Reports'),
      description: I18n.t(
        'To view the Student Interactions Report, Grades - view all grades and Reports - manage must also be enabled.'
      ),
    },
    {
      title: I18n.t('User Details'),
      description: I18n.t(
        'To view the User Details page for a student, Users - add/remove students in courses must also be enabled.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Student Interaction Report'),
      description: I18n.t(
        'Allows user to view Faculty Journal entries in the Student Interactions Report.'
      ),
    },
    {
      title: I18n.t('User Details'),
      description: I18n.t(
        'Allows user to view a link to the Faculty Journal in the User Details page sidebar.'
      ),
    },
    {
      description: I18n.t(
        'Allows user to view Faculty Journal information for individual students.'
      ),
    },
    {
      description: I18n.t('Allows user to create new entries in the Faculty Journal.'),
    },
  ],
  [
    {
      title: I18n.t('Reports'),
      description: I18n.t(
        'To view the Student Interactions Report, Grades - view all grades and Reports - manage must also be enabled.'
      ),
    },
    {
      title: I18n.t('User Details'),
      description: I18n.t(
        'To view the User Details page for a student, Users - add/remove students in courses must also be enabled.'
      ),
    },
  ]
)
