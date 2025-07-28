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

import React, {useCallback, useEffect, useState} from 'react'
import {Button, type ButtonProps} from '@instructure/ui-buttons'
import {useFileManagement} from '../../../contexts/FileManagementContext'
import UploadQueue from '@canvas/files/react/modules/UploadQueue'
import {pluralizeContextTypeString} from '../../../../utils/fileFolderUtils'
import {createPortal} from 'react-dom'
import {UploadForm} from './UploadForm'

type UploadButtonProps = ButtonProps

const UploadButton = ({disabled, children, ...buttonProps}: UploadButtonProps) => {
  const {contextId, contextType, currentFolder} = useFileManagement()
  const [isOpen, setIsOpen] = useState<boolean>(false)

  const [hasPendingUploads, setHasPendingUploads] = useState<boolean>(
    !!UploadQueue.pendingUploads(),
  )

  const handleQueueChange = useCallback(
    () => setHasPendingUploads(!!UploadQueue.pendingUploads()),
    [],
  )

  const handleUploadClick = useCallback(() => {
    setIsOpen(true)
  }, [])

  useEffect(() => {
    UploadQueue.addChangeListener(handleQueueChange)
    return () => UploadQueue.removeChangeListener(handleQueueChange)
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <>
      {/* contextType and contextId are null on All My Files page */}
      {contextType &&
        createPortal(
          <UploadForm
            open={isOpen}
            onClose={() => {
              setIsOpen(false)
            }}
            currentFolder={currentFolder!}
            contextId={contextId}
            contextType={pluralizeContextTypeString(contextType)}
          />,
          document.body,
        )}

      <Button
        {...buttonProps}
        disabled={disabled || hasPendingUploads || !contextType}
        onClick={handleUploadClick}
        data-testid="upload-button"
      >
        {children}
      </Button>
    </>
  )
}

export default UploadButton
