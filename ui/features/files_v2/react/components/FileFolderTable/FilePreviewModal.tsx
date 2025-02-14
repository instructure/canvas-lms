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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import FilePreviewTray from './FilePreviewTray'
import {DrawerLayout} from '@instructure/ui-drawer-layout'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {TruncateText} from '@instructure/ui-truncate-text'
import {IconButton, Button} from '@instructure/ui-buttons'
import {
  IconArrowEndLine,
  IconArrowStartLine,
  IconImageSolid,
  IconInfoSolid,
  IconDownloadSolid,
  IconPrinterSolid,
  IconXSolid,
} from '@instructure/ui-icons'
import {type File} from '../../../interfaces/File'
import NoFilePreviewAvailable from "./NoFilePreviewAvailable";
import FilePreviewIframe from "./FilePreviewIframe";

const I18n = createI18nScope('files_v2')

interface FilePreviewModalProps {
  isOpen: boolean
  onClose: () => void
  item: File
}

const previewableTypes = ['image','pdf','html','doc','text']

const renderFilePreview = (item: File) => {
  if (item.preview_url && previewableTypes.includes(item.mime_class)) {
    return (<FilePreviewIframe item={item}/>)
  } else {
    return (<NoFilePreviewAvailable item={item}/>)
  }
}

const FilePreviewModal = ({isOpen, onClose, item}: FilePreviewModalProps) => {
  const [isTrayOpen, setIsTrayOpen] = useState(false)
  const name = item.display_name

  const handleOverlayTrayChange = (isTrayOpen: boolean) => {
    setIsTrayOpen(isTrayOpen)
  }

  return (
    <Modal
      open={isOpen}
      onDismiss={onClose}
      size={'fullscreen'}
      label={name}
      shouldCloseOnDocumentClick={false}
      variant="inverse"
      overflow="fit"
      defaultFocusElement={() => document.getElementById('download-button')}
    >
      <Modal.Header>
        <Flex>
          <Flex.Item shouldGrow shouldShrink>
            <Flex alignItems="center">
              <Flex.Item margin="0 medium 0 0">
                <IconImageSolid size="x-small" />
              </Flex.Item>
              <Flex.Item shouldGrow shouldShrink>
                <Heading level="h2">
                  <TruncateText>{name}</TruncateText>
                </Heading>
              </Flex.Item>
            </Flex>
          </Flex.Item>
          <Flex.Item>
            <IconButton
              color="primary-inverse"
              withBackground={false}
              withBorder={false}
              renderIcon={IconInfoSolid}
              screenReaderLabel={I18n.t('Open file info panel')}
              margin="0 x-small 0 0"
              id="file-info-button"
              onClick={() => handleOverlayTrayChange(true)}
            />
            <IconButton
              color="primary-inverse"
              withBackground={false}
              withBorder={false}
              renderIcon={IconPrinterSolid}
              screenReaderLabel={I18n.t('Print')}
              margin="0 x-small 0 0"
              onClick={() => window.print()}
              id="print-button"
            />
            <IconButton
              color="primary-inverse"
              withBackground={false}
              withBorder={false}
              renderIcon={IconDownloadSolid}
              screenReaderLabel={I18n.t('Download')}
              margin="0 x-small 0 0"
              id="download-icon-button"
              href={item.url}
            />
            <IconButton
              color="primary-inverse"
              withBackground={false}
              withBorder={false}
              renderIcon={IconXSolid}
              screenReaderLabel={I18n.t('Close')}
              onClick={onClose}
              id="close-button"
              data-testid="close-button"
            />
          </Flex.Item>
        </Flex>
      </Modal.Header>
      <Modal.Body padding="none">
        <DrawerLayout onOverlayTrayChange={handleOverlayTrayChange}>
          <DrawerLayout.Content label={I18n.t('File Preview')}>
            {renderFilePreview(item)}
          </DrawerLayout.Content>
          <DrawerLayout.Tray
            open={isTrayOpen}
            onClose={() => setIsTrayOpen(false)}
            placement="end"
            label={I18n.t('File Information')}
          >
            <FilePreviewTray onDismiss={() => setIsTrayOpen(false)} item={item} />
          </DrawerLayout.Tray>
        </DrawerLayout>
      </Modal.Body>
      <Modal.Footer>
        <Flex justifyItems="space-between" width="100%">
          <Flex.Item>
            <Button onClick={() => {}} withBackground={false} color="primary-inverse">
              <Flex gap="x-small">
                <Flex.Item>
                  <IconArrowStartLine />
                </Flex.Item>
                <Flex.Item>{I18n.t('Previous')}</Flex.Item>
              </Flex>
            </Button>
            <Button onClick={() => {}} withBackground={false} color="primary-inverse">
              <Flex gap="x-small">
                <Flex.Item>{I18n.t('Next')}</Flex.Item>
                <Flex.Item>
                  <IconArrowEndLine />
                </Flex.Item>
              </Flex>
            </Button>
          </Flex.Item>
          <Flex.Item>
            <Button onClick={onClose} withBackground={false} color="primary-inverse">
              {I18n.t('Close')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

export default FilePreviewModal
