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
import {FileManagementContext} from '../Contexts'
import UploadQueue from '@canvas/files/react/modules/UploadQueue'

type UploadButtonProps = ButtonProps

const UploadButton = ({disabled, children, ...buttonProps}: UploadButtonProps) => {
  const {contextId, contextType, currentFolder} = useContext(FileManagementContext)
  const formRef = useRef<UploadForm>(null)

  const [hasPendingUploads, setHasPendingUploads] = useState<boolean>(
    !!UploadQueue.pendingUploads(),
  )

  const handleQueueChange = useCallback(
    () => setHasPendingUploads(!!UploadQueue.pendingUploads()),
    [],
  )

  const handleUploadClick = useCallback(() => formRef.current?.addFiles(), [])

  useEffect(() => {
    UploadQueue.addChangeListener(handleQueueChange)
    return () => UploadQueue.removeChangeListener(handleQueueChange)
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <>
      <UploadForm
        allowSkip={true}
        ref={formRef}
        currentFolder={currentFolder}
        contextId={contextId}
        contextType={contextType}
        // TODO: Support Zip file upload and file rename
        onZipFileUpload={() => {}}
        onFileRename={() => {}}
      />
      <Button {...buttonProps} disabled={disabled || hasPendingUploads} onClick={handleUploadClick}>
        {children}
      </Button>
    </>
  )
}

export default UploadButton
