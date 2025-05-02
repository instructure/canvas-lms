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

import React, {ChangeEvent, useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import FileFolderInfo from './shared/FileFolderInfo'
import {TextInput} from '@instructure/ui-text-input'
import type {File, Folder} from '../../interfaces/File'
import {doFetchApiWithAuthCheck, UnauthorizedError} from '../../utils/apiUtils'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import type {FormMessage} from '@instructure/ui-form-field'
import {isFile, getName, getUniqueId} from '../../utils/fileFolderUtils'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {MAX_FOLDER_NAME_LENGTH} from '../../utils/folderUtils'
import {useRows} from '../contexts/RowsContext'

const I18n = createI18nScope('files_v2')

const updateItemName = (item: File | Folder, name: string) => {
  return doFetchApiWithAuthCheck({
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
  const inputRef = useRef<TextInput>(null)
  const {currentRows, setCurrentRows} = useRows()

  const handleSave = () => {
    const trimmedNewItemName = newItemName.trim()
    if (
      trimmedNewItemName === renamingItem.name ||
      trimmedNewItemName === renamingItem.display_name
    ) {
      onClose()
      return
    }

    const errors = validateNewItemName(isFile(renamingItem), trimmedNewItemName)
    if (errors.length > 0) {
      setErrorMessages(errors)
      inputRef.current?.focus()
      return
    }

    setIsRequestInFlight(true)
    updateItemName(renamingItem, trimmedNewItemName)
      .then(async () => {
        showFlashSuccess(
          I18n.t('Successfully renamed %{item}.', {item: isFile(renamingItem) ? 'file' : 'folder'}),
        )()
        const newRows = [...currentRows]
        const index = newRows.findIndex(row => getUniqueId(row) === getUniqueId(renamingItem))
        if (index !== -1) {
          if (isFile(renamingItem)) {
            newRows[index].filename = trimmedNewItemName
            newRows[index].display_name = trimmedNewItemName
          } else {
            newRows[index].name = trimmedNewItemName
          }
          setCurrentRows(newRows)
        }
        onClose()
      })
      .catch(err => {
        if (err instanceof UnauthorizedError) {
          window.location.href = '/login'
          return
        }
        if (err?.response?.status == 409) {
          showFlashError(
            I18n.t('A file named "%{name}" already exists in this folder.', {
              name: trimmedNewItemName,
            }),
          )()
        } else {
          showFlashError(
            I18n.t('There was an error renaming this %{item}. Please try again.', {
              item: isFile(renamingItem) ? 'file' : 'folder',
            }),
          )()
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

  const validateNewItemName = (isFile: boolean, trimmedName: string): FormMessage[] => {
    const errorMessages: FormMessage[] = []
    if (trimmedName === '') {
      errorMessages.push({
        text: isFile ? I18n.t('File name cannot be blank') : I18n.t('Folder name cannot be blank'),
        type: 'newError',
      })
    } else if (trimmedName.indexOf('/') !== -1) {
      errorMessages.push({
        text: isFile
          ? I18n.t('File name cannot contain /')
          : I18n.t('Folder name cannot contain /'),
        type: 'newError',
      })
    } else if (!isFile && trimmedName.length > MAX_FOLDER_NAME_LENGTH) {
      errorMessages.push({
        text: I18n.t('Folder name cannot exceed 255 characters'),
        type: 'newError',
      })
    }
    return errorMessages
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
          data-testid="rename-modal-button-close"
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
                ref={inputRef}
                data-testid="rename-modal-input-folder-name"
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
          data-testid="rename-modal-button-save"
          disabled={isRequestInFlight}
        >
          {I18n.t('Save')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
