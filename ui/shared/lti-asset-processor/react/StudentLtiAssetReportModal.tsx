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

import {useScope as createI18nScope} from '@canvas/i18n'
import {AssetReportModal} from '../shared-with-sg/replicated/components/AssetReportModal'
import {AssetReportCompatibleSubmissionType} from '../shared-with-sg/replicated/types/LtiAssetReports'
import {LtiAssetProcessor} from '../shared-with-sg/replicated/types/LtiAssetProcessors'
import {LtiAssetReportForStudent} from '../model/LtiAssetReport'

export interface StudentLtiAssetReportModalProps {
  assetProcessors: LtiAssetProcessor[]
  assignmentName: string
  onClose?: () => void
  reports: LtiAssetReportForStudent[]
  submissionType: AssetReportCompatibleSubmissionType
}

const I18n = createI18nScope('lti_asset_reports_for_student')
const t = I18n.t.bind(I18n)

function attachmentsFromReports(
  reports: LtiAssetReportForStudent[],
): {_id: string; displayName: string}[] {
  const attachmentMap = new Map<string, string>()
  for (const report of reports) {
    const attachmentId = report.asset.attachmentId
    if (attachmentId && !attachmentMap.has(attachmentId)) {
      attachmentMap.set(attachmentId, report.asset.attachmentName ?? '')
    }
  }
  return Array.from(attachmentMap.entries()).map(([id, displayName]) => ({_id: id, displayName}))
}

export default function StudentLtiAssetReportModal({
  assetProcessors,
  assignmentName,
  onClose,
  reports,
  submissionType,
}: StudentLtiAssetReportModalProps) {
  const {attachments, mainTitle, showDocumentDisplayName} = mapData(reports, submissionType)

  // This is only needed for online_text_entry, so can be empty for other types
  const attempt =
    reports.find(r => r.asset.submissionAttempt)?.asset.submissionAttempt?.toString() ?? ''

  const modalTitle = t('Document Processors for %{assignmentName}', {assignmentName})

  return (
    <AssetReportModal
      assetProcessors={assetProcessors}
      modalTitle={modalTitle}
      attachments={attachments}
      attempt={attempt}
      mainTitle={mainTitle}
      onClose={onClose}
      reports={reports}
      showDocumentDisplayName={showDocumentDisplayName}
      studentIdForResubmission={undefined}
      submissionType={submissionType}
    />
  )
}

/**
 * Map data based on submission type, and figures out whether to show
 * document display name (headings handled by LtiAssetReports component) or a
 * main title.
 */
function mapData(
  reports: LtiAssetReportForStudent[],
  submissionType: AssetReportCompatibleSubmissionType,
): {
  attachments?: {_id: string; displayName: string}[]
  mainTitle?: string
  showDocumentDisplayName: boolean
} {
  switch (submissionType) {
    case 'online_text_entry':
      return {
        mainTitle: I18n.t('Text submitted to Canvas'),
        showDocumentDisplayName: false,
      }
    case 'online_upload': {
      const attachments = attachmentsFromReports(reports)
      if (attachments.length == 1) {
        return {
          attachments,
          mainTitle: attachments[0].displayName,
          showDocumentDisplayName: false,
        }
      }
      return {
        attachments,
        showDocumentDisplayName: true,
      }
    }
    case 'discussion_topic': {
      const attachments = attachmentsFromReports(reports)
      if (reports.length === 1) {
        return {
          attachments,
          mainTitle: I18n.t('All comments'),
          showDocumentDisplayName: false,
        }
      }
      return {
        attachments,
        showDocumentDisplayName: true,
      }
    }
    default:
      return submissionType satisfies never
  }
}
