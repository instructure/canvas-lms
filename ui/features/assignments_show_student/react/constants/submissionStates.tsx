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

import {Text} from '@instructure/ui-text'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Submission} from '../../assignments_show_student'

const I18n = createI18nScope('assignments_2_student_header')

export const SUBMISSION_STATES = {
  IN_PROGRESS: 'inProgress',
  SUBMITTED: 'submitted',
  COMPLETED: 'completed',
}

export const WORKFLOW_STATES = {
  [SUBMISSION_STATES.IN_PROGRESS]: {
    value: 1,
    title: <Text>{I18n.t('In Progress')}</Text>,
    subtitle: I18n.t('NEXT UP: Submit Assignment'),
  },
  [SUBMISSION_STATES.SUBMITTED]: {
    value: 2,
    title: (submission: Submission) => (
      <FriendlyDatetime
        dateTime={submission.submittedAt}
        format={I18n.t('#date.formats.full')}
        prefix={I18n.t('Submitted on')}
        showTime={true}
      />
    ),
    subtitle: I18n.t('NEXT UP: Review Feedback'),
  },
  [SUBMISSION_STATES.COMPLETED]: {
    value: 3,
    title: <Text>{I18n.t('Review Feedback')}</Text>,
    subtitle: (submission: Submission) => {
      if (submission.attempt === 0) return null
      if (submission.submittedAt == null) return I18n.t('This assignment is complete!')

      return (
        <FriendlyDatetime
          dateTime={submission.submittedAt}
          format={I18n.t('#date.formats.full')}
          prefix={I18n.t('SUBMITTED: ')}
          showTime={true}
        />
      )
    },
  },
}
