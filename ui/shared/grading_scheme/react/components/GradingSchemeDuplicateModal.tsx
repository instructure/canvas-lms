/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {Modal} from '@instructure/ui-modal'
import type {GradingScheme} from '@canvas/grading_scheme/gradingSchemeApiModel'
import {Heading} from '@instructure/ui-heading'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Flex} from '@instructure/ui-flex'
import {Button, CloseButton} from '@instructure/ui-buttons'

const I18n = useI18nScope('GradingSchemeViewModal')

export type GradingSchemeDuplicateModalProps = {
  open: boolean
  creatingGradingScheme: boolean
  selectedGradingScheme?: GradingScheme
  handleDuplicateScheme: (gradingScheme: GradingScheme) => void
  handleCloseDuplicateModal: () => void
}
const GradingSchemeDuplicateModal = ({
  open,
  selectedGradingScheme,
  creatingGradingScheme,
  handleDuplicateScheme,
  handleCloseDuplicateModal,
}: GradingSchemeDuplicateModalProps) => {
  if (!selectedGradingScheme) {
    return <></>
  }
  return (
    <Modal
      as="form"
      open={open}
      onDismiss={handleCloseDuplicateModal}
      label={I18n.t('Duplicate ') + selectedGradingScheme.title}
      size="small"
      data-testid="grading-scheme-duplicate-modal"
    >
      <Modal.Header>
        <CloseButton
          screenReaderLabel={I18n.t('Close')}
          placement="end"
          offset="small"
          onClick={handleCloseDuplicateModal}
          data-testid="grading-scheme-duplicate-modal-close-button"
        />
        <Heading data-testid="grading-scheme-duplicate-modal-title">
          <TruncateText>{I18n.t('Duplicate ') + selectedGradingScheme.title}</TruncateText>
        </Heading>
      </Modal.Header>
      <Modal.Body>{I18n.t('Are you sure you want to duplicate this grading scheme?')}</Modal.Body>
      <Modal.Footer>
        <Flex justifyItems="end">
          <Flex.Item>
            <Button onClick={handleCloseDuplicateModal} margin="0 x-small">
              {I18n.t('Cancel')}
            </Button>
            <Button
              onClick={() => handleDuplicateScheme(selectedGradingScheme)}
              color="primary"
              disabled={creatingGradingScheme}
              data-testid="grading-scheme-duplicate-modal-duplicate-button"
            >
              {I18n.t('Duplicate')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

export default GradingSchemeDuplicateModal
