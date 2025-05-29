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
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'

const I18n = createI18nScope('page_editor')

export const AddBlockModal = (props: {
  open: boolean
  onDismiss: () => void
  onAddBlock: (type: string) => void
}) => {
  return (
    <Modal
      label={I18n.t('Add new block')}
      size="large"
      open={props.open}
      onDismiss={props.onDismiss}
    >
      <Modal.Header>
        <Flex justifyItems="space-between">
          <Heading variant="titleSection">{I18n.t('Add new block')}</Heading>
          <CloseButton
            screenReaderLabel={I18n.t('Close')}
            onClick={props.onDismiss}
            data-testid="add-modal-close-button"
          />
        </Flex>
      </Modal.Header>
      <Modal.Body></Modal.Body>
      <Modal.Footer>
        <Flex justifyItems="end" gap="small">
          <Button color="secondary" onClick={props.onDismiss} data-testid="add-modal-cancel-button">
            {I18n.t('Cancel')}
          </Button>
          <Button
            color="primary"
            onClick={() => {
              props.onAddBlock('new_block')
              props.onDismiss()
            }}
          >
            {I18n.t('Add to page')}
          </Button>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}
