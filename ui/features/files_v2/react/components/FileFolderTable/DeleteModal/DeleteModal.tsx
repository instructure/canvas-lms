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
import {captureException} from '@sentry/react'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {type File, type Folder} from '../../../../interfaces/File'
import {showFlashSuccess, showFlashError, showFlashWarning} from '@canvas/alerts/react/FlashAlert'
import {UnauthorizedError} from '../../../../utils/apiUtils'
import {deleteItem} from '../../../queries/deleteItem'
import {BulkItemRequestsError} from '../../../queries/BultItemRequestsError'
import {makeBulkItemRequests} from '../../../queries/makeBulkItemRequests'
import {queryClient} from '@canvas/query'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import FileFolderInfo from '../../shared/FileFolderInfo'
import {useRowFocus, SELECT_ALL_FOCUS_STRING} from '../../../contexts/RowFocusContext'
import {useRows} from '../../../contexts/RowsContext'

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
  const {setSessionExpired} = useRows()

  const handleError = useCallback(
    async (error: unknown) => {
      if (error instanceof UnauthorizedError) {
        setSessionExpired(true)
        return
      }

      if (error instanceof BulkItemRequestsError) {
        const failedItems = error.failedItems
        let errorMessage = ''
        if (failedItems.length === 1 && items.length === 1) {
          errorMessage = I18n.t('Failed to delete the selected item. Please try again.')
        } else {
          errorMessage =
            failedItems.length === items.length
              ? I18n.t('Failed to delete all selected items. Please try again.')
              : I18n.t(
                  'Failed to delete %{failedItems} of the %{selectedItems} selected items. Please try again.',
                  {
                    failedItems: failedItems.length,
                    selectedItems: items.length,
                  },
                )
        }

        if (failedItems.length === items.length) {
          showFlashError(errorMessage)()
        } else {
          showFlashWarning(errorMessage)()
          queryClient.refetchQueries({queryKey: ['quota'], type: 'active'})
          await queryClient.refetchQueries({queryKey: ['files'], type: 'active'})
        }
      } else {
        // Impossible branch, makeBulkItemRequests should always throw either UnauthorizedError or BulkItemRequestsError
        const errorMessage = I18n.t('An error occurred while deleting the items. Please try again.')
        showFlashError(errorMessage)()
        captureException(error)
      }
    },
    [setSessionExpired, items],
  )

  const handleConfirmDelete = useCallback(async () => {
    setIsDeleting(true)
    try {
      await makeBulkItemRequests(items, deleteItem)

      const successMessage = isMultiple
        ? I18n.t('%{count} items deleted successfully.', {count: items.length})
        : I18n.t('1 item deleted successfully.')

      showFlashSuccess(successMessage)()
      queryClient.refetchQueries({queryKey: ['quota'], type: 'active'})
      await queryClient.refetchQueries({queryKey: ['files'], type: 'active'})
    } catch (error) {
      handleError(error)
    } finally {
      onClose()
      setRowToFocus(rowIndex ?? SELECT_ALL_FOCUS_STRING)
    }
  }, [items, isMultiple, onClose, rowIndex, setRowToFocus, handleError])

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
