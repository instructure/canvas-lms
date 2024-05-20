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

const I18n = useI18nScope('permissions_templates_12')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Item Banks'),
      description: I18n.t('Allows a user to manage sharing of item banks with subaccounts.'),
    },
  ],
  [
    {
      title: I18n.t('Item Banks'),
      description: I18n.t(
        'If this permission is disabled, users cannot share item banks to subaccounts. When a user with an admin role is granted this permission, the user can share item banks to subaccounts they administer.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Item Banks'),
      description: I18n.t('Allows a user to manage sharing of item banks with subaccounts.'),
    },
  ],
  [
    {
      title: I18n.t('Item Banks'),
      description: I18n.t(
        'If this permission is disabled, users cannot share item banks to subaccounts. When a user with a course role is granted this permission, the user can share item banks to subaccounts they are associated with.'
      ),
    },
  ]
)
