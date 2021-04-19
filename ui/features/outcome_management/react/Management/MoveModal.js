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
import I18n from 'i18n!MoveOutcomesModal'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import TreeBrowser from './TreeBrowser'
import {useGroupMoveModal} from '@canvas/outcomes/react/treeBrowser'
import AddContentItem from '../shared/AddContentItem'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import {addOutcomeGroup} from '@canvas/outcomes/graphql/Management'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const MoveModal = ({
  title,
  groupId,
  parentGroupId,
  type,
  isOpen,
  onMoveHandler,
  onCloseHandler
}) => {
  const {error, isLoading, collections, queryCollections, rootId} = useGroupMoveModal(groupId)
  const {contextType, contextId, rootOutcomeGroup} = useCanvasContext()
  const [targetGroup, setTargetGroup] = useState(null)

  const onCreateGroupHandler = async groupName => {
    try {
      // NOTE: For now, a newly added group will be added as a root outcome group.
      // Once OUT-4370 is complete, an add group component will be rendered at
      // each level of the tree. We will also need to remove
      // the FlashAlert and change this to add the newly created group to the Tree browser
      // or the new responsive designs.  The FlashAlert is merely for verification that
      // the save to the API was successful.
      await addOutcomeGroup(contextType, contextId, rootOutcomeGroup.id, groupName)
      showFlashAlert({
        message: I18n.t('"%{groupName}" has been created.', {groupName}),
        type: 'success'
      })
    } catch (err) {
      showFlashAlert({
        message: err.message
          ? I18n.t('An error occurred adding group "%{groupName}": %{message}', {
              groupName,
              message: err.message
            })
          : I18n.t('An error occurred adding group "%{groupName}"', {
              groupName
            }),
        type: 'error'
      })
    }
  }

  const onCollectionClick = (_, selectedGroupTreeCollectionObject) => {
    const selectedGroupObject = collections[selectedGroupTreeCollectionObject.id]
    if (
      groupId === selectedGroupObject.id ||
      selectedGroupObject.id.toString() === parentGroupId.toString()
    ) {
      setTargetGroup(null)
    } else {
      setTargetGroup(selectedGroupObject)
    }
  }

  const handleMove = () => {
    onMoveHandler(targetGroup)
  }

  return (
    <Modal
      open={isOpen}
      onDismiss={onCloseHandler}
      shouldReturnFocus
      size="medium"
      overflow="scroll"
      label={I18n.t('Move "%{title}"', {title})}
    >
      <Modal.Body>
        <View as="div" maxHeight="450px" height="450px" position="static">
          <Text size="medium" weight="bold">
            {type === 'outcome'
              ? I18n.t('Where would you like to move this outcome?')
              : I18n.t('Where would you like to move this group?')}
          </Text>
          <View as="div">
            {isLoading ? (
              <div style={{textAlign: 'center'}}>
                <Spinner renderTitle={I18n.t('Loading')} size="large" />
              </div>
            ) : error ? (
              <Text color="danger">
                {contextType === 'Course'
                  ? I18n.t('An error occurred while loading course outcomes: %{error}', {error})
                  : I18n.t('An error occurred while loading account outcomes: %{error}', {error})}
              </Text>
            ) : (
              <>
                <TreeBrowser
                  selectionType="single"
                  onCollectionToggle={queryCollections}
                  onCollectionClick={onCollectionClick}
                  collections={collections}
                  rootId={rootId}
                />
                <AddContentItem
                  labelInstructions={I18n.t('Create New Group')}
                  onSaveHandler={onCreateGroupHandler}
                  textInputInstructions={I18n.t('Enter new group name')}
                  showIcon
                />
              </>
            )}
          </View>
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
          disabled={!targetGroup}
          onClick={handleMove}
        >
          {I18n.t('Move')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

MoveModal.propTypes = {
  title: PropTypes.string.isRequired,
  groupId: PropTypes.string.isRequired,
  parentGroupId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  type: PropTypes.string.isRequired,
  isOpen: PropTypes.bool.isRequired,
  onMoveHandler: PropTypes.func.isRequired,
  onCloseHandler: PropTypes.func.isRequired
}

export default MoveModal
