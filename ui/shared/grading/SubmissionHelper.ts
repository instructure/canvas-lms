// @ts-nocheck
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

import {camelizeProperties, underscoreProperties} from '@canvas/convert-case'
import {originalityReportSubmissionKey} from './originalityReportHelper'
import type {
  SubmissionOriginalityData,
  SimilarityEntry,
  CamelizedSubmissionWithOriginalityReport,
} from './grading.d'

export function isGraded(submission) {
  // TODO: remove when we no longer camelize data in Gradebook
  const workflow_state = submission.workflow_state || submission.workflowState
  return (submission.score != null && workflow_state === 'graded') || submission.excused
}

export function isPostable(submission) {
  // TODO: remove when we no longer camelize data in Gradebook
  const posted_at = submission.posted_at || submission.postedAt
  const has_postable_comments = submission.has_postable_comments || submission.hasPostableComments
  return !posted_at && (isGraded(submission) || !!has_postable_comments)
}

export function isHideable(submission) {
  // TODO: remove when we no longer camelize data in Gradebook
  const posted_at = submission.posted_at || submission.postedAt
  return !!posted_at
}
// This function returns an object containing plagiarism/originality-related
// data for the given submission, or null if the submission has no relevant
// info. The returned object contains the following keys:
// - type: either 'turnitin', 'vericite' or 'originality_report'
// - entries: an array of individual reports, containing:
//   - id: an identifier for the individual report (e.g., 'submission_1', 'attachment_41')
//   - data: the contents of the report, typically containing 'status' and
//       'similarity_score' fields among other things
//
// The array of entries is sorted in the following order:
//   - "error" reports (reports that had a problem running)
//   - "pending" reports (reports still being processed)
//   - scored reports, with higher scores (indicating more likely plagiarism) first
export function extractSimilarityInfo(submission) {
  const sub = camelizeProperties(submission) as CamelizedSubmissionWithOriginalityReport
  let plagiarismData
  let type: 'vericite' | 'turnitin' | 'originality_report' | null = null

  if (sub.vericiteData?.provider === 'vericite') {
    type = 'vericite'
    plagiarismData = sub.vericiteData
  } else if (sub.turnitinData != null) {
    type = 'turnitin'
    plagiarismData = sub.turnitinData
  }

  if (sub.hasOriginalityReport) {
    type = 'originality_report'
  }
  if (plagiarismData == null || type == null) {
    return null
  }

  const entries = getSimilarityEntries(sub, plagiarismData)
  if (entries.length === 0) {
    return null
  }

  return {type, entries}
}

function getSimilarityEntries(submission, plagiarismData) {
  const entries: SimilarityEntry[] = []

  if (submission.submissionType === 'online_upload' && submission.attachments != null) {
    // A submission with attachments may have a plagiarism report for each
    // attachment. Also, an attachment's data might also be found in an
    // "attachment" object nested inside the actual attachment object we got.
    submission.attachments.forEach(attachment => {
      const id = attachment.attachment?.id || attachment.id
      const idKey = `attachment_${id}`
      const attachmentData = plagiarismData[idKey]
      if (attachmentData != null) {
        entries.push({id: idKey, data: attachmentData})
      }
    })
  } else if (submission.submissionType === 'online_text_entry') {
    // A text entry submission will only have one active report, but the report
    // may be keyed by the submission version (or not). Try to use the data for
    // the current version (as returned by originalityReportSubmissionKey), but
    // if that's not available, check the "base" submission instead.
    const originalityReportKey = originalityReportSubmissionKey(underscoreProperties(submission))
    const dataForKey = plagiarismData[originalityReportKey]

    const baseSubmissionId = `submission_${submission.id}`
    const dataForBaseSubmission = plagiarismData[baseSubmissionId]

    if (dataForKey != null) {
      entries.push({id: originalityReportKey, data: dataForKey})
    } else if (dataForBaseSubmission != null) {
      entries.push({id: baseSubmissionId, data: dataForBaseSubmission})
    }
  }

  entries.sort(similarityEntryComparator)
  return entries
}

function similarityEntryComparator(a: SimilarityEntry, b: SimilarityEntry): number {
  const orderedStatuses = ['error', 'pending', 'scored', 'none']

  // We only display a single plagiarism report in New Gradebook. If a
  // submission has multiple reports, show the one with the "worst" status
  // (e.g., a report that encountered an error should be prioritized over one
  // that was successfully scored).
  const {status: aStatus, similarity_score: aScore} = a.data
  const {status: bStatus, similarity_score: bScore} = b.data

  // If both entries have been scored, show the one with the higher similarity
  // score (i.e., the one more likely to have been plagiarized).
  if (aStatus === 'scored' && aScore != null && bStatus === 'scored' && bScore != null) {
    return bScore - aScore
  }

  // Otherwise, just compare by status.
  return orderedStatuses.indexOf(aStatus || 'none') - orderedStatuses.indexOf(bStatus || 'none')
}

export function similarityIcon(similarityData: SubmissionOriginalityData): string {
  const {status, similarity_score} = similarityData

  let iconClass
  if (status === 'error') {
    iconClass = 'icon-warning'
  } else if (status === 'pending') {
    iconClass = 'icon-clock'
  } else if (similarity_score > 60) {
    iconClass = 'icon-empty icon-Solid'
  } else if (similarity_score > 20) {
    iconClass = 'icon-oval-half icon-Solid'
  } else {
    iconClass = 'icon-certified icon-Solid'
  }

  // xsslint safeString.identifier iconClass
  return `<i class="${iconClass}"></i>`
}
