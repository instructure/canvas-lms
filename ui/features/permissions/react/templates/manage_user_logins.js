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

const I18n = useI18nScope('permissions_templates_46')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('People (Account)'),
      description: I18n.t('Allows user to create accounts for new users.'),
    },
    {
      description: I18n.t('Allows user to remove and merge users in an account.'),
    },
    {
      description: I18n.t('Allows user to modify user account details.'),
    },
    {
      description: I18n.t('Allows user to view and modify login information for a user.'),
    },
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t('Allows user to generate login/logout activity report in Admin Tools.'),
    },
  ],
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(
        'If Users - manage login details or Statistics - view is enabled, the user will be able to generate login/logout activity in Admin Tools. To hide the login/logout activity option in Admin Tools, both of these permissions need to be disabled.'
      ),
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        'To view users and user account details, Users - view list must be enabled.'
      ),
    },
    {
      description: I18n.t('To change user passwords, Users - view must also be enabled.'),
    },
    {
      description: I18n.t(
        'To view a user’s SIS ID, SIS Data - manage or SIS Data - read must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To view a user’s Integration ID, SIS Data - manage must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To merge users, the Self Service User Merge feature option must also be enabled.'
      ),
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).'
      ),
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t('Not available at the subaccount level.'),
    },
  ],
  [],
  []
)
