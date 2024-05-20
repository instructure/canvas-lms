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

import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {useMutation, queryClient} from '@canvas/query'
import {deleteRubric} from '../../queries/ViewRubricQueries'
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {View} from '@instructure/ui-view'
import {Alert} from '@instructure/ui-alerts'
import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('rubrics-duplicate-modal')

export type DeleteRubricModalProps = {
  id?: string
  title: string
  accountId?: string
  courseId?: string
  isOpen: boolean
  onDismiss: () => void
  setPopoverIsOpen: (isOpen: boolean) => void
}
export const DeleteRubricModal = ({
  id,
  title,
  accountId,
  courseId,
  isOpen,
  onDismiss,
  setPopoverIsOpen,
}: DeleteRubricModalProps) => {
  const {
    isLoading: deleteLoading,
    isError: deleteError,
    mutate,
  } = useMutation({
    mutationFn: async () => deleteRubric({id, accountId, courseId}),
    mutationKey: ['delete-rubric'],
    onSuccess: async () => {
      showFlashSuccess(I18n.t('Rubric deleted successfully'))()
      const queryKey = accountId ? `accountRubrics-${accountId}` : `courseRubrics-${courseId}`
      await queryClient.invalidateQueries([`fetch-rubric-${id}`], {}, {cancelRefetch: true})
      await queryClient.invalidateQueries([queryKey], undefined, {cancelRefetch: true})
      onDismiss()
      setPopoverIsOpen(false)
    },
  })

  return (
    <View as="div">
      {deleteError && (
        <Alert
          variant="error"
          liveRegionPoliteness="polite"
          isLiveRegionAtomic={true}
          liveRegion={getLiveRegion}
          timeout={3000}
        >
          <Text weight="bold">{I18n.t('There was an error deleting the rubric.')}</Text>
        </Alert>
      )}
      <Modal
        open={isOpen}
        onDismiss={onDismiss}
        label={I18n.t('Delete Rubric Modal')}
        shouldCloseOnDocumentClick={true}
        size="small"
        data-testid="delete-rubric-modal"
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={onDismiss}
            screenReaderLabel={I18n.t('Close')}
            data-testid="close-delete-rubric-modal-button"
          />
          <Heading>{I18n.t('Delete %{title}', {title})}</Heading>
        </Modal.Header>
        <Modal.Body>{I18n.t('Are you sure you want to delete this rubric?')}</Modal.Body>
        <Modal.Footer>
          <Button
            onClick={onDismiss}
            margin="0 x-small 0 0"
            data-testid="cancel-delete-rubric-modal-button"
          >
            {I18n.t('Cancel')}
          </Button>
          <Button
            disabled={deleteLoading}
            onClick={() => mutate()}
            color="danger"
            type="submit"
            data-testid="delete-rubric-button"
          >
            {I18n.t('Delete')}
          </Button>
        </Modal.Footer>
      </Modal>
    </View>
  )
}
