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
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {FileDrop} from '@instructure/ui-file-drop'
import {Billboard} from '@instructure/ui-billboard'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {Flex} from '@instructure/ui-flex'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv'
import './ForbiddenWordsFileUpload.module.css'

const I18n = useI18nScope('password_complexity_configuration')

declare const ENV: GlobalEnv

interface FileDetails {
  url: string | null
  filename: string | null
}

interface Props {
  open: boolean
  onDismiss: () => void
  onSave: () => void
  setForbiddenWordsUrl: (url: string | null) => void
  setForbiddenWordsFilename: (filename: string | null) => void
}

const initialFileDetails: FileDetails = {url: null, filename: null}

const ForbiddenWordsFileUpload = ({
  open,
  onDismiss,
  onSave,
  setForbiddenWordsUrl,
  setForbiddenWordsFilename,
}: Props) => {
  const [fileDropMessages, setFileDropMessages] = useState<FormMessage[]>([])
  const [fileDetails, setFileDetails] = useState<FileDetails>(initialFileDetails)
  const [isUploading, setIsUploading] = useState(false)
  const [uploadAttempted, setUploadAttempted] = useState(false)
  const [modalClosing, setModalClosing] = useState(false)

  const resetState = useCallback(() => {
    setFileDropMessages([])
    setFileDetails(initialFileDetails)
    setIsUploading(false)
    setUploadAttempted(false)
    setModalClosing(false)
  }, [])

  const handleUpload = useCallback(async () => {
    const {url, filename} = fileDetails

    if (!url || !filename || isUploading || uploadAttempted) return

    setIsUploading(true)
    setUploadAttempted(true)

    try {
      const response = await fetch(url)
      const fileBlob = await response.blob()
      const newFile = new File([fileBlob], filename, {type: fileBlob.type})
      const formData = new FormData()
      formData.append('file', newFile)

      const uploadResponse = await doFetchApi({
        method: 'POST',
        path: `/api/v1/accounts/${ENV.ACCOUNT_ID}/password_complexity/upload_forbidden_words`,
        body: formData,
      })

      if (uploadResponse.response.ok) {
        setForbiddenWordsUrl(url)
        setForbiddenWordsFilename(filename)
        onSave()
        setModalClosing(true)
        onDismiss()
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
      setIsUploading(false)
    }
  }, [
    fileDetails,
    setForbiddenWordsUrl,
    setForbiddenWordsFilename,
    onSave,
    onDismiss,
    isUploading,
    uploadAttempted,
  ])

  const handleDropAccepted = useCallback((acceptedFiles: ArrayLike<File | DataTransferItem>) => {
    const newFile = acceptedFiles[0] as File
    if (newFile.type !== 'text/plain') {
      setFileDropMessages([{text: I18n.t('Invalid file type'), type: 'error'}])
      return
    }
    const url = URL.createObjectURL(newFile)
    const filename = newFile.name

    setFileDetails({url, filename})
    setUploadAttempted(false)
  }, [])

  const handleDropRejected = useCallback(() => {
    setFileDropMessages([{text: I18n.t('Invalid file type'), type: 'error'}])
  }, [])

  useEffect(() => {
    if (fileDetails.url && fileDetails.filename && !isUploading && !uploadAttempted) {
      handleUpload()
    }
  }, [fileDetails, handleUpload, isUploading, uploadAttempted])

  useEffect(() => {
    if (open) {
      resetState()
    }
  }, [open, resetState])

  return (
    <Modal
      open={open}
      onDismiss={() => {
        resetState()
        onDismiss()
      }}
      label={I18n.t('Upload Forbidden Words/Terms List')}
      shouldCloseOnDocumentClick={true}
      size="large"
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
      <Modal.Body padding="large">
        {isUploading || modalClosing ? (
          <Flex justifyItems="center" alignItems="center" height="400px">
            <Flex.Item>
              <Spinner renderTitle={I18n.t('Uploading...')} />
            </Flex.Item>
          </Flex>
        ) : (
          <FileDrop
            id="fileDropContainer"
            accept="text/plain"
            messages={fileDropMessages}
            onDropAccepted={handleDropAccepted}
            onDropRejected={handleDropRejected}
            interaction={isUploading ? 'disabled' : 'enabled'}
            renderLabel={() => (
              <Billboard
                as="div"
                size="medium"
                heading={I18n.t('Upload File')}
                headingLevel="h2"
                hero={<RocketSVG width="179px" />}
                message={
                  <Flex direction="column" alignItems="center" justifyItems="center" gap="small">
                    <Flex.Item>
                      <Text>{I18n.t('Drag and drop, or upload from your computer')}</Text>
                    </Flex.Item>
                    <Flex.Item>
                      <Text>{I18n.t('Supported format: TXT')}</Text>
                    </Flex.Item>
                  </Flex>
                }
              />
            )}
            shouldAllowMultiple={false}
            shouldEnablePreview={false}
            height="400px"
            margin="0"
          />
        )}
      </Modal.Body>
      <Modal.Footer>
        <Button
          onClick={() => {
            resetState()
            onDismiss()
          }}
          disabled={isUploading}
        >
          {I18n.t('Cancel')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default ForbiddenWordsFileUpload
