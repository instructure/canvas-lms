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
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Billboard} from '@instructure/ui-billboard'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {IconFolderLine, IconUploadLine} from '@instructure/ui-icons'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {ContextFile} from './types'
import FileList from './FileList'
import {useFileUpload} from './hooks/useFileUpload'
import CanvasFilesBrowser from './components/CanvasFilesBrowser/CanvasFilesBrowser'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

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
  // Use custom hook for upload logic
  const {uploadingFileNames, handleDrop, isUploading} = useFileUpload({
    files,
    onFilesChange,
    courseId,
    allowedFileTypes,
    maxFileSizeMB,
    maxFiles,
  })

  const [showBrowserModal, setShowBrowserModal] = useState(false)

  const handleRemoveFile = (fileId: string) => {
    const updatedFiles = files.filter(file => file.id !== fileId)
    onFilesChange(updatedFiles)
  }

  const handleFileSelect = async (fileID: string) => {
    if (!fileID) return

    try {
      // Fetch file metadata
      const {json} = await doFetchApi<ContextFile>({
        path: `/api/v1/files/${fileID}`,
        method: 'GET',
      })

      if (!json) return

      // Check if file already exists
      if (files.some(f => f.id === json.id)) {
        showFlashAlert({
          message: I18n.t('This file has already been added.'),
          type: 'info',
        })
        return
      }

      // Check max files limit
      if (maxFiles && files.length >= maxFiles) {
        showFlashAlert({
          message: I18n.t('Maximum number of files reached (%{max})', {max: maxFiles}),
          type: 'error',
        })
        return
      }

      // Add to files list
      const newFiles = [...files, json]
      onFilesChange(newFiles)

      showFlashAlert({
        message: I18n.t('File added successfully from Canvas Files'),
        type: 'success',
      })

      // Close modal
      setShowBrowserModal(false)
    } catch (error: any) {
      showFlashAlert({
        message: I18n.t('Failed to add file: %{error}', {
          error: error.message || 'Unknown error',
        }),
        type: 'error',
      })
    }
  }

  return (
    <View as="div">
      <View
        as="div"
        borderWidth="small"
        borderRadius="medium"
        borderColor="primary"
        background="secondary"
        padding="large small"
        margin="medium 0"
        height="400px"
      >
        <Flex
          as="div"
          justifyItems="space-between"
          alignItems="stretch"
          wrap="no-wrap"
          direction="row"
          height="100%"
          padding="small 0"
        >
          {/* Upload from Computer */}
          <Flex.Item width="45%">
            <View
              as="div"
              background="primary"
              borderRadius="medium"
              height="100%"
              margin="0 large"
            >
              <FileDrop
                data-testid="context-files-drop"
                height="100%"
                shouldAllowMultiple={true}
                onDrop={handleDrop}
                accept={allowedFileTypes?.join(',')}
                renderLabel={
                  <Flex height="100%" justifyItems="center" alignItems="center">
                    <Billboard
                      size="small"
                      hero={<IconUploadLine size="large" />}
                      as="div"
                      headingAs="span"
                      headingLevel="h3"
                      heading={I18n.t('Upload from Computer')}
                      message={
                        <Text color="brand">
                          {isUploading ? I18n.t('Uploading...') : I18n.t('Drag files or click')}
                        </Text>
                      }
                      disabled={isUploading}
                    />
                  </Flex>
                }
              />
            </View>
          </Flex.Item>

          {/* Separator with "or" */}
          <Flex.Item width="10%" textAlign="center" as="div">
            <div
              style={{
                display: 'flex',
                height: '100%',
                position: 'relative',
                flexDirection: 'column',
                justifyContent: 'center',
                alignItems: 'center',
              }}
            >
              <span
                style={{
                  display: 'block',
                  width: '100%',
                  zIndex: 99,
                  backgroundColor: '#F5F5F5',
                  padding: '0.75rem 0',
                  position: 'relative',
                }}
              >
                {I18n.t('or')}
              </span>
              <div
                style={{
                  height: '100%',
                  width: '1px',
                  left: '50%',
                  top: 0,
                  position: 'absolute',
                  backgroundColor: '#C7CDD1',
                  transform: 'translateX(-50%)',
                }}
              >
                &nbsp;
              </div>
            </div>
          </Flex.Item>

          {/* Select from Canvas Files - Stub for future work */}
          <Flex.Item width="45%" as="div">
            <Flex height="100%" justifyItems="center" alignItems="center">
              <View
                as="div"
                background="primary"
                borderColor="primary"
                borderWidth="small"
                borderRadius="medium"
                width="80%"
              >
                <Button
                  display="block"
                  height="100%"
                  onClick={() => setShowBrowserModal(true)}
                  themeOverride={{borderWidth: '0'}}
                  withBackground={false}
                >
                  <Flex direction="row" justifyItems="center" padding="xxx-small 0">
                    <Flex.Item margin="0 0 0 small">
                      <IconFolderLine size="medium" color="primary" width="24px" height="24px" />
                    </Flex.Item>
                    <Flex.Item margin="0 small" shouldShrink={true}>
                      <Text color="primary" size="large">
                        {I18n.t('Canvas Files')}
                      </Text>
                    </Flex.Item>
                  </Flex>
                </Button>
              </View>
            </Flex>
          </Flex.Item>
        </Flex>
      </View>

      {/* File List Component */}
      {(files.length > 0 || uploadingFileNames.size > 0) && (
        <FileList
          files={files}
          uploadingFileNames={uploadingFileNames}
          onRemoveFile={handleRemoveFile}
        />
      )}

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
