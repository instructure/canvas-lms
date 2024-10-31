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
import {executeApiRequest} from '@canvas/do-fetch-api-effect/apiRequest'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv'
import './ForbiddenWordsFileUpload.css'
import type {PasswordSettingsResponse} from './types'
import doFetchApi from '@canvas/do-fetch-api-effect'

const I18n = useI18nScope('password_complexity_configuration')

declare const ENV: GlobalEnv

interface FileDetails {
  url: string | null
  filename: string | null
}

interface FolderResponse {
  id: number
}

interface FileResponse {
  upload_url: string
  upload_params: Record<string, string>
  id: string
}

interface Props {
  open: boolean
  onDismiss: () => void
  onSave: (attachmentId: number | null) => void
  setForbiddenWordsUrl: (url: string | null) => void
  setForbiddenWordsFilename: (filename: string | null) => void
  setCurrentAttachmentId: (attachmentId: number | null) => void
  setCommonPasswordsAttachmentId: (attachmentId: number | null) => void
  setEnableApplyButton: (enabled: boolean) => void
}

const initialFileDetails: FileDetails = {url: null, filename: null}

export const createFolder = async (): Promise<number | null> => {
  try {
    const formData = new FormData()
    formData.append('name', `password_policy`)
    formData.append('parent_folder_path', 'files/')

    const {response, text} = await doFetchApi<FolderResponse>({
      method: 'POST',
      path: `/api/v1/accounts/${ENV.DOMAIN_ROOT_ACCOUNT_ID}/folders`,
      body: formData,
    })

    const responseBodyParsed = JSON.parse(text)

    if (response.status === 200) {
      return responseBodyParsed.id
    } else {
      throw new Error('Failed to create folder')
    }
  } catch (error) {
    return null
  }
}

const ForbiddenWordsFileUpload = ({
  open,
  onDismiss,
  onSave,
  setForbiddenWordsUrl,
  setForbiddenWordsFilename,
  setCurrentAttachmentId,
  setCommonPasswordsAttachmentId,
  setEnableApplyButton,
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

    if (!filename || isUploading || uploadAttempted) return

    setIsUploading(true)
    setUploadAttempted(true)

    try {
      const {status, data: settingsResult} = await executeApiRequest<PasswordSettingsResponse>({
        path: `/api/v1/accounts/${ENV.DOMAIN_ROOT_ACCOUNT_ID}/settings`,
        method: 'GET',
      })

      if (status !== 200) {
        throw new Error('Failed to fetch current settings.')
      }

      let folderId
      if (settingsResult?.password_policy.common_passwords_folder_id) {
        folderId = settingsResult?.password_policy.common_passwords_folder_id
      } else {
        folderId = await createFolder()
      }
      if (!folderId) throw new Error('Failed to create folder')

      const initialRequestFormData = new FormData()
      initialRequestFormData.append('name', filename)

      // Temporarily using doFetchApi until the endpoint correctly return JSON
      // TODO: Remove doFetchApi and use executeApiRequest once the endpoint returns JSON
      const response = await doFetchApi<FileResponse>({
        method: 'POST',
        path: `/api/v1/folders/${folderId}/files`,
        body: initialRequestFormData,
      })

      if (response.response.status !== 200) {
        throw new Error('Failed to initiate file upload')
      }

      const responseBodyParsed = JSON.parse(response.text)

      const upload_url = responseBodyParsed.upload_url
      const upload_params = responseBodyParsed.upload_params

      const uploadFileFormData = new FormData()
      for (const [key, value] of Object.entries(upload_params)) {
        uploadFileFormData.append(key, value as string)
      }

      if (url && filename) {
        uploadFileFormData.append('file', new File([url], filename))
      } else {
        throw new Error('URL or filename is missing')
      }

      const {data: uploadResponseData, status: uploadStatus} =
        await executeApiRequest<FileResponse>({
          path: upload_url,
          method: 'POST',
          body: uploadFileFormData,
        })

      if (uploadStatus !== 200 && uploadStatus !== 201) {
        throw new Error('Failed to complete the file upload')
      }

      const fileId = Number(uploadResponseData.id)

      const updatedPasswordPolicy = {
        account: {
          settings: {
            password_policy: {
              ...settingsResult?.password_policy,
              common_passwords_folder_id: folderId,
              common_passwords_attachment_id: fileId,
            },
          },
        },
      }

      const {status: accountsSettingsStatus} = await executeApiRequest({
        path: `/api/v1/accounts/${ENV.DOMAIN_ROOT_ACCOUNT_ID}/`,
        body: updatedPasswordPolicy,
        method: 'PUT',
      })

      if (accountsSettingsStatus === 200) {
        setForbiddenWordsUrl(url)
        setForbiddenWordsFilename(filename)
        setCurrentAttachmentId(fileId)
        setCommonPasswordsAttachmentId(fileId)
        onSave(fileId)
        setModalClosing(true)
        onDismiss()
        setEnableApplyButton(true)
      } else {
        throw new Error('Failed to save password policy settings')
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
    setCurrentAttachmentId,
    setCommonPasswordsAttachmentId,
    setEnableApplyButton,
  ])

  const handleDropAccepted = useCallback((acceptedFiles: ArrayLike<File | DataTransferItem>) => {
    const newFile = acceptedFiles[0] as File
    const url = URL.createObjectURL(newFile)
    const filename = newFile.name

    setFileDetails({url, filename})
    setUploadAttempted(false)
  }, [])

  const handleDropRejected = useCallback(() => {
    setFileDropMessages([
      {text: I18n.t('Invalid file type or file size exceeded limit of 1MB'), type: 'error'},
    ])
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
            maxSize={1000000}
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
