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

import React, {useContext, useState} from 'react'
import {Modal} from '@instructure/ui-modal'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {TextInput} from '@instructure/ui-text-input'
import {useMutation, queryClient} from '@canvas/query'
import {FileManagementContext} from '../Contexts'
import {generateFolderPostUrl} from '../../../utils/apiUtils'
import getCookie from '@instructure/get-cookie'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'

const I18n = createI18nScope('files_v2')

interface CreateFolderModalProps {
  isOpen: boolean
  onRequestClose: () => void
}

const CreateFolderModal = ({isOpen, onRequestClose}: CreateFolderModalProps) => {
  const [folderName, setFolderName] = useState('')
  const [isRequestInFlight, setIsRequestInFlight] = useState(false)
  const {folderId: parentFolderId} = useContext(FileManagementContext)

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
      if (!response.ok) {
        throw new Error('Network response was not ok')
      }
    },
    onSuccess: async () => {
      showFlashSuccess(I18n.t('Folder was successfully created.'))()
      onRequestClose()
      await queryClient.refetchQueries({queryKey: ['files'], type: 'active'})
    },
    onError: () => {
      showFlashError(I18n.t('There was an error creating the folder. Please try again.'))(
        new Error(),
      )
    },
    onSettled: () => {
      setIsRequestInFlight(false)
    },
  })

  const handleSubmit = () => {
    createFolderMutation.mutate(folderName)
  }

  const handleExited = () => {
    setFolderName('')
    setIsRequestInFlight(false)
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
