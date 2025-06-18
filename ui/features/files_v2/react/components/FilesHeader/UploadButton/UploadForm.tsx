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

import React from 'react'
import {Modal} from '@instructure/ui-modal'
import {useScope as createI18nScope} from '@canvas/i18n'
import '@canvas/rails-flash-notifications'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {BBFolderWrapper} from '../../../../utils/fileFolderWrappers'
import {FileUploadDrop} from '../../shared/FileUploadDrop'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('upload_drop_zone')

type UploadFormProps = {
  contextId: string | number
  contextType: string
  currentFolder: BBFolderWrapper
  open: boolean
  onClose: () => void
}

export const UploadForm = ({
  contextId,
  contextType,
  currentFolder,
  open,
  onClose,
}: UploadFormProps) => {
  return (
    <Modal open={open} onDismiss={onClose} size="large" label={I18n.t('Upload file')}>
      <Modal.Header>
        <CloseButton
          data-testid="upload-close-button"
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Upload file')}</Heading>
      </Modal.Header>
      <Modal.Body as={Flex}>
        <Flex.Item width="100%" padding="medium" height="50vh">
          <FileUploadDrop
            contextId={contextId}
            contextType={contextType}
            currentFolder={currentFolder}
            onClose={onClose}
            fileDropHeight={'100%'}
          />
        </Flex.Item>
      </Modal.Body>
      <Modal.Footer>
        <Button data-testid="upload-cancel-button" onClick={onClose}>
          {I18n.t('Cancel')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
