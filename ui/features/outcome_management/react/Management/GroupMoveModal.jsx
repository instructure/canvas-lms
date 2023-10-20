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

import React, {useState} from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import TargetGroupSelector from '../shared/TargetGroupSelector'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {UPDATE_LEARNING_OUTCOME_GROUP} from '@canvas/outcomes/graphql/Management'
import {useMutation} from 'react-apollo'

const I18n = useI18nScope('MoveOutcomesModal')

const GroupMoveModal = ({groupId, groupTitle, parentGroup, isOpen, onCloseHandler, onSuccess}) => {
  const [targetGroup, setTargetGroup] = useState(parentGroup)
  const [moveOutcomeGroup] = useMutation(UPDATE_LEARNING_OUTCOME_GROUP)
  const disableGroupMove = parentGroup.id === targetGroup.id

  const onMoveGroupHandler = () => {
    ;(async () => {
      try {
        const result = await moveOutcomeGroup({
          variables: {
            input: {
              id: groupId,
              parentOutcomeGroupId: targetGroup.id,
            },
          },
        })

        const movedOutcomeGroup = result.data?.updateLearningOutcomeGroup?.learningOutcomeGroup
        const errorMessage = result.data?.updateLearningOutcomeGroup?.errors?.[0]?.message
        if (!movedOutcomeGroup) throw new Error(errorMessage)

        showFlashAlert({
          message: I18n.t('"%{groupTitle}" was moved to "%{newGroupTitle}".', {
            groupTitle,
            newGroupTitle: targetGroup.name,
          }),
          type: 'success',
        })
        onSuccess()
      } catch (err) {
        showFlashAlert({
          message: I18n.t('An error occurred while moving this group. Please try again.'),
          type: 'error',
        })
      }
    })()
    onCloseHandler()
  }

  return (
    <Modal
      open={isOpen}
      onDismiss={onCloseHandler}
      shouldReturnFocus={true}
      size="medium"
      overflow="scroll"
      label={I18n.t('Move "%{groupTitle}"', {groupTitle})}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Body>
        <View as="div" maxHeight="450px" height="450px" position="static">
          <Text size="medium" weight="bold">
            {I18n.t('Where would you like to move this group?')}
          </Text>
          <TargetGroupSelector
            groupId={groupId}
            // eslint-disable-next-line @typescript-eslint/no-shadow
            setTargetGroup={({targetGroup}) => setTargetGroup(targetGroup)}
            starterGroupId={parentGroup.id}
          />
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button type="button" color="secondary" margin="0 x-small 0 0" onClick={onCloseHandler}>
          {I18n.t('Cancel')}
        </Button>
        <Button
          type="button"
          color="primary"
          margin="0 x-small 0 0"
          disabled={disableGroupMove}
          onClick={onMoveGroupHandler}
        >
          {I18n.t('Move')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

GroupMoveModal.propTypes = {
  groupId: PropTypes.string.isRequired,
  groupTitle: PropTypes.string.isRequired,
  isOpen: PropTypes.bool.isRequired,
  onCloseHandler: PropTypes.func.isRequired,
  onSuccess: PropTypes.func.isRequired,
  parentGroup: PropTypes.object.isRequired,
}

GroupMoveModal.defaultProps = {
  onSuccess: () => {},
}

export default GroupMoveModal
