/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

const I18n = useI18nScope('permissions_templates_79')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Admin Analytics'),
      description: I18n.t(
        'Allows user to view, drill into, and export Admin Analytics data in the Overview, Course, and Student tabs.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(
        'The Admin Analytics feature must be enabled in Account Settings to view Admin Analytics dashboards.'
      ),
    },
  ]
)
