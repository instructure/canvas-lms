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

import React, {useCallback, useContext, useEffect, useRef, useState} from 'react'
import {Button, type ButtonProps} from '@instructure/ui-buttons'
import UploadForm from '@canvas/files/react/components/UploadForm'
import {FileManagementContext} from '../../Contexts'
import UploadQueue from '@canvas/files/react/modules/UploadQueue'
import FileRenameForm from './FileRenameForm'
import ZipFileOptionsForm from './ZipFileOptionsForm'
import {pluralizeContextTypeString} from '../../../../utils/fileFolderUtils'
import {type FileOptionsResults} from './FileOptions'

type UploadButtonProps = ButtonProps

const UploadButton = ({disabled, children, ...buttonProps}: UploadButtonProps) => {
  const {contextId, contextType, currentFolder} = useContext(FileManagementContext)
  const [fileOptions, setFileOptions] = useState<FileOptionsResults | null>(null)
  const formRef = useRef<UploadForm>(null)

  const [hasPendingUploads, setHasPendingUploads] = useState<boolean>(
    !!UploadQueue.pendingUploads(),
  )

  const handleQueueChange = useCallback(
    () => setHasPendingUploads(!!UploadQueue.pendingUploads()),
    [],
  )

  const handleUploadClick = useCallback(() => formRef.current?.addFiles(), [])

  const renderModal = useCallback(() => {
    if (!fileOptions || !formRef.current) return null

    const zipOptions = fileOptions.zipOptions
    const nameCollisions = fileOptions.nameCollisions

    if (zipOptions.length)
      return (
        <ZipFileOptionsForm
          open={!!zipOptions.length}
          onClose={formRef.current?.onClose}
          fileOptions={zipOptions[0]}
          onZipOptionsResolved={formRef.current?.onZipOptionsResolved}
        />
      )
    else if (nameCollisions.length)
      return (
        <>
          <FileRenameForm
            open={!!nameCollisions.length}
            onClose={formRef.current?.onClose}
            fileOptions={nameCollisions[0]}
            onNameConflictResolved={formRef.current?.onNameConflictResolved}
          />
        </>
      )
    else return null
  }, [fileOptions])

  useEffect(() => {
    UploadQueue.addChangeListener(handleQueueChange)
    return () => UploadQueue.removeChangeListener(handleQueueChange)
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <>
      {/* contextType and contextId are null on All My Files page */}
      {contextType && (
        <UploadForm
          allowSkip={true}
          ref={formRef}
          currentFolder={currentFolder}
          contextId={contextId}
          contextType={pluralizeContextTypeString(contextType)}
          useCanvasModals={false}
          onFileOptionsChange={(fileOptions: FileOptionsResults) => setFileOptions(fileOptions)}
        />
      )}

      <Button
        {...buttonProps}
        disabled={disabled || hasPendingUploads || !contextType}
        onClick={handleUploadClick}
      >
        {children}
      </Button>
      {/* eslint-disable-next-line react-compiler/react-compiler */}
      {renderModal()}
    </>
  )
}

export default UploadButton
