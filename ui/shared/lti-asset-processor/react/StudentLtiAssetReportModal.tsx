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
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {CloseButton} from '@instructure/ui-buttons'
import {Flex, FlexItem} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import TruncateWithTooltip from '../../lti-apps/components/common/TruncateWithTooltip'
import LtiAssetReportStatus from './LtiAssetReportStatus'
import {View} from '@instructure/ui-view'
import {LtiAssetProcessor, LtiAssetReportForStudent} from '../model/LtiAssetReport'
import {LtiAssetReports} from '../shared-with-sg/replicated/components/LtiAssetReports'
import {AssetReportCompatibleSubmissionType} from '../shared-with-sg/replicated/types/LtiAssetReports'

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
  const assetProcessorsWithReports = assetProcessors.filter(assetProcessor =>
    reports.some(report => report.processorId === assetProcessor._id),
  )
  const {attachments, mainTitle, showDocumentDisplayName} = mapData(reports, submissionType)

  // This is only needed for online_text_entry, so can be empty for other types
  const attempt =
    reports.find(r => r.asset.submissionAttempt)?.asset.submissionAttempt?.toString() ?? ''

  return (
    <Modal
      label={t('Document Processors for %{assignmentName}', {assignmentName})}
      open={true}
      onClose={onClose}
      onDismiss={onClose}
    >
      <Modal.Header>
        <Heading>{t('Document Processors for %{assignmentName}', {assignmentName})}</Heading>
        <CloseButton
          placement="end"
          offset="medium"
          onClick={onClose}
          screenReaderLabel={t('Close')}
          elementRef={el => {
            el?.setAttribute('data-pendo', 'asset-processors-student-view-modal-close')
          }}
        />
      </Modal.Header>
      <Modal.Body>
        <Flex justifyItems="space-between" alignItems="center" margin="0 0 medium 0" gap="medium">
          {mainTitle && (
            <FlexItem>
              <View maxWidth="30em" as="div">
                <Text size="descriptionPage" weight="weightImportant">
                  <TruncateWithTooltip
                    linesAllowed={1}
                    horizontalOffset={0}
                    backgroundColor="primary-inverse"
                  >
                    {mainTitle}
                  </TruncateWithTooltip>
                </Text>
              </View>
            </FlexItem>
          )}
          <FlexItem>
            <LtiAssetReportStatus reports={reports} />
          </FlexItem>
        </Flex>
        <LtiAssetReports
          assetProcessors={assetProcessorsWithReports}
          attempt={attempt}
          reports={reports}
          studentIdForResubmission={undefined}
          attachments={attachments}
          submissionType={submissionType}
          showDocumentDisplayName={showDocumentDisplayName}
        />
      </Modal.Body>
    </Modal>
  )
}

/**
 * Map data based on submission type, and figures out whether to show
 * document display name or a main title.
 */
function mapData(
  reports: LtiAssetReportForStudent[],
  submissionType: AssetReportCompatibleSubmissionType,
): {
  attachments: {_id: string; displayName: string}[]
  mainTitle: string | undefined
  showDocumentDisplayName: boolean
} {
  switch (submissionType) {
    case 'online_text_entry':
      return {
        attachments: [],
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
      } else {
        return {
          attachments,
          mainTitle: undefined,
          showDocumentDisplayName: true,
        }
      }
    }
    default:
      return submissionType satisfies never
  }
}
