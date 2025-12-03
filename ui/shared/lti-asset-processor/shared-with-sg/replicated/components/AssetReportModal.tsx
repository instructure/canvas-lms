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

import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex, FlexItem} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
// biome-ignore lint/style/noRestrictedImports: the modal in SG's instui-bindings is incompatible with all three of Canvas's modals and doesn't permit pendo tracking
import {Modal} from '@instructure/ui-modal'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import LtiAssetReportStatus from './LtiAssetReportStatus'
import {LtiAssetReports, type LtiAssetReportsProps} from './LtiAssetReports'
import TruncateWithTooltip from './TruncateWithTooltip'
import {ResubmitDiscussionNoticesButton} from './ResubmitDiscussionNoticesButton'

export type AssetReportModalProps = LtiAssetReportsProps & {
  modalTitle: string
  mainTitle?: string
  onClose?: () => void
  assignmentId?: string
}

const I18n = createI18nScope('lti_asset_processor')

export function AssetReportModal({
  assetProcessors,
  modalTitle,
  attachments,
  attempt,
  mainTitle,
  onClose,
  reports,
  showDocumentDisplayName,
  studentIdForResubmission,
  submissionType,
  assignmentId,
}: AssetReportModalProps): JSX.Element {
  const assetProcessorsWithReports = assetProcessors.filter(assetProcessor =>
    reports.some(report => report.processorId === assetProcessor._id),
  )

  return (
    <Modal label={modalTitle} open={true} onClose={onClose} onDismiss={onClose} size="medium">
      <Modal.Header>
        <Heading>{modalTitle}</Heading>
        <CloseButton
          placement="end"
          offset="medium"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
          elementRef={el => {
            el?.setAttribute('data-pendo', 'asset-reports-modal-close')
          }}
        />
      </Modal.Header>
      <Modal.Body overflow="scroll">
        <View height="25rem" as="div">
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
            studentIdForResubmission={studentIdForResubmission}
            attachments={attachments}
            submissionType={submissionType}
            showDocumentDisplayName={showDocumentDisplayName}
          />
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Flex gap="small">
          {submissionType === 'discussion_topic' && studentIdForResubmission && assignmentId && (
            <ResubmitDiscussionNoticesButton
              size="medium"
              assignmentId={assignmentId}
              studentId={studentIdForResubmission}
            />
          )}
          <Flex.Item>
            <Button data-pendo="asset-reports-modal-close-footer-button" onClick={onClose}>
              {I18n.t('Close')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}
