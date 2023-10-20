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

const I18n = useI18nScope('permissions_templates_14')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(
        'Allows user to view and manage the Settings and Notifications tabs in Account Settings.'
      ),
    },
    {
      title: I18n.t('Authentication'),
      description: I18n.t(
        'Allows user to view and manage authentication options for the whole account.'
      ),
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t('Allows user to view and manage subaccounts for the account.'),
    },
    {
      title: I18n.t('Terms'),
      description: I18n.t('Allows user to view and manage terms for the account.'),
    },
    {
      title: I18n.t('Theme Editor'),
      description: I18n.t('Allows user to access the Theme Editor.'),
    },
  ],
  [
    {
      title: I18n.t('Announcements'),
      description: I18n.t(
        'The Announcements tab is always visible to admins; however, to manage announcements, Global Announcements - add / edit / delete must also be enabled.'
      ),
    },
    {
      title: I18n.t('Feature Options (Account Settings)'),
      description: I18n.t(
        'To manage the Feature Options tab, Feature Options - enable disable - must also be enabled.'
      ),
    },
    {
      title: I18n.t('Reports (Account Settings)'),
      description: I18n.t('To view the Reports tab, Reports - manage must also be enabled.'),
    },
    {
      title: I18n.t('Subaccount Navigation (Account Settings)'),
      description: I18n.t(
        'Not all settings options are available at the subaccount level, including the Notifications tab.'
      ),
    },
  ],
  [],
  []
)
