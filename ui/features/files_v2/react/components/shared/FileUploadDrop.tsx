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
import {FileDrop} from '@instructure/ui-file-drop'
import {Flex} from '@instructure/ui-flex'
import {Billboard} from '@instructure/ui-billboard'
import {RocketSVG} from '@instructure/canvas-media'
import {Text} from '@instructure/ui-text'
import {BBFolderWrapper} from '../../../utils/fileFolderWrappers'
import {type FileOptionsResults} from '../FilesHeader/UploadButton/FileOptions'
import {FileUploadModals} from './FileUploadModals'
import {queueOptionsCollectionUploads, startUpload} from '../../../utils/uploadUtils'

const I18n = createI18nScope('upload_drop_zone')

type FileUploadDropProps = {
  contextId: string | number
  contextType: string
  currentFolder: BBFolderWrapper
  onClose?: () => void
  fileDropHeight: string | number
  handleFileDropRef?: (el: HTMLInputElement | null) => void
}

export const FileUploadDrop = ({
  contextId,
  contextType,
  currentFolder,
  onClose,
  fileDropHeight,
  handleFileDropRef,
}: FileUploadDropProps) => {
  const [fileOptions, setFileOptions] = useState<FileOptionsResults | null>(null)

  const handleDrop = (
    accepted: ArrayLike<DataTransferItem | globalThis.File>,
    _rejected: ArrayLike<DataTransferItem | globalThis.File>,
    e: React.DragEvent<Element>,
  ) => {
    e?.preventDefault()
    e?.stopPropagation()
    const newFileOptions = startUpload(currentFolder, contextId, contextType, onClose, accepted)
    setFileOptions(newFileOptions)
  }

  const onModalResolved = (fileOptions: FileOptionsResults) => {
    queueOptionsCollectionUploads(contextId, contextType, fileOptions, onClose)
    setFileOptions(fileOptions)
  }

  const onModalClose = (fileOptions: FileOptionsResults) => {
    setFileOptions(fileOptions)
    onClose?.()
  }

  return (
    <>
      <FileDrop
        data-testid="file-upload-drop"
        height={fileDropHeight}
        shouldAllowMultiple={true}
        // Called when dropping files or when clicking,
        // after the file dialog window exits successfully
        onDrop={handleDrop}
        inputRef={handleFileDropRef}
        renderLabel={
          <Flex direction="column" height="100%" alignItems="center" justifyItems="center">
            <Billboard
              size="small"
              hero={<RocketSVG width="3em" height="3em" />}
              as="div"
              headingAs="span"
              headingLevel="h2"
              heading={I18n.t('Drop files here to upload')}
              message={<Text color="brand">{I18n.t('or choose files')}</Text>}
            />
          </Flex>
        }
      />
      <FileUploadModals
        fileOptions={fileOptions}
        onResolved={onModalResolved}
        onClose={onModalClose}
      />
    </>
  )
}
