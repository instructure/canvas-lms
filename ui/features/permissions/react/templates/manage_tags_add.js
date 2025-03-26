/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import {generateActionTemplates} from '../generateActionTemplates'

const I18n = createI18nScope('permissions_templates_34')

export const template = generateActionTemplates(
  [
    // Account "WHAT IT DOES"
  ],
  [
    // Account "OTHER CONSIDERATIONS"
  ],
  [
    {
      title: I18n.t('Allows'),
      description: I18n.t('This permission controls the ability to:'),
    },
    {
      description: I18n.t('Create new differentiation tags'),
    },
    {
      description: I18n.t('Add users to differentiation tags'),
    },
    {
      title: I18n.t('Warning'),
      description: I18n.t(
        'This permission does not allow a user to edit a differentiation tag after it has been created.',
      ),
    },
  ],
  [
    // course "OTHER CONSIDERATIONS"
  ],
)
