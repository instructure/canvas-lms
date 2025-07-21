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
import {filterReports} from '@canvas/lti-asset-processor/react/AssetProcessorHelper'
import {useMemo} from 'react'
import AssetReportStatus from '@canvas/lti-asset-processor/react/AssetReportStatus'

export const ASSET_REPORT_MODAL_EVENT = 'openAssetReportModal'

interface Props {
  attachmentId: string
  assetProcessors: ExistingAttachedAssetProcessor[]
  assetReports: LtiAssetReportWithAsset[]
  assignmentName: string
}

/*
 * This component is used inside an iframe in case of online_upload in old student submission view,
 * but we want the Report modal to open in the main window.
 * To do this, we post a message to the main window which will then open the modal.
 * The message is handled by the StudentAssetReportModalWrapper component.
 * (ui/features/submissions/react/StudentAssetReportModalWrapper.tsx)
 */
export default function OnlineUploadAssetReportStatusLink({
  assetProcessors,
  assetReports,
  attachmentId,
  assignmentName,
}: Props) {
  const reports = useMemo(
    () => filterReports(assetReports, attachmentId),
    [assetReports, attachmentId],
  )

  return (
    <AssetReportStatus
      reports={reports}
      openModal={() =>
        window.parent.postMessage({
          type: ASSET_REPORT_MODAL_EVENT,
          assetReports: reports,
          assetProcessors,
          assignmentName,
          submissionType: 'online_upload',
        })
      }
    />
  )
}
