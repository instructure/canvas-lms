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
import {LtiAssetReportWithAsset} from '@canvas/lti/model/AssetReport'
import groupBy from 'lodash/groupBy'
import {LtiAssetReports} from '../../../shared/lti/react/LtiAssetReports'
import {type LtiAssetReportsByProcessor} from '@canvas/lti/model/AssetReport'
import {ExistingAttachedAssetProcessor} from '@canvas/lti/model/AssetProcessor'
import {Flex, FlexItem} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import AssetReportStatus from '../../../shared/lti/react/AssetReportStatus'

interface Props {
  assetProcessors: ExistingAttachedAssetProcessor[]
  assignmentName: string
  onClose?: () => void
  open?: boolean
  reports: LtiAssetReportWithAsset[]
}

const I18n = createI18nScope('submissions_show_preview_asset_report_status')
const t = I18n.t.bind(I18n)

export default function StudentAssetReportModal({
  assetProcessors,
  assignmentName,
  onClose,
  open,
  reports,
}: Props) {
  const attachmentId = reports?.[0]?.asset.attachment_id
  const attachmentName = reports?.[0]?.asset.attachment_name

  if (!attachmentId) {
    return null
  }
  const attachments = [
    {
      attachment: {
        id: attachmentId,
      },
    },
  ]
  const reportsByAttachment: Record<string, LtiAssetReportsByProcessor> = {
    [attachmentId]: groupBy(reports, rep => rep.asset_processor_id),
  }

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
        <Flex justifyItems="space-between" alignItems="center" margin="0 0 medium 0">
          <FlexItem>
            <Text size="descriptionPage" weight="weightImportant">
              {attachmentName}
            </Text>
          </FlexItem>
          <FlexItem>
            <AssetReportStatus reports={reports} />
          </FlexItem>
        </Flex>
        <LtiAssetReports
          assetProcessors={assetProcessors}
          attempt={null}
          reportsByAttachment={reportsByAttachment}
          studentId={undefined}
          versionedAttachments={attachments}
        />
      </Modal.Body>
    </Modal>
  )
}
