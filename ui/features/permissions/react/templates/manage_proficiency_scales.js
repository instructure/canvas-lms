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

const I18n = useI18nScope('permissions_templates_39')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Outcomes'),
      description: I18n.t(
        'Allows user to view the Outcomes Mastery tab and set outcome mastery scales at the account and course levels.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Feature Option'),
      description: I18n.t(
        'This permission requires the Account and Course Level Outcome Mastery Scales feature option, which must be enabled by a Customer Success Manager.'
      ),
    },
    {
      description: I18n.t('This feature affects existing data for an entire account.'),
    },
    {
      title: I18n.t('Outcomes'),
      description: I18n.t(
        'If the feature option is enabled, and this permission is enabled, the Outcomes page includes three tabs: Manage, Mastery, and Calculation.'
      ),
    },
    {
      description: I18n.t(
        'To access the Calculation tab, the Outcome Proficiency Calculations - add / edit permission must also be enabled. To access the Manage tab, the Learning Outcomes - add / edit / delete permission must also be enabled.'
      ),
    },
    {
      title: I18n.t('Rubrics'),
      description: I18n.t(
        'If this permission is enabled, the Learning Mastery tab displays on the Outcomes page instead of the Rubrics page.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Outcomes'),
      description: I18n.t(
        'Allows user to view the Outcomes Mastery tab and set outcome mastery scales at the course level.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Feature Option'),
      description: I18n.t(
        'This permission requires the Account and Course Level Outcome Mastery Scales feature option, which can only be enabled at the account level.'
      ),
    },
    {
      description: I18n.t('This feature affects existing data for all courses in the account.'),
    },
    {
      title: I18n.t('Outcomes'),
      description: I18n.t(
        'If the feature option is enabled, and this permission is enabled, the Outcomes page includes three tabs: Manage, Mastery, and Calculation.'
      ),
    },
    {
      description: I18n.t(
        'To access the Calculation tab, the Outcome Proficiency Calculations - add / edit permission must also be enabled. To access the Manage tab, the Learning Outcomes - add / edit / delete permission must also be enabled.'
      ),
    },
    {
      title: I18n.t('Rubrics'),
      description: I18n.t(
        'If this permission is enabled, the Learning Mastery tab displays on the Outcomes page instead of the Rubrics page.'
      ),
    },
  ]
)
