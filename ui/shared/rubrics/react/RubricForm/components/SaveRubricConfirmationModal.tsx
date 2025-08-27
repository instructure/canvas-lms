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

type SaveRubricConfirmationModalProps = {
  isOpen: boolean
  onConfirm: () => void
  onDismiss: () => void
}
export const SaveRubricConfirmationModal = ({
  isOpen,
  onConfirm,
  onDismiss,
}: SaveRubricConfirmationModalProps) => {
  return (
    <Modal
      open={isOpen}
      onDismiss={onDismiss}
      size="small"
      label={I18n.t('Rubric Save Confirmation Dialog')}
      shouldCloseOnDocumentClick={true}
      data-testid="rubric-save-confirmation-modal"
    >
      <Modal.Header>
        <CloseButton placement="end" offset="small" onClick={onDismiss} screenReaderLabel="Close" />
        <Heading>{I18n.t('Confirm to continue')}</Heading>
      </Modal.Header>
      <Modal.Body>
        {I18n.t(
          'This rubric has already been used for grading. Saving changes may alter student scores or grading history. Are you sure you want to proceed?',
        )}
      </Modal.Body>
      <Modal.Footer>
        <Button data-testid="save-confirm-cancel-btn" onClick={onDismiss} margin="0 x-small 0 0">
          {I18n.t('Cancel')}
        </Button>
        <Button data-testid="save-confirm-btn" color="primary" onClick={onConfirm}>
          {I18n.t('Save')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
