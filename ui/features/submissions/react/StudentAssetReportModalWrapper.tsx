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
import {ASSET_REPORT_MODAL_EVENT} from '../../submissions_show_preview_asset_report_status/react/OnlineUploadAssetReportStatusLink'
import {LtiAssetReportWithAsset} from '@canvas/lti-asset-processor/model/AssetReport'
import StudentAssetReportModal from '@canvas/lti-asset-processor/react/StudentAssetReportModal'
import {useEffect, useState} from 'react'

/**
 * The AssetReportStatusLink which, when clicked, triggers opening the
 * StudentAssetReportModal, is in an iframe so cannot launch the modal
 * directly in the main content window. This wrapper is rendered in the
 * main content window and provides a postMessage listener to listen to
 * the message sent by AssetReportStatusLink to open the modal.
 */
export default function StudentAssetReportModalWrapper() {
  const [open, setOpen] = useState(false)
  const [reports, setReports] = useState<LtiAssetReportWithAsset[]>([])
  const [assetProcessors, setAssetProcessors] = useState<ExistingAttachedAssetProcessor[]>([])
  const [assignmentName, setAssignmentName] = useState<string>('')
  const [submissionType, setSubmissionType] = useState<'online_text_entry' | 'online_upload'>()

  useEffect(() => {
    function handleOpenAssetReportModal(event: MessageEvent) {
      if (event.origin !== window.location.origin) {
        console.warn('Rejected message from different origin:', event.origin)
        return
      }

      if (event.data.type === ASSET_REPORT_MODAL_EVENT) {
        setReports(event.data.assetReports)
        setAssetProcessors(event.data.assetProcessors)
        setAssignmentName(event.data.assignmentName)
        setSubmissionType(event.data.submissionType)
        setOpen(true)
      }
    }
    window.addEventListener('message', handleOpenAssetReportModal)
    return () => {
      window.removeEventListener('message', handleOpenAssetReportModal)
    }
  }, [])

  function onClose() {
    setOpen(false)
  }

  if (reports.length === 0 || assetProcessors.length === 0) {
    return null
  }

  if (!assignmentName || !submissionType) {
    console.error('Missing required data for StudentAssetReportModal')
    return null
  }

  return (
    <StudentAssetReportModal
      assetProcessors={assetProcessors}
      assignmentName={assignmentName}
      onClose={onClose}
      open={open}
      reports={reports}
      submissionType={submissionType}
    />
  )
}
