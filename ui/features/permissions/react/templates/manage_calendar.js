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

const I18n = useI18nScope('permissions_templates_18')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Calendar'),
      description: I18n.t('Allows user to add, edit, and delete events in the course calendar.'),
    },
    {
      title: I18n.t('Scheduler'),
      description: I18n.t(
        'Allows user to create and manage appointments on the calendar using Scheduler.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Calendar'),
      description: I18n.t(
        'Regardless of whether this permission is enabled or disabled, users will still be able to manage events in their personal calendar.'
      ),
    },
    {
      title: I18n.t('Scheduler'),
      description: I18n.t('Scheduler must be enabled for your account.'),
    },
  ],
  [
    {
      title: I18n.t('Calendar'),
      description: I18n.t('Allows user to add, edit, and delete events in the course calendar.'),
    },
    {
      title: I18n.t('Scheduler'),
      description: I18n.t(
        'Allows user to create and manage appointments on the calendar using Scheduler.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Calendar'),
      description: I18n.t(
        'Regardless of whether this permission is enabled or disabled, users will still be able to manage events in their personal calendar.'
      ),
    },
    {
      title: I18n.t('Scheduler'),
      description: I18n.t('Scheduler must be enabled by your Canvas admin.'),
    },
  ]
)
