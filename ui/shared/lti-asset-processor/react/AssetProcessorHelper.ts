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

import {LtiAssetReportWithAsset} from '@canvas/lti-asset-processor/model/AssetReport'

// TODO should be removed after INTEROP-9588
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
