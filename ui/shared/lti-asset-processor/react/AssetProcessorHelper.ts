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

import {ExistingAttachedAssetProcessor} from '@canvas/lti/model/AssetProcessor'
import {LtiAssetReportWithAsset} from '@canvas/lti-asset-processor/model/AssetReport'

declare const ENV: {
  ASSET_REPORTS?: LtiAssetReportWithAsset[]
  ASSET_PROCESSORS?: ExistingAttachedAssetProcessor[]
  ASSIGNMENT_NAME?: string
}

export function filterReports(
  reports: LtiAssetReportWithAsset[] | undefined,
  attachmentId?: string,
) {
  if (!reports || !attachmentId) {
    return []
  }
  return reports.filter(report => report.asset && report.asset.attachment_id === attachmentId) ?? []
}

export function filterReportsByAttempt(
  reports: LtiAssetReportWithAsset[] | undefined,
  attemptId?: string,
) {
  if (!reports || !attemptId) {
    return []
  }
  return (
    reports.filter(
      report => report.asset && report.asset.submission_attempt?.toString() === attemptId,
    ) ?? []
  )
}

export function shouldRenderAssetProcessorData(): boolean {
  // See also assignmentHasDocumentProcessorsDataToShow, equivalent for new
  // Grades Page
  const assignmentHasProcessors = !!ENV.ASSET_PROCESSORS?.length
  const assignmentHasMaybeEmptyAssetReports = !!ENV.ASSET_REPORTS
  return assignmentHasProcessors && assignmentHasMaybeEmptyAssetReports
}

export function clearAssetProcessorReports() {
  ENV.ASSET_REPORTS = undefined
}
