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
import {
  LtiAssetReportWithAsset,
  SpeedGraderLtiAssetReports,
} from '@canvas/lti-asset-processor/model/AssetReport'
import groupBy from 'lodash/groupBy'
import {
  LtiAssetReports,
  LtiAssetReportsProps,
} from '@canvas/lti-asset-processor/react/LtiAssetReports'
import {ExistingAttachedAssetProcessor} from '@canvas/lti/model/AssetProcessor'
import {Flex, FlexItem} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import TruncateWithTooltip from '../../lti-apps/components/common/TruncateWithTooltip'
import AssetReportStatus from './AssetReportStatus'
import {View} from '@instructure/ui-view'

interface Props {
  assetProcessors: ExistingAttachedAssetProcessor[]
  assignmentName: string
  onClose?: () => void
  open?: boolean
  reports: LtiAssetReportWithAsset[]
  submissionType: 'online_text_entry' | 'online_upload'
}

const I18n = createI18nScope('submissions_show_preview_asset_report_status')
const t = I18n.t.bind(I18n)

export default function StudentAssetReportModal({
  assetProcessors,
  assignmentName,
  onClose,
  open,
  reports,
  submissionType,
}: Props) {
  const {sgReports, attachments, mainTitle} = mapData(reports, submissionType)
  const assetProcessorsWithReports = assetProcessors.filter(assetProcessor =>
    reports.some(report => report.asset_processor_id === assetProcessor.id),
  )

  return (
    <Modal
      label={t('Document Processors for %{assignmentName}', {assignmentName})}
      open={open}
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
          <FlexItem>
            <AssetReportStatus reports={reports} />
          </FlexItem>
        </Flex>
        <LtiAssetReports
          assetProcessors={assetProcessorsWithReports}
          attempt={sgReports.by_attempt ? Object.keys(sgReports.by_attempt)[0] : ''}
          reports={sgReports}
          studentId={undefined}
          versionedAttachments={attachments}
          submissionType={submissionType}
        />
      </Modal.Body>
    </Modal>
  )
}

function mapData(
  reports: LtiAssetReportWithAsset[],
  submissionType: 'online_text_entry' | 'online_upload',
): {
  sgReports: SpeedGraderLtiAssetReports
  attachments: LtiAssetReportsProps['versionedAttachments']
  mainTitle: string
} {
  if (submissionType === 'online_text_entry') {
    const attempt = reports?.[0]?.asset?.submission_attempt?.toString() ?? ''
    return {
      attachments: [],
      mainTitle: I18n.t('Text submitted to Canvas'),
      sgReports: {
        by_attempt: {
          [attempt]: groupBy(reports, rep => rep.asset_processor_id),
        },
      },
    }
  } else if (submissionType === 'online_upload') {
    const attachmentNames: Record<string, string> = {}
    const by_attachment: SpeedGraderLtiAssetReports['by_attachment'] = {}
    for (const report of reports ?? []) {
      const {
        asset_processor_id,
        asset: {attachment_id},
      } = report
      if (attachment_id) {
        by_attachment[attachment_id] ??= {}
        by_attachment[attachment_id][asset_processor_id] ??= []
        by_attachment[attachment_id][asset_processor_id].push(report)
        attachmentNames[attachment_id] = report.asset.attachment_name ?? ''
      }
    }
    const attachmentIds = Object.keys(by_attachment)
    if (attachmentIds.length === 1) {
      return {
        attachments: [{attachment: {id: attachmentIds[0]}}],
        mainTitle: attachmentNames[attachmentIds[0]] ?? '',
        sgReports: {
          by_attachment,
        },
      }
    } else {
      return {
        attachments: attachmentIds.map(id => ({
          attachment: {id, display_name: attachmentNames[id]},
        })),
        mainTitle: '',
        sgReports: {
          by_attachment,
        },
      }
    }
  } else {
    throw new Error(
      `Unsupported submission type: ${submissionType}. Expected 'online_text_entry' or 'online_upload'.`,
    )
  }
}
