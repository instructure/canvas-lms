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

const I18n = useI18nScope('permissions_templates_26')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'Allows user to manage the Visibility options in Course Settings or when creating a new course.'
      ),
    },
  ],
  [],
  [
    {
      title: I18n.t('Course Settings'),
      description: I18n.t(
        'Allows user to manage the Visibility options in Course Settings or when creating a new course.'
      ),
    },
  ],
  []
)
