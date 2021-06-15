/*
 * Copyright (C) 2021 - present Instructure, Inc.

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
import PropTypes from 'prop-types'
import I18n from 'i18n!OutcomeManagement'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {List} from '@instructure/ui-list'
import {TruncateText} from '@instructure/ui-truncate-text'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {outcomeShape} from './shapes'

const OutcomeRemoveMultiModal = ({outcomes, isOpen, onCloseHandler, onRemoveHandler}) => {
  const nonRemovableOutcomeIds = Object.keys(outcomes).filter(_id => !outcomes[_id].canUnlink)
  const removableOutcomeIds = Object.keys(outcomes).filter(_id => outcomes[_id].canUnlink)
  let outcomeIds, modalLabel, modalMessage, modalButtons
  if (nonRemovableOutcomeIds.length > 0) {
    outcomeIds = nonRemovableOutcomeIds
    modalLabel = I18n.t('Please Try Again')
    modalMessage = I18n.t(
      {
        one: 'The following outcome cannot be removed because it is aligned to content. Please unselect it and try again.',
        other:
          'The following outcomes cannot be removed because they are aligned to content. Please unselect them and try again.'
      },
      {
        count: outcomeIds.length
      }
    )
    modalButtons = (
      <Button type="button" color="primary" margin="0 x-small 0 0" onClick={onCloseHandler}>
        {I18n.t('Close')}
      </Button>
    )
  } else {
    outcomeIds = removableOutcomeIds
    modalLabel = I18n.t('Remove Outcomes?')
    modalMessage = I18n.t(
      {
        one: 'Would you like to remove that outcome?',
        other: 'Would you like to remove these %{count} outcomes?'
      },
      {
        count: outcomeIds.length
      }
    )
    modalButtons = (
      <>
        <Button type="button" color="secondary" margin="0 x-small 0 0" onClick={onCloseHandler}>
          {I18n.t('Cancel')}
        </Button>
        <Button type="button" color="danger" margin="0 x-small 0 0" onClick={onRemoveHandler}>
          {I18n.t(
            {
              one: 'Remove Outcome',
              other: 'Remove Outcomes'
            },
            {
              count: outcomeIds.length
            }
          )}
        </Button>
      </>
    )
  }

  return (
    <Modal
      size="small"
      label={modalLabel}
      open={isOpen}
      shouldReturnFocus
      onDismiss={onCloseHandler}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Body overflow="scroll">
        <View as="div">
          <Text size="medium">{modalMessage}</Text>
        </View>
        <View as="div" maxHeight="16rem">
          <View as="div" padding={outcomeIds.length > 10 ? 'small 0 medium' : 'small 0 0'}>
            <List as="ul" size="medium" margin="0" isUnstyled>
              {outcomeIds.map((_id, idx) => (
                // its ok to use index in the key as the list is static
                // eslint-disable-next-line react/no-array-index-key
                <List.Item size="medium" key={`${_id}_${idx}`}>
                  <TruncateText>{outcomes[_id].title}</TruncateText>
                </List.Item>
              ))}
            </List>
          </View>
        </View>
      </Modal.Body>
      <Modal.Footer>{modalButtons}</Modal.Footer>
    </Modal>
  )
}

OutcomeRemoveMultiModal.propTypes = {
  outcomes: PropTypes.objectOf(outcomeShape).isRequired,
  isOpen: PropTypes.bool.isRequired,
  onCloseHandler: PropTypes.func.isRequired,
  onRemoveHandler: PropTypes.func.isRequired
}

export default OutcomeRemoveMultiModal
