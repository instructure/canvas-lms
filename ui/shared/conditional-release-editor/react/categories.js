/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

const I18n = useI18nScope('conditional_release')

export const ALL_ID = 'all'
export const OTHER_ID = 'other'

const Categories = [
  {
    label: () => I18n.t('All Items'),
    id: ALL_ID,
  },
  {
    label: () => I18n.t('Assignments'),
    id: 'assignment',
    submission_types: [
      'online_upload',
      'online_text_entry',
      'online_url',
      'on_paper',
      'external_tool',
      'not_graded',
      'media_recording',
      'none',
    ],
  },
  {
    label: () => I18n.t('Quizzes'),
    id: 'quiz',
    submission_types: ['online_quiz'],
  },
  {
    label: () => I18n.t('Discussions'),
    id: 'discussion',
    submission_types: ['discussion_topic'],
  },
  {
    label: () => I18n.t('Pages'),
    id: 'page',
    submission_types: ['wiki_page'],
  },
  {
    label: () => I18n.t('Other'),
    id: OTHER_ID,
    submission_types: [''],
  },
]

export default Categories
