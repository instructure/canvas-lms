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

import {useScope as createI18nScope} from '@canvas/i18n'
import {generateActionTemplates} from '../generateActionTemplates'

const I18n = createI18nScope('permissions_templates_74')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Quizzes'),
      description: I18n.t('Allows user to view student quiz logs.'),
    },
  ],
  [
    {
      title: I18n.t('Grades'),
      description: I18n.t('Grades - edit must also be enabled.'),
    },
    {
      title: I18n.t('Quizzes'),
      description: I18n.t(
        'The Quiz Log Auditing feature option must be enabled in Course Settings.',
      ),
    },
  ],
  [],
  [],
)
