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
  // Allows us to ignore results if the last attempt number is not
  // the one we are viewing. For students, the server only returns
  // reports for the last attempt.
  ifLastAttemptIsNumber?: number
}

type SubmissionIdAndTypeAndAttachment = AssetReportsForStudentParams & {
  attachmentId?: string | undefined
}

export function useShouldShowLtiAssetReportsForStudent(submission: AssetReportsForStudentParams) {
  return !!useLtiAssetProcessorsAndReportsForStudentQuery(submission)
}

/**
 * Fetches all reports for a student submission, and optionally filters by attachment ID.
 * Because this uses Tanstack query, it can be called multiple times with the same submissionId
 * and different attachmentId and will only make one query.
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
  const attempt = submission?.attempt

  if (assignmentName && assetProcessors.length > 0 && reports) {
    return {assignmentName, assetProcessors, reports, attempt}
  }

  return undefined
}

function useLtiAssetProcessorsAndReportsForStudentQuery({
  submissionId,
  submissionType,
  ifLastAttemptIsNumber,
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

  if (ifLastAttemptIsNumber !== undefined && data?.attempt !== ifLastAttemptIsNumber) {
    // Student view only returns reports for latest attempt.
    // If we are viewing another attempt, we shouldn't show any reports
    return undefined
  }

  return data
}
