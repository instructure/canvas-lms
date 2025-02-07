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

import React, { useState, useCallback } from 'react'
import { Modal } from '@instructure/ui-modal'
import { Button, CloseButton } from '@instructure/ui-buttons'
import { Heading } from '@instructure/ui-heading'
import { Text } from '@instructure/ui-text'
import { Flex } from '@instructure/ui-flex'
import { useScope as createI18nScope } from '@canvas/i18n'
import { type File, type Folder } from '../../../interfaces/File'
import { isFile } from '../../../utils/fileFolderUtils'
import { showFlashSuccess, showFlashError } from '@canvas/alerts/react/FlashAlert'
import getCookie from '@instructure/get-cookie'
import { queryClient } from '@canvas/query'
import FileFolderInfo from '../shared/FileFolderInfo'

const I18n = createI18nScope('files_v2')

interface DeleteModalProps {
  open: boolean
  items: (File | Folder)[]
  onClose: () => void
}

const DeleteModal = ({ open, items, onClose }: DeleteModalProps) => {
  const [isDeleting, setIsDeleting] = useState(false)
  const isMultiple = items.length > 1

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
          }
        )

        if (!response.ok) {
          const errorText = await response.text()
          throw new Error(`Failed to delete ${item.id}: ${response.status} - ${errorText}`)
        }
      })

      await Promise.all(deletePromises)

      const successMessage = isMultiple
        ? I18n.t('%{count} items deleted successfully', { count: items.length })
        : I18n.t('1 item deleted successfully')

      showFlashSuccess(successMessage)()
      await queryClient.refetchQueries({ queryKey: ['files'], type: 'active' })
    } catch (error) {
      const errorMessage = I18n.t('Failed to delete items. Please try again.')
      showFlashError(errorMessage)
    } finally {
      onClose()
    }
  }, [items, isMultiple, onClose])

  if (items.length === 0) {
    return null
  }

  return (
    <Modal open={open} onDismiss={onClose} onExited={() => setIsDeleting(false)} label={I18n.t('Delete Confirmation')}>
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
        <FileFolderInfo items={items} />
        <Text>
          {isMultiple
            ? I18n.t('Deleting these items cannot be undone. Do you want to continue?')
            : I18n.t('Deleting this item cannot be undone. Do you want to continue?')}
        </Text>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onClose} disabled={isDeleting}>
          {I18n.t('Cancel')}
        </Button>
        <Button data-testid="modal-delete-button" onClick={handleConfirmDelete} color="danger" margin="none none none small" disabled={isDeleting}>
          {isDeleting ? I18n.t('Deleting...') : I18n.t('Delete')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default DeleteModal
