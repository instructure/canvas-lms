/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {generateActionTemplates} from '../generateActionTemplates'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('permissions_templates_lti_registrations')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('LTI Registrations - Manage'),
      description: I18n.t(
        'Allows users to view, add, modify, and delete LTI 1.3 tool registrations on the new Apps page.',
      ),
    },
  ],
  [],
  [],
  [],
)
