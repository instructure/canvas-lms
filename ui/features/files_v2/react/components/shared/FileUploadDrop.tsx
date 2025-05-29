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

import React, {useEffect, useCallback, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {FileDrop} from '@instructure/ui-file-drop'
import {Flex} from '@instructure/ui-flex'
import {Billboard} from '@instructure/ui-billboard'
import {RocketSVG} from '@instructure/canvas-media'
import {Text} from '@instructure/ui-text'
import FileOptionsCollection from '@canvas/files/react/modules/FileOptionsCollection'
import {BBFolderWrapper} from '../../../utils/fileFolderWrappers'
import {type FileOptionsResults} from '../FilesHeader/UploadButton/FileOptions'
import ZipFileOptionsForm from '../FilesHeader/UploadButton/ZipFileOptionsForm'
import FileRenameForm from '../FilesHeader/UploadButton/FileRenameForm'
import {createPortal} from 'react-dom'

const I18n = createI18nScope('upload_drop_zone')

type FileUploadDropProps = {
  contextId: string | number
  contextType: string
  currentFolder: BBFolderWrapper
  onClose?: () => void
  fileDropHeight: string | number
  handleFileDropRef?: (el: HTMLInputElement | null) => void
}

export const queueOptionsCollectionUploads = (
  contextId: string | number,
  contextType: string,
  fileOptions?: FileOptionsResults | null,
  onClose?: () => void,
) => {
  if (!fileOptions) return
  if (
    fileOptions.zipOptions.length === 0 &&
    fileOptions.nameCollisions.length === 0 &&
    FileOptionsCollection.hasNewOptions()
  ) {
    if (fileOptions.resolvedNames.length > 0) {
      FileOptionsCollection.queueUploads(contextId, contextType)
    }
    if (onClose) onClose()
  }
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

  useEffect(() => {
    FileOptionsCollection.setFolder(currentFolder)
    FileOptionsCollection.setUploadOptions({
      alwaysRename: false,
      alwaysUploadZips: false,
      errorOnDuplicate: true,
    })
  }, [currentFolder])

  useEffect(() => {
    queueOptionsCollectionUploads(contextId, contextType, fileOptions, onClose)
    setFileOptions(fileOptions)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [fileOptions])

  const handleDrop = (
    accepted: ArrayLike<DataTransferItem | globalThis.File>,
    _rejected: ArrayLike<DataTransferItem | globalThis.File>,
    e: React.DragEvent<Element>,
  ) => {
    e?.preventDefault()
    e?.stopPropagation()
    FileOptionsCollection.setFolder(currentFolder)
    FileOptionsCollection.setOptionsFromFiles(accepted, true)
    setFileOptions(FileOptionsCollection.getState())
  }

  const onZipOptionsResolved = useCallback(
    (fileNameOptions: any) => {
      FileOptionsCollection.onZipOptionsResolved(fileNameOptions)
      setFileOptions(FileOptionsCollection.getState())
    },
    [setFileOptions],
  )

  const onNameConflictResolved = useCallback(
    (fileNameOptions: any) => {
      FileOptionsCollection.onNameConflictResolved(fileNameOptions)
      setFileOptions(FileOptionsCollection.getState())
    },
    [setFileOptions],
  )

  const onCloseResolveModals = useCallback(() => {
    // user dismissed a zip or name conflict modal
    FileOptionsCollection.resetState()
    setFileOptions(FileOptionsCollection.getState())
    if (onClose) onClose()
  }, [onClose])

  const renderModal = useCallback(() => {
    if (!fileOptions) return null

    const zipOptions = fileOptions.zipOptions
    const nameCollisions = fileOptions.nameCollisions

    if (zipOptions.length)
      return createPortal(
        <ZipFileOptionsForm
          open={!!zipOptions.length}
          onClose={onCloseResolveModals}
          fileOptions={zipOptions[0]}
          onZipOptionsResolved={onZipOptionsResolved}
        />,
        document.body,
      )
    else if (nameCollisions.length)
      return createPortal(
        <FileRenameForm
          open={!!nameCollisions.length}
          onClose={onCloseResolveModals}
          fileOptions={nameCollisions[0]}
          onNameConflictResolved={onNameConflictResolved}
        />,
        document.body,
      )
    else return null
  }, [fileOptions, onCloseResolveModals, onZipOptionsResolved, onNameConflictResolved])

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
      {renderModal()}
    </>
  )
}
