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

import {useInfiniteQuery} from '@tanstack/react-query'
import {useEffect} from 'react'
import {
  COURSE_ASSIGNMENTS_ASSET_REPORTS_QUERY,
  ZGetCourseAssignmentsAssetReportsResult,
  type GetCourseAssignmentsAssetReportsResult,
} from '../../queries/getCourseAssignmentsAssetReports'
import {useScope as createI18nScope} from '@canvas/i18n'
import {
  LtiAssetProcessor,
  LtiAssetReport,
  shouldShowAssetReportCell,
} from '@canvas/lti-asset-processor/model/LtiAssetReport'
import {
  AssetReportCompatibleSubmissionType,
  ensureCompatibleSubmissionType,
} from '@canvas/lti-asset-processor/shared-with-sg/replicated/types/LtiAssetReports'
import {z} from 'zod'
import {executeQueryAndValidate} from './graphqlQueryHooks'

const I18n = createI18nScope('lti_asset_processor')

export const ZUseCourseAssignmentsAssetReportsParams = z.object({
  courseId: z.string(),
  gradingPeriodId: z.string().nullable().optional(),
  studentId: z.string(),
})

export type UseCourseAssignmentsAssetReportsParams = z.infer<
  typeof ZUseCourseAssignmentsAssetReportsParams
>

export type AssignmentReportData = {
  assetProcessors: LtiAssetProcessor[]
  assetReports: LtiAssetReport[]
  submissionType: AssetReportCompatibleSubmissionType
  assignmentName: string
}

function indexByAssignmentId(data: {
  pages: GetCourseAssignmentsAssetReportsResult[]
}): Map<string, AssignmentReportData | null> {
  const byAssignmentId = new Map<string, AssignmentReportData | null>()
  for (const page of data.pages) {
    const assignments = page.legacyNode?.assignmentsConnection?.nodes || []
    for (const assignment of assignments) {
      if (!assignment) continue
      const submission = assignment.submissionsConnection?.nodes?.[0]
      const assetProcessors = assignment.ltiAssetProcessorsConnection?.nodes?.filter(
        p => p !== null && p !== undefined,
      )
      const assetReports = submission?.ltiAssetReportsConnection?.nodes?.filter(
        r => r !== null && r !== undefined,
      )
      const submissionType = ensureCompatibleSubmissionType(submission?.submissionType)
      const assignmentName = assignment.name

      if (
        assetProcessors &&
        assetReports &&
        assignmentName &&
        submissionType &&
        shouldShowAssetReportCell(assetProcessors, assetReports)
      ) {
        byAssignmentId.set(assignment._id, {
          assetProcessors,
          assetReports,
          submissionType,
          assignmentName,
        })
      }
    }
  }
  return byAssignmentId
}

export function useCourseAssignmentsAssetReports({
  courseId,
  gradingPeriodId,
  studentId,
}: UseCourseAssignmentsAssetReportsParams) {
  const query = useInfiniteQuery({
    queryKey: ['course_assignments_asset_reports', courseId, gradingPeriodId, studentId],
    queryFn: ({pageParam}: {pageParam?: string}) =>
      executeQueryAndValidate(
        COURSE_ASSIGNMENTS_ASSET_REPORTS_QUERY,
        {courseID: courseId, gradingPeriodID: gradingPeriodId, studentId, after: pageParam},
        I18n.t('Error loading Document Processors and Reports'),
        ZGetCourseAssignmentsAssetReportsResult,
      ),
    initialPageParam: undefined,
    getNextPageParam: (lastPage: GetCourseAssignmentsAssetReportsResult) => {
      const pageInfo = lastPage.legacyNode?.assignmentsConnection?.pageInfo
      return pageInfo?.hasNextPage ? pageInfo.endCursor : undefined
    },
    staleTime: 10 * 60 * 1000, // 10 minutes
    refetchOnMount: false,
    refetchOnWindowFocus: false,
    enabled: !!courseId && !!studentId && !!ENV.FEATURES?.lti_asset_processor,
    select: indexByAssignmentId,
  })

  // Automatically fetch next page when ready
  useEffect(() => {
    if (query.hasNextPage && !query.isFetchingNextPage && !query.isError) {
      query.fetchNextPage()
    }
  }, [query])

  return query
}
