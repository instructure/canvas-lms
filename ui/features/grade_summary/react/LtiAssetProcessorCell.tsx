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
import {
  LtiAssetProcessor,
  LtiAssetReportForStudent,
  ZLtiAssetProcessor,
  ZLtiAssetReportForStudent,
} from '@canvas/lti-asset-processor/model/LtiAssetReport'
import {ZodType} from 'zod'
import LtiAssetReportStatus from '@canvas/lti-asset-processor/react/LtiAssetReportStatus'
import StudentLtiAssetReportModal from '@canvas/lti-asset-processor/react/StudentLtiAssetReportModal'

interface AssetProcessorCellProps {
  assetProcessors: LtiAssetProcessor[] | undefined
  assetReports: LtiAssetReportForStudent[] | undefined
  submissionType: 'online_upload' | 'online_text_entry'
  assignmentName: string
}

/**
 * Represents the AssetReportStatus link with corresponding Modal showing the
 * full information, used in Student Grades page (both old and new).
 */
export default function LtiAssetProcessorCell({
  assetProcessors,
  assetReports,
  submissionType,
  assignmentName,
}: AssetProcessorCellProps) {
  console.log('LtiAssetProcessorCell render', {assetProcessors, assetReports})
  const [isModalOpen, setIsModalOpen] = useState(false)

  function handleClose() {
    setIsModalOpen(false)
  }

  const validatedProcessors: LtiAssetProcessor[] = useZodMemo(
    assetProcessors || [],
    ZLtiAssetProcessor.array(),
    [],
  )
  const validatedReports: LtiAssetReportForStudent[] = useZodMemo(
    assetReports || [],
    ZLtiAssetReportForStudent.array(),
    [],
  )

  if (!validatedProcessors.length || !Array.isArray(assetReports)) {
    // Note that empty array means to still show, but show "No Reports"
    // see AssetProcessorReportHelper#raw_asset_reports
    return null
  }

  return (
    <>
      <LtiAssetReportStatus reports={validatedReports} openModal={() => setIsModalOpen(true)} />
      {isModalOpen && (
        <StudentLtiAssetReportModal
          assetProcessors={validatedProcessors}
          assignmentName={assignmentName}
          open={isModalOpen}
          onClose={handleClose}
          reports={validatedReports}
          submissionType={submissionType}
        />
      )}
    </>
  )
}

function useZodMemo<T, U>(data: T, schema: ZodType<T>, fallback: U): T | U {
  return React.useMemo(() => {
    const result = schema.safeParse(data)
    if (!result.success) {
      console.error('useZodMemo: invalid data', {data, error: result.error})
      return fallback
    }
    return result.data
  }, [data, schema, fallback])
}

export function shouldShowLtiAssetProcessorCellColumn(
  assetProcessors: LtiAssetProcessor[] | undefined,
  assetReports: LtiAssetReportForStudent[] | undefined,
): boolean {
  const hasProcessors = Array.isArray(assetProcessors) && assetProcessors.length > 0
  const hasReports = Array.isArray(assetReports) && assetReports.length > 0
  return hasProcessors && hasReports
}
