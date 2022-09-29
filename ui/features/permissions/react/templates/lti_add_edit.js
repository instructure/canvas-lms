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

const I18n = useI18nScope('permissions_templates_11')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t('Allows user to manually add and delete an app in Account Settings.'),
    },
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to manually add and delete an app in Course Settings.'),
    },
    {
      title: I18n.t('External Apps'),
      description: I18n.t('Allows user to edit configurations for manually added external apps.'),
    },
  ],
  [
    {
      title: I18n.t('External Apps (Account, Course Settings)'),
      description: I18n.t(
        'If this permission is disabled, users can still install approved apps through the Canvas App Center (if enabled for your institution).'
      ),
    },
    {
      description: I18n.t(
        'Additionally, if this permission is disabled, users cannot delete manually added external apps.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t('Allows user to manually add and delete an app in Course Settings.'),
    },
    {
      title: I18n.t('External Apps (Course Settings)'),
      description: I18n.t('Allows user to edit configurations for manually added external apps.'),
    },
  ],
  [
    {
      title: I18n.t('External Apps (Course Settings)'),
      description: I18n.t(
        'If this permission is disabled, users can still install approved apps through the Canvas App Center (if enabled for your institution).'
      ),
    },
    {
      description: I18n.t(
        'Additionally, if this permission is disabled, users cannot delete manually added external apps.'
      ),
    },
  ]
)
