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

import React, {useState, useCallback} from 'react'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {type File, type Folder} from '../../../../interfaces/File'
import {isFile} from '../../../../utils/fileFolderUtils'
import {showFlashSuccess, showFlashError} from '@canvas/alerts/react/FlashAlert'
import getCookie from '@instructure/get-cookie'
import {UnauthorizedError} from '../../../../utils/apiUtils'
import {queryClient} from '@canvas/query'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import FileFolderInfo from '../../shared/FileFolderInfo'
import {useRowFocus, SELECT_ALL_FOCUS_STRING} from '../../../contexts/RowFocusContext'

const I18n = createI18nScope('files_v2')

export interface DeleteModalProps {
  open: boolean
  items: (File | Folder)[]
  onClose: () => void
  rowIndex?: number
}

export function DeleteModal({open, items, onClose, rowIndex}: DeleteModalProps) {
  const [isDeleting, setIsDeleting] = useState(false)
  const isDeletingOrLoading = isDeleting || items.length === 0
  const isMultiple = items.length > 1
  const {setRowToFocus} = useRowFocus()

  const handleConfirmDelete = useCallback(async () => {
    setIsDeleting(true)
    try {
      const deletePromises = items.filter(Boolean).map(async (item: File | Folder) => {
        const response = await fetch(
          `/api/v1/${isFile(item) ? 'files' : 'folders'}/${item.id}?force=true`,
          {
            method: 'DELETE',
            headers: {
              'Content-Type': 'application/json',
              'X-CSRF-Token': getCookie('_csrf_token'),
            },
          },
        )

        if (response.status === 401) {
          throw new UnauthorizedError()
        }

        if (!response.ok) {
          const errorText = await response.text()
          throw new Error(`Failed to delete ${item.id}: ${response.status} - ${errorText}`)
        }
      })

      await Promise.all(deletePromises)

      const successMessage = isMultiple
        ? I18n.t('%{count} items deleted successfully.', {count: items.length})
        : I18n.t('1 item deleted successfully.')

      showFlashSuccess(successMessage)()
      queryClient.refetchQueries({queryKey: ['quota'], type: 'active'})
      await queryClient.refetchQueries({queryKey: ['files'], type: 'active'})
    } catch (error) {
      if (error instanceof UnauthorizedError) {
        window.location.href = '/login'
        return
      }
      const errorMessage = I18n.t('Failed to delete items. Please try again.')
      showFlashError(errorMessage)
    } finally {
      onClose()
      setRowToFocus(rowIndex ?? SELECT_ALL_FOCUS_STRING)
    }
  }, [items, isMultiple, onClose, rowIndex, setRowToFocus])

  return (
    <Modal
      size="small"
      open={open}
      onDismiss={onClose}
      onExited={() => setIsDeleting(false)}
      label={I18n.t('Delete Confirmation')}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Delete Items')}</Heading>
      </Modal.Header>
      <Modal.Body>
        {isDeletingOrLoading ? (
          <View as="div" textAlign="center">
            <Spinner
              renderTitle={() => I18n.t('Deleting...')}
              margin="0 0 0 medium"
              aria-live="polite"
              data-testid="delete-spinner"
            />
          </View>
        ) : (
          <>
            <FileFolderInfo items={items} />
            <Text>
              {isMultiple
                ? I18n.t('Deleting these items cannot be undone. Do you want to continue?')
                : I18n.t('Deleting this item cannot be undone. Do you want to continue?')}
            </Text>
          </>
        )}
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onClose} disabled={isDeletingOrLoading} data-testid="modal-cancel-button">
          {I18n.t('Cancel')}
        </Button>
        <Button
          data-testid="modal-delete-button"
          onClick={handleConfirmDelete}
          color="danger"
          margin="none none none small"
          disabled={isDeletingOrLoading}
        >
          {isDeletingOrLoading ? I18n.t('Deleting...') : I18n.t('Delete')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
