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

import StudentLtiAssetReportModal, {
  StudentLtiAssetReportModalProps,
} from '@canvas/lti-asset-processor/react/StudentLtiAssetReportModal'
import {useEffect, useState} from 'react'

export type AssetReportModalEventData = Omit<StudentLtiAssetReportModalProps, 'onClose'>

export const ASSET_REPORT_MODAL_EVENT = 'openAssetReportModal'

export function sendOpenAssetReportModalMessage(data: AssetReportModalEventData) {
  window.parent.postMessage({type: ASSET_REPORT_MODAL_EVENT, ...data}, window.location.origin)
}

/**
 * The AttachmentAssetReportStatus which, when clicked, triggers opening the
 * StudentLtiAssetReportModal, is in an iframe, so it cannot launch the modal
 * directly in the main content window. This wrapper is rendered in the main
 * content window and provides a postMessage listener to listen to the message
 * sent by AttachmentAssetReportStatus to open the modal.
 */
export default function StudentAssetReportModalWrapper() {
  const [data, setData] = useState<AssetReportModalEventData | undefined>(undefined)

  useEffect(() => {
    function handleMessage(event: MessageEvent) {
      if (event.origin !== window.location.origin) {
        console.warn('Rejected message from different origin:', event.origin)
        return
      }

      const {type, ...data} = event.data || {}
      if (type === ASSET_REPORT_MODAL_EVENT) {
        setData(data)
      }
    }
    window.addEventListener('message', handleMessage)
    return () => window.removeEventListener('message', handleMessage)
  }, [])

  return data && <StudentLtiAssetReportModal {...data} onClose={() => setData(undefined)} />
}
