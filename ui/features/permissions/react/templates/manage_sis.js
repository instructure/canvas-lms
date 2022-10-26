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

const I18n = useI18nScope('permissions_templates_43')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Account Navigation'),
      description: I18n.t('Determines visibility of SIS Import link in Account Navigation.'),
    },
    {
      description: I18n.t(
        'Allows user to view the previous SIS import dates, errors, and imported items.'
      ),
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to edit the course SIS ID.'),
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        'Allows user to view and edit the SIS ID and Integration ID in a user’s Login Details.'
      ),
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t('Allows user to edit the course SIS ID.'),
    },
    {
      title: I18n.t('Subaccount Settings'),
      description: I18n.t('Allows user to view and insert data in the SIS ID field.'),
    },
  ],
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('To edit course settings, Courses - manage must be enabled.'),
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        'To view or edit a user’s SIS ID or Integration ID, Users - view list and Users - manage login details must also both be enabled.'
      ),
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'If this permission is enabled, users do not need the SIS Data - read permission enabled. The account permission overrides the course permission.'
      ),
    },
    {
      description: I18n.t(
        'To disallow users from managing SIS IDs at the course level, SIS Data - manage and SIS Data - read must both be disabled.'
      ),
    },
    {
      description: I18n.t(
        'To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).'
      ),
    },
    {
      title: I18n.t('SIS Import'),
      description: I18n.t('To import SIS data, SIS Data - import must also be enabled.'),
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t('Not available at the subaccount level.'),
    },
  ],
  [],
  []
)
