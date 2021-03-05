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
import Modal from '../../shared/components/InstuiModal'
import {useCanvasContext} from '../shared/hooks'
import {showFlashAlert} from '../../shared/FlashAlert'
import {removeOutcomeGroup} from './api'

const GroupRemoveModal = ({groupId, isOpen, onCloseHandler}) => {
  const {contextType, contextId} = useCanvasContext()
  const isAccount = contextType === 'Account'
  const onRemoveGroupHandler = async () => {
    onCloseHandler()
    try {
      const result = await removeOutcomeGroup(contextType, contextId, groupId)
      if (result?.status === 200) {
        showFlashAlert({
          message: isAccount
            ? I18n.t('This group was successfully removed from this account.')
            : I18n.t('This group was successfully removed from this course.'),
          type: 'success'
        })
      } else {
        throw Error()
      }
    } catch (err) {
      showFlashAlert({
        message: I18n.t('An error occurred while making a network request.'),
        type: 'error'
      })
    }
  }

  return (
    <Modal
      size="small"
      label={I18n.t('Remove Group?')}
      open={isOpen}
      onDismiss={onCloseHandler}
      shouldReturnFocus
    >
      <Modal.Body>
        <View as="div" padding="small 0">
          <Text size="medium">
            {isAccount
              ? I18n.t(
                  'Are you sure that you want to remove this group and all of its content from your account?'
                )
              : I18n.t(
                  'Are you sure that you want to remove this group and all of its content from your course?'
                )}
          </Text>
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button type="button" color="secondary" margin="0 x-small 0 0" onClick={onCloseHandler}>
          {I18n.t('Cancel')}
        </Button>
        <Button type="button" color="danger" margin="0 x-small 0 0" onClick={onRemoveGroupHandler}>
          {I18n.t('Remove Group')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

GroupRemoveModal.propTypes = {
  groupId: PropTypes.string.isRequired,
  isOpen: PropTypes.bool.isRequired,
  onCloseHandler: PropTypes.func.isRequired
}

export default GroupRemoveModal
