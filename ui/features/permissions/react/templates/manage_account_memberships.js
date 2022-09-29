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

const I18n = useI18nScope('permissions_templates_13')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t('Allows user to add and remove other account admins.'),
    },
    {
      title: I18n.t('Commons'),
      description: I18n.t('Allows user to access and edit the Admin settings in Commons.'),
    },
    {
      description: I18n.t(
        'Allows user to create and manage Groups. Allows user to manage shared resources in the account.'
      ),
    },
    {
      description: I18n.t('Allows user to manage shared resources in the account.'),
    },
  ],
  [],
  [],
  []
)
