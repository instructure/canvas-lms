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

import {useScope as createI18nScope} from '@canvas/i18n'
import {RubricRating} from '../../types/rubric'

const I18n = createI18nScope('rubrics-form')

export const DEFAULT_RUBRIC_RATINGS: RubricRating[] = [
  {
    id: '1',
    points: 4,
    description: I18n.t('Exceeds'),
    longDescription: '',
  },
  {
    id: '2',
    points: 3,
    description: I18n.t('Mastery'),
    longDescription: '',
  },
  {
    id: '3',
    points: 2,
    description: I18n.t('Near'),
    longDescription: '',
  },
  {
    id: '4',
    points: 1,
    description: I18n.t('Below'),
    longDescription: '',
  },
  {
    id: '5',
    points: 0,
    description: I18n.t('No Evidence'),
    longDescription: '',
  },
]
