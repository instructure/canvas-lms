/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

const I18n = useI18nScope('permissions_templates_28')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('LTI - add'),
      description: I18n.t('Allows user to manually add an app in Account Settings.'),
    },
    {
      description: I18n.t(
        'Allows user to add external app icons to the Rich Content Editor toolbar.'
      ),
    },
    {
      description: I18n.t('Allows user to manually add an app in Course Settings.'),
    },
    {
      title: I18n.t('LTI - delete'),
      description: I18n.t('Allows user to manually delete an app in Account Settings.'),
    },
    {
      description: I18n.t('Allows user to manually delete an app in Course Settings.'),
    },
    {
      title: I18n.t('LTI - edit'),
      description: I18n.t('Allows user to edit configurations for manually added external apps.'),
    },
  ],
  [
    {
      title: I18n.t('External Apps'),
      description: I18n.t(
        'If LTI - add is disabled, users can still install approved apps through the Canvas App Center (if enabled for your institution). However, if LTI - delete is not enabled, they cannot delete manually added external apps.'
      ),
    },
  ],
  [
    {
      title: I18n.t('LTI - add'),
      description: I18n.t('Allows user to manually add an app in Course Settings.'),
    },
    {
      title: I18n.t('LTI - delete'),
      description: I18n.t('Allows user to manually delete an app in Course Settings.'),
    },
    {
      title: I18n.t('LTI - edit'),
      description: I18n.t('Allows user to edit configurations for manually added external apps.'),
    },
  ],
  [
    {
      title: I18n.t('External Apps'),
      description: I18n.t(
        'If LTI - add is disabled, users can still install approved apps through the Canvas App Center (if enabled for your institution). However, if LTI - delete is not enabled, they cannot delete manually added external apps.'
      ),
    },
  ]
)
