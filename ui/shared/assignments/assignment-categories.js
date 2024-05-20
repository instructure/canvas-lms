/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import {find} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('assignment_categories')

const OTHER = {
  label: I18n.t('Other'),
  id: 'other',
  submissionTypes: [''],
}

const Categories = {
  list: [
    {
      label: I18n.t('Assignments'),
      id: 'assignment',
      contentTypeClass: 'assignment',
      submissionTypes: [
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
      label: I18n.t('Quizzes'),
      id: 'quiz',
      contentTypeClass: 'quiz',
      submissionTypes: ['online_quiz'],
    },
    {
      label: I18n.t('Discussions'),
      id: 'discussion',
      contentTypeClass: 'discussion_topic',
      submissionTypes: ['discussion_topic'],
    },
    {
      label: I18n.t('Wiki'),
      id: 'document',
      contentTypeClass: 'wiki_page',
      submissionTypes: ['wiki_page'],
    },
    OTHER,
  ],
}

Categories.getCategory = assg => {
  const category = find(Categories.list, cat => {
    return (
      assg.submission_types.length &&
      find(assg.submission_types, sub => cat.submissionTypes.indexOf(sub) !== -1)
    )
  })
  return category || OTHER
}

export default Categories
