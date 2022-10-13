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

const I18n = useI18nScope('permissions_templates_2')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('People (Account)'),
      description: I18n.t('Allows user to act as other users in the account.'),
    },
    {
      description: I18n.t(
        'This permission should only be assigned to users that your institution has authorized to act as other users in your entire Canvas account.'
      ),
    },
    {
      description: I18n.t(
        'Users with this permission may be able to use the Act as feature to manage account settings, view and adjust grades, access user information, etc. This permissions also allows admins designated to a sub-account to access settings and information outside of their sub-account.'
      ),
    },
    {
      title: I18n.t('Student Context Card'),
      description: I18n.t('Allows user to access the Act as User link on student context cards.'),
    },
    {
      title: I18n.t('SpeedGrader'),
      description: I18n.t('Allows user to delete a submission file.'),
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t('Allows user to view Login IDs in a course People page.'),
    },
  ],
  [
    {
      title: I18n.t('API'),
      description: I18n.t('The Roles API refers to this permission as become_user.'),
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        'To view the list of users in an account, Users - view list must be enabled.'
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
  [],
  []
)
