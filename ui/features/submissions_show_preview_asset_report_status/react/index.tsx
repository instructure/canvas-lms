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

import {ExistingAttachedAssetProcessor} from '@canvas/lti/model/AssetProcessor'
import {LtiAssetReportWithAsset} from '@canvas/lti-asset-processor/model/AssetReport'
import ready from '@instructure/ready'
import {createRoot} from 'react-dom/client'
import OnlineUploadAssetReportStatusLink from './OnlineUploadAssetReportStatusLink'

declare const ENV: {
  ASSET_REPORTS?: LtiAssetReportWithAsset[]
  ASSET_PROCESSORS?: ExistingAttachedAssetProcessor[]
  ASSIGNMENT_NAME?: string
}

ready(() => {
  const reports = ENV['ASSET_REPORTS']
  const assetProcessors = ENV['ASSET_PROCESSORS'] || []
  const assignmentName = ENV['ASSIGNMENT_NAME'] || ''

  // if lti_asset_processor FF is off, reports will be undefined
  if (!reports || !assetProcessors || !assetProcessors.length) {
    return
  }

  const containers = document.querySelectorAll<HTMLDivElement>('.asset_report_status_container')
  containers.forEach(container => {
    const attachmentId = container.dataset['attachmentId']
    if (!attachmentId) {
      console.warn('No attachmentId found in asset report status container')
      return
    }
    createRoot(container).render(
      <OnlineUploadAssetReportStatusLink
        assignmentName={assignmentName}
        assetProcessors={assetProcessors}
        assetReports={reports}
        attachmentId={attachmentId}
      />,
    )
  })
})
