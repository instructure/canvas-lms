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

const I18n = useI18nScope('permissions_templates_6')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'Allows user to generate a pairing code on behalf of a student to share with an observer.'
      ),
    },
  ],
  [
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'To generate a pairing code from a student`s User Settings page, the User - act as permission must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To generate a pairing code from a student`s User Details page, the Users - allow administrative actions in courses permission must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'Pairing codes are only supported when self registration is enabled for the account.'
      ),
    },
    {
      description: I18n.t(
        'QR codes are not the same as pairing codes and are only used to help users log into their own accounts via the Canvas mobile apps. To disable QR code logins for all users in your account, please contact your Customer Success Manager.'
      ),
    },
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        'Allows user to generate a pairing code on behalf of a student to share with an observer.'
      ),
    },
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        'To generate a pairing code from a student`s User Details page, the Users - allow administrative actions in courses permission must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'Pairing codes are only supported when self registration is enabled for the course.'
      ),
    },
    {
      description: I18n.t(
        'QR codes are not the same as pairing codes and are only used to help users log into their own accounts via the Canvas mobile apps.'
      ),
    },
  ]
)
