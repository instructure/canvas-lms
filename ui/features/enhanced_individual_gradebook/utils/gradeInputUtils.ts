/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import type {AssignmentConnection, GradebookUserSubmissionDetails} from '../types'
import {ApiCallStatus} from '../types'
import DateHelper from '@canvas/datetime/dateHelper'
import {REPLY_TO_ENTRY, REPLY_TO_TOPIC} from '../react/components/GradingResults'
import {isInPastGradingPeriodAndNotAdmin} from './gradebookUtils'

const I18n = createI18nScope('enhanced_individual_gradebook')

export const passFailStatusOptions = [
  {
    label: I18n.t('Ungraded'),
    value: ' ',
  },
  {
    label: I18n.t('Complete'),
    value: 'complete',
  },
  {
    label: I18n.t('Incomplete'),
    value: 'incomplete',
  },
  {
    label: I18n.t('Excused'),
    value: 'EX',
  },
]

export function submitterPreviewText(submission: GradebookUserSubmissionDetails): string {
  if (!submission.submissionType) {
    return I18n.t('Has not submitted')
  }
  const formattedDate = DateHelper.formatDatetimeForDisplay(submission.submittedAt)
  if (submission.proxySubmitter) {
    return I18n.t('Submitted by %{proxy} on %{date}', {
      proxy: submission.proxySubmitter,
      date: formattedDate,
    })
  }
  return I18n.t('Submitted on %{date}', {date: formattedDate})
}

export function outOfText(
  assignment: AssignmentConnection,
  submission: GradebookUserSubmissionDetails,
  pointsBasedGradingScheme: boolean,
): string {
  const {gradingType, pointsPossible} = assignment

  if (submission.excused) {
    return I18n.t('Excused')
  } else if (gradingType === 'gpa_scale') {
    return ''
  } else if (gradingType === 'letter_grade' || gradingType === 'pass_fail') {
    if (pointsBasedGradingScheme) {
      return I18n.t('(%{score} out of %{points})', {
        points: I18n.n(pointsPossible, {precision: 2}),
        score: I18n.n(submission.enteredScore, {precision: 2}) ?? ' -',
      })
    } else {
      return I18n.t('(%{score} out of %{points})', {
        points: I18n.n(pointsPossible),
        score: submission.enteredScore ?? ' -',
      })
    }
  } else if (pointsPossible === null || pointsPossible === undefined) {
    return I18n.t('No points possible')
  } else {
    return I18n.t('(out of %{points})', {points: I18n.n(pointsPossible)})
  }
}

export function disableGrading(
  assignment: AssignmentConnection,
  submitScoreStatus?: ApiCallStatus,
): boolean {
  return (
    submitScoreStatus === ApiCallStatus.PENDING ||
    isInPastGradingPeriodAndNotAdmin(assignment) ||
    (assignment.moderatedGrading && !assignment.gradesPublished)
  )
}

export function assignmentHasCheckpoints(assignment: AssignmentConnection): boolean {
  return (assignment.checkpoints?.length ?? 0) > 0
}

export const getCorrectSubmission = (
  submission?: GradebookUserSubmissionDetails,
  subAssignmentTag?: string | null,
) => {
  if (subAssignmentTag === REPLY_TO_TOPIC || subAssignmentTag === REPLY_TO_ENTRY) {
    return submission?.subAssignmentSubmissions?.find(
      subSubmission => subSubmission.subAssignmentTag === subAssignmentTag,
    )
  }

  return submission
}
