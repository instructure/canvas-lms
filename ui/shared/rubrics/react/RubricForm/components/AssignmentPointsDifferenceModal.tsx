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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'

const I18n = createI18nScope('rubrics-criterion-modal')

type AssignmentPointsDifferenceModalProps = {
  isOpen: boolean
  onChange: () => void
  onLeaveDifferent: () => void
  onDismiss: () => void
  assignmentPoints: number
  rubricPoints: number
}
export const AssignmentPointsDifferenceModal = ({
  isOpen,
  onChange,
  onLeaveDifferent,
  onDismiss,
  assignmentPoints,
  rubricPoints,
}: AssignmentPointsDifferenceModalProps) => {
  const pointRatio = I18n.toPercentage((rubricPoints / assignmentPoints) * 100, {
    precision: 0,
  })

  const confirmationMessage = I18n.t(
    `Leaving the assignment's total points at %{assignmentPoints} and the rubric's total points at %{rubricPoints}
    will result in a maximum possible score of %{pointRatio} for student submissions graded with the rubric.`,
    {
      assignmentPoints,
      rubricPoints,
      pointRatio,
    },
  )

  return (
    <Modal
      open={isOpen}
      onDismiss={onDismiss}
      size="small"
      label={I18n.t('Rubric Points Difference Dialog')}
      shouldCloseOnDocumentClick={true}
      data-testid="rubric-points-difference-modal"
    >
      <Modal.Header>
        <CloseButton placement="end" offset="small" onClick={onDismiss} screenReaderLabel="Close" />
        <Heading>{I18n.t('Confirm to continue')}</Heading>
      </Modal.Header>
      <Modal.Body>{confirmationMessage}</Modal.Body>
      <Modal.Footer>
        <Button
          data-testid="change-points-button"
          color="primary"
          onClick={onChange}
          margin="0 x-small 0 0"
        >
          {I18n.t('Change')}
        </Button>
        <Button data-testid="leave-different-button" color="primary" onClick={onLeaveDifferent}>
          {I18n.t('Leave Different')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
