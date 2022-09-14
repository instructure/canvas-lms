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
export function originalityReportSubmissionKey(submission) {
  try {
    let submittedAt = new Date(submission.submitted_at || submission.submittedAt)
    submittedAt = `${submittedAt.toISOString().split('.')[0]}Z`
    return (submittedAt && `submission_${submission.id}_${submittedAt}`) || ''
  } catch (_error) {
    return ''
  }
}

export function getOriginalityData(submission, index) {
  let data = null
  if (submission.submissionType === 'online_text_entry') {
    data =
      submission.originalityData[`submission_${originalityReportSubmissionKey(submission)}`] ||
      submission.originalityData[`submission_${submission._id}`]
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
      state: data.state
    }
  }
}
