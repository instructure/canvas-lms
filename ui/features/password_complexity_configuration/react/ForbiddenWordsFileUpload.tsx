/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import {RocketSVG} from '@instructure/canvas-media'
import type {FormMessage} from '@instructure/ui-form-field'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {FileDrop} from '@instructure/ui-file-drop'
import {Billboard} from '@instructure/ui-billboard'
import {Text} from '@instructure/ui-text'
import {Table} from '@instructure/ui-table'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {IconTrashLine} from '@instructure/ui-icons'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv'

const I18n = useI18nScope('password_complexity_configuration')

declare const ENV: GlobalEnv

type Props = {
  open: boolean
  onDismiss: () => void
  onSave: () => void
  setForbiddenWordsUrl: (url: string | null) => void
  setForbiddenWordsFilename: (filename: string | null) => void
}

const ForbiddenWordsFileUpload = ({
  open,
  onDismiss,
  onSave,
  setForbiddenWordsUrl,
  setForbiddenWordsFilename,
}: Props) => {
  const [fileDropMessages, setFileDropMessages] = useState<FormMessage[]>([])
  const [uploadInFlight, setUploadInFlight] = useState(false)
  const [localForbiddenWordsUrl, setLocalForbiddenWordsUrl] = useState<string | null>(null)
  const [localForbiddenWordsFilename, setLocalForbiddenWordsFilename] = useState<string | null>(
    null
  )
  const [isValidFile, setIsValidFile] = useState(false)

  useEffect(() => {
    if (open) {
      setLocalForbiddenWordsUrl(null)
      setLocalForbiddenWordsFilename(null)
      setIsValidFile(false)
    }
  }, [open])

  const resetState = useCallback(() => {
    setFileDropMessages([])
    setLocalForbiddenWordsUrl(null)
    setLocalForbiddenWordsFilename(null)
    setIsValidFile(false)
  }, [])

  const handleDropAccepted = useCallback((acceptedFiles: ArrayLike<File | DataTransferItem>) => {
    setFileDropMessages([])
    const newFile = acceptedFiles[0] as File
    if (newFile.type !== 'text/plain') {
      setFileDropMessages([{text: I18n.t('Invalid file type'), type: 'error'}])
      setIsValidFile(false)
      return
    }
    setLocalForbiddenWordsUrl(URL.createObjectURL(newFile))
    setLocalForbiddenWordsFilename(newFile.name)
    setIsValidFile(true)
  }, [])

  const handleRemoveFile = useCallback(() => {
    setLocalForbiddenWordsUrl(null)
    setLocalForbiddenWordsFilename(null)
    setIsValidFile(false)
  }, [])

  const handleUpload = useCallback(async () => {
    if (!localForbiddenWordsUrl || !localForbiddenWordsFilename) return

    setUploadInFlight(true)

    try {
      const response = await fetch(localForbiddenWordsUrl)
      const fileBlob = await response.blob()
      const newFile = new File([fileBlob], localForbiddenWordsFilename, {type: fileBlob.type})
      const formData = new FormData()
      formData.append('file', newFile)
      const uploadResponse = await doFetchApi({
        method: 'POST',
        path: `/api/v1/accounts/${ENV.ACCOUNT_ID}/password_complexity/upload_forbidden_words`,
        body: formData,
      })
      if (uploadResponse.response.ok) {
        setForbiddenWordsUrl(localForbiddenWordsUrl)
        setForbiddenWordsFilename(localForbiddenWordsFilename)
        onSave()
        resetState()
      } else {
        setFileDropMessages([
          {
            text: I18n.t('Upload failed. Please try again later.'),
            type: 'error',
          },
        ])
      }
    } catch (error) {
      setFileDropMessages([
        {
          text: I18n.t('An error occurred during the upload. Please try again later.'),
          type: 'error',
        },
      ])
    } finally {
      setUploadInFlight(false)
    }
  }, [
    localForbiddenWordsUrl,
    localForbiddenWordsFilename,
    setForbiddenWordsUrl,
    setForbiddenWordsFilename,
    onSave,
    resetState,
  ])

  const renderFilesTable = () => {
    if (!localForbiddenWordsFilename) return null
    return (
      <Table caption="files" layout="auto">
        <Table.Head>
          <Table.Row>
            <Table.ColHeader id="filename">File name</Table.ColHeader>
            <Table.ColHeader id="action" width="2rem">
              <ScreenReaderContent>Action</ScreenReaderContent>
            </Table.ColHeader>
          </Table.Row>
        </Table.Head>
        <Table.Body>
          <Table.Row key={localForbiddenWordsFilename}>
            <Table.Cell>
              <Flex gap="small">
                <Flex.Item shouldGrow={true}>{localForbiddenWordsFilename}</Flex.Item>
              </Flex>
            </Table.Cell>
            <Table.Cell>
              <IconButton
                screenReaderLabel={`remove ${localForbiddenWordsFilename}`}
                onClick={handleRemoveFile}
              >
                <IconTrashLine />
              </IconButton>
            </Table.Cell>
          </Table.Row>
        </Table.Body>
      </Table>
    )
  }

  return (
    <View as="div">
      <Modal
        open={open}
        onDismiss={() => {
          resetState()
          onDismiss()
        }}
        size="medium"
        label={I18n.t('Upload Forbidden Words/Terms List')}
        shouldCloseOnDocumentClick={true}
        overflow="scroll"
      >
        <Modal.Header>
          <Heading>{I18n.t('Upload Forbidden Words/Terms List')}</Heading>
          <CloseButton
            margin="small 0 0 0"
            placement="end"
            offset="small"
            onClick={() => {
              resetState()
              onDismiss()
            }}
            screenReaderLabel={I18n.t('Close')}
          />
        </Modal.Header>
        <Modal.Body>
          {!localForbiddenWordsUrl && (
            <div style={{overflowY: 'clip'}}>
              <FileDrop
                accept="text/plain"
                messages={fileDropMessages}
                onDropAccepted={handleDropAccepted}
                renderLabel={() => (
                  <Billboard
                    size="medium"
                    heading={I18n.t('Upload File')}
                    headingLevel="h2"
                    hero={<RocketSVG width="3em" height="3em" />}
                    message={
                      <>
                        <View as="div" margin="small 0">
                          <Text>{I18n.t('Drag and drop, or upload from your computer')}</Text>
                        </View>
                        <View as="div" margin="small 0">
                          <Text>{I18n.t('Supported format: TXT')}</Text>
                        </View>
                      </>
                    }
                  />
                )}
                shouldAllowMultiple={false}
                shouldEnablePreview={false}
                width="942px"
              />
            </div>
          )}
          {localForbiddenWordsUrl && (
            <View as="div" margin="small 0">
              {renderFilesTable()}
            </View>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button
            onClick={() => {
              resetState()
              onDismiss()
            }}
          >
            {I18n.t('Cancel')}
          </Button>
          <Button
            color="primary"
            margin="0 0 0 small"
            onClick={handleUpload}
            disabled={uploadInFlight || !isValidFile}
          >
            {uploadInFlight ? I18n.t('Uploading...') : I18n.t('Upload')}
          </Button>
        </Modal.Footer>
      </Modal>
    </View>
  )
}

export default ForbiddenWordsFileUpload
