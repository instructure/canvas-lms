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

import {useLtiAssetProcessors, useLtiAssetReports} from '../../dependenciesShims'
import {
  extractStudentUserIdOrAnonymousId,
  type StudentUserIdOrAnonymousId,
} from '../queries/getLtiAssetReports'
import type {LtiAssetProcessor} from '../types/LtiAssetProcessors'
import {
  type AssetReportCompatibleSubmissionType,
  ensureCompatibleSubmissionType,
  type LtiAssetReport,
} from '../types/LtiAssetReports'

export type UseLtiAssetProcessorsAndReportsForSpeedgraderParams = {
  assignmentId: string
  submissionType: string
} & StudentUserIdOrAnonymousId

type UseLtiAssetProcessorsAndReportsResult = {
  assetProcessors: LtiAssetProcessor[]
  assetReports: LtiAssetReport[]
  compatibleSubmissionType: AssetReportCompatibleSubmissionType
  hasNextPage: boolean
}

export function useLtiAssetProcessorsAndReportsForSpeedgrader(
  params: UseLtiAssetProcessorsAndReportsForSpeedgraderParams,
): UseLtiAssetProcessorsAndReportsResult | undefined {
  const {assignmentId, submissionType} = params

  const processorsQueryResult = useLtiAssetProcessors({assignmentId})
  const nullableAssetProcessors =
    processorsQueryResult.data?.assignment?.ltiAssetProcessorsConnection?.nodes
  const assetProcessors = nullableAssetProcessors?.filter(ap => ap !== null) || []

  const hasZeroProcessors = processorsQueryResult.data && !assetProcessors.length
  const compatibleSubmissionType = ensureCompatibleSubmissionType(submissionType)
  const canSkipReportsQuery = hasZeroProcessors || !compatibleSubmissionType

  const reportsQueryResult = useLtiAssetReports(
    {assignmentId, ...extractStudentUserIdOrAnonymousId(params)},
    {cancel: canSkipReportsQuery},
  )

  const nullableAssetReports = reportsQueryResult.data?.submission?.ltiAssetReportsConnection?.nodes
  const hasNextPage =
    reportsQueryResult.data?.submission?.ltiAssetReportsConnection?.pageInfo?.hasNextPage ?? false

  // In the future we may wish to distinguish between 1) no processors and 2)
  // asset reports still loading, but for now, we just show nothing for both cases.
  if (!assetProcessors.length || !compatibleSubmissionType || !nullableAssetReports) {
    return undefined
  }

  const assetReports = nullableAssetReports.filter(ar => ar !== null) || []

  return {
    assetProcessors,
    assetReports,
    compatibleSubmissionType,
    hasNextPage,
  }
}
