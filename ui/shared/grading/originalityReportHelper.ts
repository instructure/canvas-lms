/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import type {SubmissionOriginalityData, OriginalityData} from './grading.d'

export function originalityReportSubmissionKey(submission: {
  id?: string
  submitted_at?: null | string | Date
  submittedAt?: null | string | Date
}): string {
  try {
    const submitted_at = submission.submitted_at || submission.submittedAt
    if (!submitted_at) {
      return ''
    }
    const submittedAtDate = new Date(submitted_at)
    const submittedAtString = `${submittedAtDate.toISOString().split('.')[0]}Z`
    return submittedAtString ? `submission_${submission.id}_${submittedAtString}` : ''
  } catch (_error) {
    return ''
  }
}

export function isOriginalityReportVisible(
  originalityReportVisibility: string | null,
  dueAt: string | null,
  gradingStatus: string | null
): boolean {
  switch (originalityReportVisibility) {
    case 'immediate':
      return true
    case 'never':
      return false
    case 'after_grading':
      if (gradingStatus && ['graded', 'excused'].includes(gradingStatus)) {
        return true
      }
      return false
    case 'after_due_date':
      if (!dueAt || new Date(dueAt) < new Date()) {
        return true
      }
      return false
    default:
      return true
  }
}

export function getOriginalityData(
  submission: {
    _id: string
    submissionType: string
    originalityData: {
      [key: string]: SubmissionOriginalityData
    }
    attachments: any
    submittedAt?: null | string | Date
    submitted_at?: null | string | Date
  },
  index: number
): false | OriginalityData {
  let data: null | SubmissionOriginalityData = null
  if (submission.submissionType === 'online_text_entry') {
    data =
      submission.originalityData[
        originalityReportSubmissionKey({...submission, id: submission._id})
      ] || submission.originalityData[`submission_${submission._id}`]
  } else if (submission.submissionType === 'online_upload') {
    data = submission.originalityData[`attachment_${submission.attachments[index]?._id}`]
  }

  if (
    !data?.state ||
    !data?.report_url ||
    (!data?.similarity_score && data?.similarity_score !== 0) ||
    data?.state === 'error'
  ) {
    return false
  } else {
    return {
      reportUrl: data.report_url,
      score: data.similarity_score,
      status: data.status,
      state: data.state,
    }
  }
}
