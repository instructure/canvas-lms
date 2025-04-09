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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {IconLikeLine} from '@instructure/ui-icons'
import {Heading} from '@instructure/ui-heading'
import {Button, CloseButton} from '@instructure/ui-buttons'

const I18n = createI18nScope('SmartSearch')

interface Props {
  isOpen: boolean
  onClose: () => void
}

export default function PositiveFeedbackModal(props: Props) {
  return (
    <>
      <Modal
        open={props.isOpen}
        onDismiss={props.onClose}
        size="small"
        label={I18n.t('Feedback Received')}
        shouldReturnFocus={true}
      >
        <Modal.Header>
          <Heading>
            <IconLikeLine />
            &ensp;
            {I18n.t('Feedback Received')}
          </Heading>
          <CloseButton
            placement="end"
            offset="small"
            onClick={props.onClose}
            screenReaderLabel={I18n.t('Close')}
          />
        </Modal.Header>
        <Modal.Body>
          {I18n.t(
            "Thank you for your feedback on our semantic search results! We've recorded your response and will use it to refine our algorithms, ensuring more accurate and relevant results tailored to your needs in the future.",
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button data-testid="pf-close" onClick={props.onClose}>
            {I18n.t('Close')}
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  )
}
