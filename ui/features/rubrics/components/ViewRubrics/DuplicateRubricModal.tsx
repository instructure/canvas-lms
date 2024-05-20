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
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {Alert} from '@instructure/ui-alerts'
import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {duplicateRubric} from '../../queries/ViewRubricQueries'
import type {RubricCriterion} from '@canvas/rubrics/react/types/rubric'

const I18n = useI18nScope('rubrics-duplicate-modal')

export type DuplicateRubricModalProps = {
  id?: string
  title: string
  hidePoints?: boolean
  accountId?: string
  courseId?: string
  criteria?: RubricCriterion[]
  pointsPossible: number
  buttonDisplay?: string
  ratingOrder?: string
  isOpen: boolean
  onDismiss: () => void
  setPopoverIsOpen: (isOpen: boolean) => void
}
export const DuplicateRubricModal = ({
  id,
  title,
  hidePoints,
  accountId,
  courseId,
  criteria,
  pointsPossible,
  buttonDisplay,
  ratingOrder,
  isOpen,
  onDismiss,
  setPopoverIsOpen,
}: DuplicateRubricModalProps) => {
  const {
    isLoading: duplicateLoading,
    isError: duplicateError,
    mutate,
  } = useMutation({
    mutationFn: async () =>
      duplicateRubric({
        id,
        accountId,
        courseId,
        title,
        hidePoints,
        criteria,
        pointsPossible,
        buttonDisplay,
        ratingOrder,
      }),
    mutationKey: ['duplicate-rubric'],
    onSuccess: async () => {
      showFlashSuccess(I18n.t('Rubric duplicated successfully'))()
      const queryKey = accountId ? `accountRubrics-${accountId}` : `courseRubrics-${courseId}`
      await queryClient.invalidateQueries([`fetch-rubric-${id}`], {}, {cancelRefetch: true})
      await queryClient.invalidateQueries([queryKey], undefined, {cancelRefetch: true})
      onDismiss()
      setPopoverIsOpen(false)
    },
  })

  return (
    <View as="div">
      {duplicateError && (
        <Alert
          variant="error"
          liveRegionPoliteness="polite"
          isLiveRegionAtomic={true}
          liveRegion={getLiveRegion}
          timeout={3000}
        >
          <Text weight="bold">{I18n.t('There was an error duplicating the rubric.')}</Text>
        </Alert>
      )}
      <Modal
        open={isOpen}
        onDismiss={onDismiss}
        label={I18n.t('Duplicate Rubric Modal')}
        shouldCloseOnDocumentClick={true}
        size="small"
        data-testid="duplicate-rubric-modal"
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={onDismiss}
            screenReaderLabel={I18n.t('Close')}
            data-testid="close-duplicate-rubric-modal-button"
          />
          <Heading>{I18n.t('Duplicate %{title}', {title})}</Heading>
        </Modal.Header>
        <Modal.Body>{I18n.t('Are you sure you want to duplicate this rubric?')}</Modal.Body>
        <Modal.Footer>
          <Button
            onClick={onDismiss}
            margin="0 x-small 0 0"
            data-testid="cancel-duplicate-rubric-modal-button"
          >
            {I18n.t('Cancel')}
          </Button>
          <Button
            disabled={duplicateLoading}
            onClick={() => mutate()}
            type="submit"
            color="primary"
            data-testid="duplicate-rubric-button"
          >
            {I18n.t('Duplicate')}
          </Button>
        </Modal.Footer>
      </Modal>
    </View>
  )
}
