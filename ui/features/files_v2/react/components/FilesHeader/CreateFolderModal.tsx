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
import {Modal} from '@instructure/ui-modal'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {TextInput} from '@instructure/ui-text-input'
import {queryClient} from '@canvas/query'
import {useFileManagement} from '../../contexts/FileManagementContext'
import {generateFolderPostUrl, UnauthorizedError} from '../../../utils/apiUtils'
import getCookie from '@instructure/get-cookie'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {useMutation} from '@tanstack/react-query'
import {FormMessage} from '@instructure/ui-form-field'
import {MAX_FOLDER_NAME_LENGTH} from '../../../utils/folderUtils'

const I18n = createI18nScope('files_v2')

interface CreateFolderModalProps {
  isOpen: boolean
  onRequestClose: () => void
  onExited: (wasSuccessful?: boolean) => void
}

const CreateFolderModal = ({isOpen, onRequestClose, onExited}: CreateFolderModalProps) => {
  const [folderName, setFolderName] = useState('')
  const [isRequestInFlight, setIsRequestInFlight] = useState(false)
  const [wasRequestSuccessful, setWasRequestSuccessful] = useState(false)
  const [errorMessage, setErrorMessage] = useState<FormMessage>()
  const textInputRef = useRef<TextInput>(null)
  const {folderId: parentFolderId} = useFileManagement()

  const createFolderMutation = useMutation({
    mutationFn: async (name: string) => {
      setIsRequestInFlight(true)
      const postUrl = generateFolderPostUrl(parentFolderId)
      const response = await fetch(postUrl, {
        method: 'POST',
        body: JSON.stringify({name}),
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': getCookie('_csrf_token'),
        },
      })
      if (response.status === 401) {
        throw new UnauthorizedError()
      }
      if (!response.ok) {
        throw new Error('Network response was not ok')
      }
    },
    onSuccess: async () => {
      setWasRequestSuccessful(true)
      onRequestClose()
      await queryClient.refetchQueries({queryKey: ['files'], type: 'active'})
    },
    onError: error => {
      if (error instanceof UnauthorizedError) {
        window.location.href = '/login'
        return
      }
      showFlashError(I18n.t('There was an error creating the folder. Please try again.'))(
        error as Error,
      )
    },
    onSettled: () => {
      setIsRequestInFlight(false)
    },
  })

  const handleSubmit = () => {
    if (folderName.length > MAX_FOLDER_NAME_LENGTH) {
      setErrorMessage({
        text: I18n.t('Folder name cannot exceed 255 characters'),
        type: 'newError',
      })
      textInputRef.current?.focus()
      return
    }
    createFolderMutation.mutate(folderName)
  }

  const handleExited = () => {
    setFolderName('')
    setIsRequestInFlight(false)
    onExited(wasRequestSuccessful)
    setWasRequestSuccessful(false)
    setErrorMessage(undefined)
  }

  return (
    <Modal
      as="div"
      open={isOpen}
      onDismiss={onRequestClose}
      onSubmit={handleSubmit}
      onExited={handleExited}
      label={I18n.t('Create Folder')}
      shouldCloseOnDocumentClick
      size="small"
      shouldReturnFocus={false}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onRequestClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading level="h2">{I18n.t('Create Folder')}</Heading>
      </Modal.Header>
      <Modal.Body>
        {isRequestInFlight ? (
          <View as="div" textAlign="center">
            <Spinner
              renderTitle={() => I18n.t('Creating folder')}
              margin="0 0 0 medium"
              aria-live="polite"
              data-testid="create-folder-spinner"
            />
          </View>
        ) : (
          <TextInput
            renderLabel={I18n.t('Folder Name')}
            name="folderName"
            value={folderName}
            ref={textInputRef}
            messages={errorMessage ? [errorMessage] : []}
            onChange={(_e, newValue) => setFolderName(newValue)}
            onKeyDown={e => {
              if (e.key === 'Enter') {
                handleSubmit()
              }
            }}
          />
        )}
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onRequestClose} disabled={isRequestInFlight} margin="0 x-small 0 0">
          {I18n.t('Cancel')}
        </Button>
        <Button color="primary" onClick={handleSubmit} disabled={isRequestInFlight}>
          {I18n.t('Create Folder')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default CreateFolderModal
