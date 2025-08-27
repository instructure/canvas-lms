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

import React, {useState} from 'react'
import AssetReportStatus from '@canvas/lti-asset-processor/react/AssetReportStatus'
import StudentAssetReportModal from '@canvas/lti-asset-processor/react/StudentAssetReportModal'
import {LtiAssetReportWithAsset} from '@canvas/lti-asset-processor/model/AssetReport'
import {ExistingAttachedAssetProcessor} from '@canvas/lti/model/AssetProcessor'

interface AssetProcessorCellProps {
  assetProcessors: ExistingAttachedAssetProcessor[]
  assetReports: LtiAssetReportWithAsset[]
  submissionType: 'online_upload' | 'online_text_entry'
  assignmentName: string
}

export default function AssetProcessorCell({
  assetProcessors,
  assetReports,
  submissionType,
  assignmentName,
}: AssetProcessorCellProps) {
  const [isModalOpen, setIsModalOpen] = useState(false)

  function handleClose() {
    setIsModalOpen(false)
  }

  return (
    <>
      <AssetReportStatus reports={assetReports} openModal={() => setIsModalOpen(true)} />
      {isModalOpen && (
        <StudentAssetReportModal
          assetProcessors={assetProcessors}
          assignmentName={assignmentName}
          open={isModalOpen}
          onClose={handleClose}
          reports={assetReports}
          submissionType={submissionType}
        />
      )}
    </>
  )
}
