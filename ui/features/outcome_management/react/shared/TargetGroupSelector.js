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
import I18n from 'i18n!MoveOutcomesModal'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import TreeBrowser from '../Management/TreeBrowser'
import AddContentItem from './AddContentItem'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useGroupMoveModal} from '@canvas/outcomes/react/treeBrowser'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import {addOutcomeGroup} from '@canvas/outcomes/graphql/Management'

const TargetGroupSelector = ({groupId, parentGroupId, setTargetGroup}) => {
  const {contextType, contextId, rootOutcomeGroup} = useCanvasContext()
  const {error, isLoading, collections, queryCollections, rootId} = useGroupMoveModal(groupId)

  const onCreateGroupHandler = async groupName => {
    try {
      // NOTE: For now, a newly added group will be added as a root outcome group.
      // Once OUT-4370 is complete, an add group component will be rendered at
      // each level of the tree. We will also need to remove
      // the FlashAlert and change this to add the newly created group to the Tree browser
      // or the new responsive designs. The FlashAlert is merely for verification that
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

  const onCollectionClick = (_, selectedCollection) => {
    const selectedGroupObject = collections[selectedCollection.id]
    const targetGroup =
      groupId && (groupId === selectedGroupObject.id || selectedGroupObject.id === parentGroupId)
        ? null
        : selectedGroupObject
    setTargetGroup(targetGroup)
  }

  return (
    <View as="div">
      {isLoading ? (
        <div style={{textAlign: 'center'}}>
          <Spinner renderTitle={I18n.t('Loading')} size="large" />
        </div>
      ) : error && Object.keys(collections).length === 0 ? (
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
            showRootCollection
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
  )
}

TargetGroupSelector.propTypes = {
  groupId: PropTypes.string,
  parentGroupId: PropTypes.string,
  setTargetGroup: PropTypes.func.isRequired
}

export default TargetGroupSelector
