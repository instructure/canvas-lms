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

/**
 * STOP!
 *
 * This file is retained only for old code; it will be removed after
 * the Asset Processors refactor for Grades Page is complete
 * (INTEROP-9587). Do not use this file in new code, use
 * ./LtiAssetProcessorCell.ts instead.
 *
 * TODO: remove this file after INTEROP-9588 is done
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

/**
 * Represents the AssetReportStatus link with corresponding Modal showing the
 * full information, used in Student Grades page (both old and new).
 */
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
