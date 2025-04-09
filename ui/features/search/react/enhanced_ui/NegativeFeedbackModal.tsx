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

import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {TextArea} from '@instructure/ui-text-area'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('SmartSearch')

interface Props {
  isOpen: boolean
  onSubmit: (comment: string) => void
  onClose: () => void
}

export default function NegativeFeedbackModal(props: Props) {
  const [comment, setComment] = useState('')

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
          <Heading>{I18n.t('Feedback Noted')}</Heading>
          <CloseButton
            placement="end"
            offset="small"
            onClick={props.onClose}
            screenReaderLabel={I18n.t('Close')}
          />
        </Modal.Header>
        <Modal.Body>
          <View as="div" margin="0 0 medium 0">
            <Text>
              {I18n.t(
                "Thank you for your feedback. We're sorry to hear that these results didn't meet your expectations. Your input is crucial for improving our semantic search algorithms, and we'll use it to enhance the accuracy and relevance of future searches.",
              )}
            </Text>
          </View>
          <TextArea
            maxHeight="6em"
            height="6em"
            label={I18n.t('Additional Feedback')}
            placeholder={I18n.t('Let us know how we can improve')}
            onChange={e => setComment(e.target.value)}
          />
        </Modal.Body>
        <Modal.Footer>
          <Button data-testid="nf-close" onClick={props.onClose} margin="0 x-small 0 0">
            {I18n.t('Close')}
          </Button>
          <Button data-testid="nf-submit" color="primary" onClick={() => props.onSubmit(comment)}>
            {I18n.t('Submit')}
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  )
}
