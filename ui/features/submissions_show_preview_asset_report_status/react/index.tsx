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

import ready from '@instructure/ready'
import {
  useShouldShowLtiAssetReportsForStudent,
  useLtiAssetProcessorsAndReportsForStudent,
} from '@canvas/lti-asset-processor/react/hooks/useLtiAssetProcessorsAndReportsForStudent'

import {sendOpenAssetReportModalMessage} from '@canvas/lti-asset-processor/react/StudentAssetReportModalWrapper'
import LtiAssetReportStatus from '@canvas/lti-asset-processor/shared-with-sg/replicated/components/LtiAssetReportStatus'
import {z} from 'zod'
import {useScope as createI18nScope} from '@canvas/i18n'
import {renderAPComponent} from '@canvas/lti-asset-processor/react/util/renderToElements'

const I18n = createI18nScope('lti_asset_reports_for_student')

/**
 * This code, which renders Asset Report statuses, is used inside an iframe in
 * case of online_upload in old student submission view, but we want the Report
 * modal to open in the main window. To do this, we post a message to the main
 * window which will then open the modal. The message is handled by the
 * StudentLtiAssetReportModalWrapper component.
 * (ui/features/submissions/react/StudentLtiAssetReportModalWrapper.tsx)
 */

const ZAttachmentAssetReportStatusProps = z.object({
  submissionId: z.string(),
  submissionType: z.string(),
  attachmentId: z.string(),
})
export default function AttachmentAssetReportStatus(
  props: z.infer<typeof ZAttachmentAssetReportStatusProps>,
) {
  const data = useLtiAssetProcessorsAndReportsForStudent(props)
  if (!data) return null
  const openModal = () => sendOpenAssetReportModalMessage(data)
  return <LtiAssetReportStatus reports={data.reports} openModal={openModal} />
}

const ZDocumentProcessorsHeaderProps = z.object({
  submissionId: z.string(),
  submissionType: z.string(),
})
function DocumentProcessorsHeader(submission: z.infer<typeof ZDocumentProcessorsHeaderProps>) {
  const shouldShow = useShouldShowLtiAssetReportsForStudent(submission)
  return shouldShow ? <>{I18n.t('Document Processors')}</> : null
}

ready(() => {
  const nRendered = renderAPComponent(
    '.asset-report-status-container',
    AttachmentAssetReportStatus,
    ZAttachmentAssetReportStatusProps,
  )
  if (nRendered > 0) {
    renderAPComponent(
      '.asset-report-status-header',
      DocumentProcessorsHeader,
      ZDocumentProcessorsHeaderProps,
    )
  }
})
