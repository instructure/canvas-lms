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

const I18n = useI18nScope('permissions_templates_61')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to view a course’s SIS ID.'),
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t('Allows user to view the SIS ID in a user’s login details.'),
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t('Allows user to view user SIS IDs in a course People page.'),
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        'Allows user to view the user SIS ID column in the Quiz Item Analysis CSV file.'
      ),
    },
    {
      title: I18n.t('SIS'),
      description: I18n.t('Governs account-related SIS IDs (i.e., subaccount SIS ID).'),
    },
  ],
  [
    {
      title: I18n.t('Account and Subaccount'),
      description: I18n.t(
        'Users and terms are located at the account, so the SIS endpoint always confirms the user’s permissions according to account.'
      ),
    },
    {
      description: I18n.t(
        'Subaccounts only have ownership of courses and sections; they do not own user data. Subaccount admins are not able to view SIS information unless they are also granted an instructor role in a course.'
      ),
    },
    {
      description: I18n.t(
        'Subaccount admins are not able to view SIS information unless they are also granted an instructor role in a course.'
      ),
    },
    {
      description: I18n.t(
        'Subaccount admins cannot view SIS information without the course association, as the instructor role has permission to read SIS data at the account level.'
      ),
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        'To view a user’s login details, Users - view list and Modify login details for users must also both be enabled.'
      ),
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).'
      ),
    },
    {
      title: I18n.t('SIS Import'),
      description: I18n.t('To manage SIS data, SIS Data - manage must be enabled.'),
    },
    {
      description: I18n.t(
        'If SIS Data - manage is enabled and SIS Data - read is disabled, the account permission overrides the course permission.'
      ),
    },
    {
      description: I18n.t(
        'If SIS Data - manage is disabled and SIS Data - read is enabled, users can only view course, user, and subaccount SIS IDs.'
      ),
    },
    {
      description: I18n.t(
        'To disallow users from viewing any SIS IDs at the course level, SIS Data - manage and SIS Data - read must both be disabled.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to view course SIS ID.'),
    },
    {
      title: I18n.t('People'),
      description: I18n.t('Allows user to view user SIS IDs.'),
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        'Allows user to view the user SIS ID column in the Quiz Item Analysis CSV file.'
      ),
    },
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        'To view the list of users in the course, Users - view list must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To add or remove users to a course via SIS, the appropriate Users permission must be enabled (e.g. Users - Teachers).'
      ),
    },
  ]
)
