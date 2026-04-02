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

import React, {useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {ContextFile} from './types'
import FileList from './FileList'
import {useFileUpload} from './hooks/useFileUpload'
import CanvasFilesBrowser from './components/CanvasFilesBrowser/CanvasFilesBrowser'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashAlert} from '@instructure/platform-alerts'

const I18n = createI18nScope('canvas_file_upload')

interface CanvasFileUploadProps {
  files: ContextFile[]
  onFilesChange: (files: ContextFile[]) => void
  courseId: string
  allowedFileTypes?: string[]
  maxFileSizeMB?: number // Maximum file size in MB, undefined = unlimited
  maxFiles?: number // Maximum number of files, undefined = unlimited
}

const CanvasFileUpload: React.FC<CanvasFileUploadProps> = ({
  files,
  onFilesChange,
  courseId,
  allowedFileTypes,
  maxFileSizeMB,
  maxFiles,
}) => {
  const {uploadingFileNames, failedFileNames, clearFailedFile, handleDrop, isUploading} =
    useFileUpload({
      files,
      onFilesChange,
      courseId,
      allowedFileTypes,
      maxFileSizeMB,
      maxFiles,
    })

  const fileInputRef = useRef<HTMLInputElement>(null)
  const isSelectingRef = useRef(false)
  const [showBrowserModal, setShowBrowserModal] = useState(false)

  const handleRemoveFile = (fileId: string) => {
    const updatedFiles = files.filter(file => file.id !== fileId)
    onFilesChange(updatedFiles)
  }

  const handleFileInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      handleDrop(e.target.files, [])
      e.target.value = ''
    }
  }

  const handleFileSelect = async (fileID: string) => {
    if (!fileID || isSelectingRef.current) return
    isSelectingRef.current = true

    try {
      const {json} = await doFetchApi<ContextFile>({
        path: `/api/v1/files/${fileID}`,
        method: 'GET',
      })

      if (!json) return

      if (files.some(f => f.id === json.id)) {
        showFlashAlert({
          message: I18n.t('This file has already been added.'),
          type: 'info',
        })
        return
      }

      if (maxFiles && files.length >= maxFiles) {
        showFlashAlert({
          message: I18n.t('Maximum number of files reached (%{max})', {max: maxFiles}),
          type: 'error',
        })
        return
      }

      onFilesChange([...files, json])

      showFlashAlert({
        message: I18n.t('File added successfully from Canvas Files'),
        type: 'success',
      })

      setShowBrowserModal(false)
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'Unknown error'
      showFlashAlert({
        message: I18n.t('Failed to add file: %{error}', {error: message}),
        type: 'error',
      })
    } finally {
      isSelectingRef.current = false
    }
  }

  return (
    <View as="div">
      <View as="div" margin="0 0 small 0">
        <Text weight="bold">
          {I18n.t('Up to %{maxFiles} file sources (Maximum of %{maxSize}MB)', {
            maxFiles: maxFiles ?? 10,
            maxSize: maxFileSizeMB,
          })}
        </Text>
      </View>
      {(files.length > 0 || uploadingFileNames.size > 0 || failedFileNames.size > 0) && (
        <FileList
          files={files}
          uploadingFileNames={uploadingFileNames}
          failedFileNames={failedFileNames}
          onRemoveFile={handleRemoveFile}
          onClearFailedFile={clearFailedFile}
        />
      )}

      <Flex as="div" wrap="wrap">
        <input
          ref={fileInputRef}
          type="file"
          multiple={true}
          accept={allowedFileTypes?.join(',')}
          onChange={handleFileInputChange}
          style={{display: 'none'}}
          data-testid="context-files-input"
        />
        <Flex.Item margin="0 small 0 0">
          <Button
            color="primary"
            onClick={() => fileInputRef.current?.click()}
            interaction={isUploading ? 'disabled' : 'enabled'}
          >
            {isUploading ? I18n.t('Uploading...') : I18n.t('Upload from computer')}
          </Button>
        </Flex.Item>
        <Flex.Item>
          <Button color="secondary" onClick={() => setShowBrowserModal(true)}>
            {I18n.t('Choose from Canvas files')}
          </Button>
        </Flex.Item>
      </Flex>

      {/* Canvas Files Browser Modal */}
      <Modal
        open={showBrowserModal}
        onDismiss={() => setShowBrowserModal(false)}
        size="large"
        label={I18n.t('Select from Canvas Files')}
        shouldCloseOnDocumentClick={true}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="medium"
            onClick={() => setShowBrowserModal(false)}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>{I18n.t('Select from Canvas Files')}</Heading>
        </Modal.Header>
        <Modal.Body padding="0">
          <View as="div" height="500px" position="relative" overflowY="auto">
            <CanvasFilesBrowser
              courseID={courseId}
              allowedExtensions={allowedFileTypes}
              handleCanvasFileSelect={handleFileSelect}
            />
          </View>
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={() => setShowBrowserModal(false)} margin="0 xx-small 0 0">
            {I18n.t('Cancel')}
          </Button>
        </Modal.Footer>
      </Modal>
    </View>
  )
}

export default CanvasFileUpload
