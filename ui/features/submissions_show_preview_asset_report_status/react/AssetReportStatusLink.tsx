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

import {useMemo} from 'react'
import {ExistingAttachedAssetProcessor} from '@canvas/lti/model/AssetProcessor'
import {ViewOwnProps} from '@instructure/ui-view'
import AssetReportStatus from '../../../shared/lti/react/AssetReportStatus'
import {LtiAssetReportWithAsset} from '@canvas/lti/model/AssetReport'

export const ASSET_REPORT_MODAL_EVENT = 'openAssetReportModal'

interface Props {
  attachmentId?: string
  assetProcessors: ExistingAttachedAssetProcessor[]
  assetReports: LtiAssetReportWithAsset[]
  assignmentName: string
}

export default function AssetReportStatusLink({
  assetProcessors,
  assetReports,
  attachmentId,
  assignmentName,
}: Props) {
  /*
   * This file list is rendered into an iframe, but we want the Report modal
   * to open in the main window. To do this, we post a message to the main window
   * which will then open the modal.
   * The message is handled by the StudentAssetReportModalWrapper component.
   * (ui/features/submissions/react/StudentAssetReportModalWrapper.tsx)
   */
  const reports = useMemo(
    () => assetReports.filter(report => report.asset.attachment_id === attachmentId),
    [assetReports, attachmentId],
  )

  function openModal(event: React.MouseEvent<ViewOwnProps, MouseEvent>) {
    event.preventDefault()
    window.parent.postMessage({
      type: ASSET_REPORT_MODAL_EVENT,
      assetReports: reports,
      assetProcessors,
      assignmentName,
    })
  }

  return <AssetReportStatus reports={reports} openModal={openModal} />
}
