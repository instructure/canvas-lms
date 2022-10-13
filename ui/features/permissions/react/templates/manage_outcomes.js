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

const I18n = useI18nScope('permissions_templates_37')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Outcomes'),
      description: I18n.t(
        'Determines visibility and management of the Outcomes link in Account Navigation.'
      ),
    },
    {
      description: I18n.t(
        'Allows user to view the Outcomes Manage tab at the account and course levels.'
      ),
    },
    {
      description: I18n.t(
        'Allows user to create, edit, and delete outcomes and outcome groups at the account and course levels.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Feature Option'),
      description: I18n.t(
        'If the Account and Course Level Outcome Mastery Scales feature option is enabled, the Manage tab displays an updated interface. Additionally, the Outcomes page will display two additional tabs that decouple mastery scales and proficiency calculations from outcomes management.'
      ),
    },
    {
      description: I18n.t(
        'Access to these tabs requires the Outcome Proficiency Calculations - add / edit and Outcome Mastery Scales - add / edit permissions.'
      ),
    },
    {
      title: I18n.t('Outcomes'),
      description: I18n.t(
        'To allow the Outcomes page as read-only, this permission can be disabled but Course Content - view must be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To import learning outcomes, Learning Outcomes - import must also be enabled.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Outcomes'),
      description: I18n.t(
        'Allows user to create, edit, and delete outcomes and outcome groups at the course level.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Feature Option'),
      description: I18n.t(
        'If the Account and Course Level Outcome Mastery Scales feature option is enabled, the Manage tab displays an updated interface. Additionally, the Outcomes page will display two additional tabs that decouple mastery scales and proficiency calculations from outcomes management.'
      ),
    },
    {
      description: I18n.t(
        'Access to these tabs requires the Outcome Proficiency Calculations - add / edit and Outcome Mastery Scales - add / edit permissions.'
      ),
    },
    {
      title: I18n.t('Outcomes'),
      description: I18n.t(
        'To allow the Outcomes page as read-only, this permission can be disabled but Course Content - view must be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To import learning outcomes, Learning Outcomes - import must also be enabled.'
      ),
    },
  ]
)
