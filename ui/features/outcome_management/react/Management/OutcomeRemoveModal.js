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
import {useMutation} from 'react-apollo'
import PropTypes from 'prop-types'
import I18n from 'i18n!OutcomeManagement'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {DELETE_OUTCOME_LINKS} from '@canvas/outcomes/graphql/Management'

const OutcomeRemoveModal = ({outcomeLinkId, isOpen, onCloseHandler}) => {
  const {contextType} = useCanvasContext()
  const isAccount = contextType === 'Account'
  const [deleteOutcomeLinks] = useMutation(DELETE_OUTCOME_LINKS, {
    onCompleted: _data => {
      if (_data.deleteOutcomeLinks?.deletedOutcomeLinkIds.length === 0)
        throw new Error(_data.deleteOutcomeLinks?.errors?.[0]?.message)

      showFlashAlert({
        message: isAccount
          ? I18n.t('This outcome was successfully removed from this account.')
          : I18n.t('This outcome was successfully removed from this course.'),
        type: 'success'
      })
    },
    onError: _err => {
      _err.message = _err.message.match(/cannot be deleted because it is aligned to content/)
        ? I18n.t('Outcome cannot be removed because it is aligned to content')
        : _err.message
      showFlashAlert({
        message: _err.message
          ? I18n.t('An error occurred while removing the outcome: %{message}', {
              message: _err.message
            })
          : I18n.t('An error occurred while removing the outcome.'),
        type: 'error'
      })
    },
    variables: {
      ids: [outcomeLinkId]
    }
  })

  const onRemoveOutcomeHandler = () => {
    deleteOutcomeLinks()
    onCloseHandler()
  }

  return (
    <Modal
      size="small"
      label={I18n.t('Remove Outcome?')}
      open={isOpen}
      shouldReturnFocus
      onDismiss={onCloseHandler}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Body>
        <View as="div" padding="small 0">
          <Text size="medium">
            {isAccount
              ? I18n.t('Are you sure that you want to remove this outcome from this account?')
              : I18n.t('Are you sure that you want to remove this outcome from this course?')}
          </Text>
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button type="button" color="secondary" margin="0 x-small 0 0" onClick={onCloseHandler}>
          {I18n.t('Cancel')}
        </Button>
        <Button
          type="button"
          color="danger"
          margin="0 x-small 0 0"
          onClick={onRemoveOutcomeHandler}
        >
          {I18n.t('Remove Outcome')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

OutcomeRemoveModal.propTypes = {
  outcomeLinkId: PropTypes.string.isRequired,
  isOpen: PropTypes.bool.isRequired,
  onCloseHandler: PropTypes.func.isRequired
}

export default OutcomeRemoveModal
