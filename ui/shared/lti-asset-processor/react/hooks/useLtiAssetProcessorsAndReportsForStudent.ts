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

import {useQuery} from '@tanstack/react-query'
import {executeQueryAndValidate} from './graphqlQueryHooks'
import {useScope as createI18nScope} from '@canvas/i18n'
import {
  GetLtiAssetProcessorsAndReportsForStudentResult,
  LTI_ASSET_PROCESSORS_AND_REPORTS_FOR_STUDENT_QUERY,
  ZGetLtiAssetProcessorsAndReportsForStudentResult,
} from '../../queries/getLtiAssetProcessorsAndReportsForStudent'
import {ensureCompatibleSubmissionType} from '../../shared-with-sg/replicated/types/LtiAssetReports'

const I18n = createI18nScope('lti_asset_reports_for_student')

const allReportsDisabled = false

/**
 * Hooks that use Tanstack Query to fetch Asset Reports, and Asset Processors, for Student Submission pages
 */

// SubmissionType is used to pre-emptively skip submission types that could not support reports
export type AssetReportsForStudentParams = {
  submissionId: string
  submissionType: string
  attempt?: number
  // IDs of the current attempt's attachments, used to scope column visibility to the current attempt
  attachmentIds?: string[]
}

type SubmissionIdAndTypeAndAttachment = AssetReportsForStudentParams & {
  attachmentId?: string | undefined
}

export function useShouldShowLtiAssetReportsForStudent(submission: AssetReportsForStudentParams) {
  const data = useLtiAssetProcessorsAndReportsForStudentQuery(submission)
  if (!data) return false
  const {attachmentIds, attempt} = submission
  if (attachmentIds != null && attachmentIds.length > 0) {
    // For file uploads: show column only if this attempt's attachments have reports
    return data.reports.some(
      report =>
        report.asset?.attachmentId != null && attachmentIds.includes(report.asset.attachmentId),
    )
  }
  if (attempt != null) {
    // For text entry/discussion: show column only if this attempt has reports
    return data.reports.some(
      report =>
        report.asset?.submissionAttempt === attempt || report.asset?.discussionEntryVersion != null,
    )
  }
  // attempt unknown: hide column (matches useLtiAssetProcessorsAndReportsForStudent behavior)
  return false
}

/**
 * Fetches all reports for a student submission across all attempts, then filters
 * to the current attempt. Because this uses Tanstack query, it can be called
 * multiple times with the same submissionId and will only make one network request.
 *
 * When attachmentId is provided (file upload submissions), filters by that specific
 * attachment. Otherwise, filters by asset.submissionAttempt (text entry) and passes
 * discussion entry reports through as-is.
 */
export function useLtiAssetProcessorsAndReportsForStudent({
  attachmentId,
  ...submission
}: SubmissionIdAndTypeAndAttachment) {
  const data = useLtiAssetProcessorsAndReportsForStudentQuery(submission)
  const submissionType = ensureCompatibleSubmissionType(submission.submissionType)
  if (!data || !submissionType) {
    return undefined
  }
  const result = {...data, submissionType}
  if (attachmentId !== undefined) {
    result.reports = result.reports.filter(report => report.asset?.attachmentId === attachmentId)
  } else if (submission.attempt != null) {
    // For text entry submissions, filter to the current attempt using asset.submissionAttempt.
    // Discussion entry reports (asset.discussionEntryVersion set) are always passed through.
    result.reports = result.reports.filter(
      report =>
        report.asset?.submissionAttempt === submission.attempt ||
        report.asset?.discussionEntryVersion != null,
    )
  } else {
    // attempt unknown: hide all attempt-specific reports to avoid mixing attempts.
    console.warn(
      'useLtiAssetProcessorsAndReportsForStudent: attachmentId and attempt are undefined',
      result.reports,
    )
    result.reports = []
  }
  return result
}

const getLtiAssetProcessors = (submissionId: string) => {
  return executeQueryAndValidate<GetLtiAssetProcessorsAndReportsForStudentResult>(
    LTI_ASSET_PROCESSORS_AND_REPORTS_FOR_STUDENT_QUERY,
    {submissionId},
    I18n.t('Error loading Document Processors and Reports'),
    ZGetLtiAssetProcessorsAndReportsForStudentResult,
  )
}

function unpackGqlQueryResult(
  data: GetLtiAssetProcessorsAndReportsForStudentResult | null | undefined,
) {
  const submission = data?.submission
  const assignment = submission?.assignment
  const assignmentName = assignment?.name
  const assetProcessors =
    assignment?.ltiAssetProcessorsConnection?.nodes?.filter(p => p !== null) ?? []
  const reports = submission?.ltiAssetReportsConnection?.nodes?.filter(r => r !== null)
  const hasNextPage = submission?.ltiAssetReportsConnection?.pageInfo?.hasNextPage ?? false

  if (assignmentName && assetProcessors.length > 0 && reports) {
    return {assignmentName, assetProcessors, reports, hasNextPage}
  }

  return undefined
}

function useLtiAssetProcessorsAndReportsForStudentQuery({
  submissionId,
  submissionType,
}: AssetReportsForStudentParams) {
  const {data} = useQuery({
    queryKey: ['ltiAssetProcessorsAndReportsForStudent', submissionId],
    queryFn: () => getLtiAssetProcessors(submissionId),
    staleTime: 5 * 60 * 1000, // 5 minutes
    refetchOnMount: false, // multiple components on the same page call this
    enabled:
      !!ENV.FEATURES?.lti_asset_processor &&
      !allReportsDisabled &&
      !!ensureCompatibleSubmissionType(submissionType),
    select: unpackGqlQueryResult,
  })

  return data
}
