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

import React, {ChangeEvent, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import FileFolderInfo from './shared/FileFolderInfo'
import {TextInput} from '@instructure/ui-text-input'
import type {File, Folder} from '../../interfaces/File'
import {queryClient} from '@canvas/query'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import type {FormMessage} from '@instructure/ui-form-field'
import {isFile, getName} from '../../utils/fileFolderUtils'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'

const I18n = createI18nScope('files_v2')

const updateItemName = (item: File | Folder, name: string) => {
  return doFetchApi({
    method: 'PUT',
    path: `/api/v1/${isFile(item) ? 'files' : 'folders'}/${item.id}`,
    body: {name: name},
  })
}

export const RenameModal = ({
  renamingItem,
  isOpen,
  onClose,
}: {
  renamingItem: File | Folder
  isOpen: boolean
  onClose: () => void
}) => {
  const [newItemName, setNewItemName] = useState<string>(getName(renamingItem))
  const [errorMessages, setErrorMessages] = useState<FormMessage[]>()
  const [isRequestInFlight, setIsRequestInFlight] = useState(false)

  const handleSave = () => {
    const trimmedNewItemName = newItemName.trim()
    if (
      trimmedNewItemName === renamingItem.name ||
      trimmedNewItemName === renamingItem.display_name
    ) {
      onClose()
      return
    }

    if (trimmedNewItemName == '' || trimmedNewItemName?.indexOf('/') !== -1) {
      if (isFile(renamingItem)) {
        setErrorMessages(
          !trimmedNewItemName
            ? [{text: I18n.t('File name cannot be blank'), type: 'newError'}]
            : [{text: I18n.t('File name cannot contain /'), type: 'newError'}],
        )
      } else {
        setErrorMessages(
          !trimmedNewItemName
            ? [{text: I18n.t('Folder name cannot be blank'), type: 'newError'}]
            : [{text: I18n.t('Folder name cannot contain /'), type: 'newError'}],
        )
      }
      return
    }

    setIsRequestInFlight(true)
    updateItemName(renamingItem, trimmedNewItemName)
      .then(async () => {
        showFlashSuccess(
          I18n.t('Successfully renamed %{item}', {item: isFile(renamingItem) ? 'file' : 'folder'}),
        )()
        onClose()
        await queryClient.refetchQueries({queryKey: ['files'], type: 'active'})
      })
      .catch(err => {
        if (err?.response?.status == 409) {
          showFlashError(
            I18n.t('A file named "%{name}" already exists in this folder', {
              name: trimmedNewItemName,
            }),
          )()
        } else {
          showFlashError(I18n.t('Renaming failed'))(err)
        }
      })
      .finally(() => {
        setIsRequestInFlight(false)
      })
  }

  const handleExited = () => {
    setNewItemName(getName(renamingItem))
    setErrorMessages([])
    setIsRequestInFlight(false)
  }

  return (
    <Modal
      as="div"
      open={isOpen}
      onDismiss={onClose}
      onExited={handleExited}
      size="small"
      label={I18n.t('Rename file/folder modal')}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Rename')}</Heading>
      </Modal.Header>
      <Modal.Body>
        {isRequestInFlight ? (
          <View as="div" textAlign="center">
            <Spinner
              renderTitle={() =>
                I18n.t('Renaming %{item}', {item: isFile(renamingItem) ? 'file' : 'folder'})
              }
              margin="0 0 0 medium"
              aria-live="polite"
              data-testid="rename-spinner"
            />
          </View>
        ) : (
          <>
            <FileFolderInfo items={[renamingItem]} />
            <div style={{paddingTop: '1.5rem'}}>
              <TextInput
                value={newItemName}
                onChange={(_e: ChangeEvent<HTMLInputElement>, new_value: string) => {
                  setNewItemName(new_value)
                }}
                onKeyDown={e => {
                  if (e.key === 'Enter') {
                    handleSave()
                  }
                }}
                messages={errorMessages}
                renderLabel={isFile(renamingItem) ? I18n.t('File Name') : I18n.t('Folder Name')}
                isRequired
              />
            </div>
          </>
        )}
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onClose} disabled={isRequestInFlight}>
          {I18n.t('Cancel')}
        </Button>
        <Button
          color="primary"
          margin="none none none small"
          onClick={handleSave}
          disabled={isRequestInFlight}
        >
          {I18n.t('Save')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
