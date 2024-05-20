/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useCallback, useState} from 'react'
import {Billboard} from '@instructure/ui-billboard'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {FileDrop} from '@instructure/ui-file-drop'
import {Flex} from '@instructure/ui-flex'
import type {FormMessage} from '@instructure/ui-form-field'
import {Heading} from '@instructure/ui-heading'
import {IconTrashLine} from '@instructure/ui-icons'
import {Modal} from '@instructure/ui-modal'
import {RocketSVG} from '@instructure/canvas-media'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Spinner} from '@instructure/ui-spinner'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {ViewProps} from '@instructure/ui-view'
import type {AttachmentData} from '../../../types'
import doFileUpload from '../../../shared/UploadFile'
import {renderFileTypeIcon, stringToId} from '../../../shared/utils'

type AddFilesModalProps = {
  open: boolean
  onDismiss: () => void
  onSave: (attachments: AttachmentData[]) => void
}

const AddFilesModal = ({open, onDismiss, onSave}: AddFilesModalProps) => {
  const [fileDropMessages, setFileDropMessages] = useState<FormMessage[]>([])
  const [uploadInFlight, setUploadInFlight] = useState(false)
  const [theFiles, setTheFiles] = useState<File[]>([])

  const setError = useCallback(
    (error: Error) => {
      setFileDropMessages([
        ...fileDropMessages,
        {
          text: error.message,
          type: 'error',
        },
      ])
    },
    [fileDropMessages]
  )

  const handleClose = useCallback(() => {
    setFileDropMessages([])
    setTheFiles([])
    setUploadInFlight(false)
  }, [])

  const handleDismiss = useCallback(() => {
    handleClose()
    onDismiss()
  }, [handleClose, onDismiss])

  const handleSave = useCallback(async () => {
    if (uploadInFlight) return

    if (theFiles.length === 0) {
      onSave([])
      return
    }
    try {
      setUploadInFlight(true)
      const filedata = await Promise.all(theFiles.map(doFileUpload))
      const newAttachments: AttachmentData[] = filedata.map(fdata => {
        const url = new URL(fdata.preview_url, window.location.origin)
        url.pathname = url.pathname.replace(/\w+$/, 'preview')
        url.searchParams.set('verifier', fdata.uuid)
        return {
          id: fdata.id,
          filename: fdata.filename,
          display_name: fdata.display_name,
          size: fdata.size,
          contentType: fdata['content-type'],
          url: url.href,
        } as AttachmentData
      })
      onSave(newAttachments)
    } catch (ex) {
      setError(ex as Error)
    } finally {
      setUploadInFlight(false)
    }
  }, [onSave, setError, theFiles, uploadInFlight])

  const handleDropRejected = useCallback(() => {
    setFileDropMessages([
      {
        text: 'Invalid file type',
        type: 'error',
      },
    ])
  }, [])

  const handleDropAccepted = useCallback(
    (acceptedFiles: ArrayLike<File | DataTransferItem>) => {
      setFileDropMessages([])
      const newFiles = acceptedFiles as File[]

      // add new files, replacing files with the same name
      const newFileList: Record<string, File> = {}
      theFiles.forEach(file => {
        newFileList[file.name] = file
      })
      newFiles.forEach(file => {
        newFileList[file.name] = file
      })
      setTheFiles(Object.values(newFileList).sort((a, b) => a.name.localeCompare(b.name)))
    },
    [theFiles]
  )

  const handleRemoveFile = useCallback(
    (event: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      const filename = (event.target as HTMLButtonElement).getAttribute('data-filename')
      if (!filename) return
      setTheFiles(theFiles.filter(file => file.name !== filename))
    },
    [theFiles]
  )

  const renderFilesTable = () => {
    return (
      <Table caption="files" layout="auto">
        <Table.Head>
          <Table.Row>
            <Table.ColHeader id="fliename">
              <ScreenReaderContent>File name</ScreenReaderContent>
            </Table.ColHeader>
            <Table.ColHeader id="action" width="2rem">
              <ScreenReaderContent>Action</ScreenReaderContent>
            </Table.ColHeader>
          </Table.Row>
        </Table.Head>
        <Table.Body>
          {theFiles.map((file: File) => {
            return (
              <Table.Row key={stringToId(file.name)}>
                <Table.Cell>
                  <Flex gap="small">
                    <Flex.Item shouldGrow={false}>{renderFileTypeIcon(file.type)}</Flex.Item>
                    <Flex.Item shouldGrow={true}>{file.name}</Flex.Item>
                  </Flex>
                </Table.Cell>
                <Table.Cell>
                  <IconButton
                    screenReaderLabel={`remove ${file.name}`}
                    data-filename={file.name}
                    onClick={handleRemoveFile}
                  >
                    <IconTrashLine />
                  </IconButton>
                </Table.Cell>
              </Table.Row>
            )
          })}
        </Table.Body>
      </Table>
    )
  }

  return (
    <Modal
      open={open}
      size="auto"
      label="Edit Cover Image"
      onDismiss={handleDismiss}
      onClose={handleClose}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="medium"
          onClick={handleDismiss}
          screenReaderLabel="Close"
        />
        <Heading>Add Files</Heading>
      </Modal.Header>
      <Modal.Body>
        <FileDrop
          accept={undefined}
          messages={fileDropMessages}
          onDropAccepted={handleDropAccepted}
          onDropRejected={handleDropRejected}
          renderLabel={
            <Billboard
              heading="Upload Files"
              hero={<RocketSVG width="3em" height="3em" />}
              message={
                uploadInFlight ? (
                  <Spinner size="large" renderTitle="Uploading" />
                ) : (
                  <View as="div" margin="small 0">
                    <Text>Drag and drop, or upload from your computer</Text>
                  </View>
                )
              }
            />
          }
          shouldAllowMultiple={true}
          width="942px"
        />
        <View as="div" margin="small 0">
          {renderFilesTable()}
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button color="secondary" onClick={handleDismiss}>
          Cancel
        </Button>
        <Button color="primary" margin="0 0 0 small" onClick={handleSave}>
          Add Files
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default AddFilesModal
