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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {removeOutcomeGroup} from '@canvas/outcomes/graphql/Management'

const I18n = useI18nScope('OutcomeManagement')

const GroupRemoveModal = ({groupId, groupTitle, isOpen, onCloseHandler, onSuccess}) => {
  const {contextType, contextId} = useCanvasContext()
  const isAccount = contextType === 'Account'
  const onRemoveGroupHandler = async () => {
    onCloseHandler()
    try {
      const result = await removeOutcomeGroup(contextType, contextId, groupId)
      if (result?.status === 200) {
        onSuccess()
        showFlashAlert({
          message: I18n.t('This group was successfully removed.'),
          type: 'success',
        })
      } else {
        throw Error()
      }
    } catch (err) {
      const message = err?.response?.data?.match(
        /cannot be deleted because it is aligned to content/
      )
        ? I18n.t(
            'An error occurred while removing this group: "%{groupTitle}" contains one or ' +
              'more Outcomes that are currently aligned to content.',
            {
              groupTitle,
            }
          )
        : I18n.t('An error occurred while removing this group. Please try again.')

      showFlashAlert({
        message,
        type: 'error',
      })
    }
  }

  return (
    <Modal
      size="small"
      label={I18n.t('Remove Group?')}
      open={isOpen}
      onDismiss={onCloseHandler}
      shouldReturnFocus={true}
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
  groupTitle: PropTypes.string.isRequired,
  isOpen: PropTypes.bool.isRequired,
  onCloseHandler: PropTypes.func.isRequired,
  onSuccess: PropTypes.func.isRequired,
}

export default GroupRemoveModal
