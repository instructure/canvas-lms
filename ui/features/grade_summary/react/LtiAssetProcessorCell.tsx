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
  shouldShowAssetReportCell,
  ZLtiAssetProcessor,
  ZLtiAssetReportForStudent,
} from '@canvas/lti-asset-processor/model/LtiAssetReport'
import {ZodType} from 'zod'
import LtiAssetReportStatus from '@canvas/lti-asset-processor/shared-with-sg/replicated/components/LtiAssetReportStatus'
import StudentLtiAssetReportModal from '@canvas/lti-asset-processor/react/StudentLtiAssetReportModal'
import {ensureCompatibleSubmissionType} from '@canvas/lti-asset-processor/shared-with-sg/replicated/types/LtiAssetReports'

interface AssetProcessorCellProps {
  assetProcessors: LtiAssetProcessor[] | undefined
  assetReports: LtiAssetReportForStudent[] | undefined
  submissionType: string | undefined
  assignmentName: string
}

/**
 * Represents the LtiAssetReportStatus link with corresponding Modal showing the
 * full information, used in Student Grades page (both old and new).
 */
export default function LtiAssetProcessorCell({
  assetProcessors,
  assetReports,
  submissionType,
  assignmentName,
}: AssetProcessorCellProps) {
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

  // Submissions for checkpointed discussions will have null submissionType until they're
  // fully submitted. They can still have reports, so show those reports if they exist.
  const inferredSubmissionType = ensureCompatibleSubmissionType(
    submissionType ||
      (assetReports?.some(report => report.asset.discussionEntryVersion)
        ? 'discussion_topic'
        : undefined),
  )

  if (!inferredSubmissionType || !shouldShowAssetReportCell(assetProcessors, assetReports)) {
    return null
  }

  return (
    <>
      <LtiAssetReportStatus reports={validatedReports} openModal={() => setIsModalOpen(true)} />
      {isModalOpen && (
        <StudentLtiAssetReportModal
          assetProcessors={validatedProcessors}
          assignmentName={assignmentName}
          onClose={handleClose}
          reports={validatedReports}
          submissionType={inferredSubmissionType}
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
