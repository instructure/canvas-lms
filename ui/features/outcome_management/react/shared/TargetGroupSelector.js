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

import React, {useEffect, useState} from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!MoveOutcomesModal'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {Link} from '@instructure/ui-link'
import {IconPlusLine} from '@instructure/ui-icons'
import AddContentItem from './AddContentItem'
import GroupSelectionDrillDown from './GroupSelectionDrillDown'
import {useTargetGroupSelector} from '@canvas/outcomes/react/treeBrowser'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'

const getAncestorsIds = (targetGroup, collections) => {
  const ids = []
  let group = targetGroup && collections[targetGroup.id]

  while (group) {
    ids.push(group.id)
    group = collections[group.parentGroupId]
  }

  return ids
}

const TargetGroupSelector = ({groupId, setTargetGroup}) => {
  const {isCourse} = useCanvasContext()
  const [expanded, setExpanded] = useState(false)
  const [hasExpanded, setHasExpanded] = useState(false)
  const [labelRef, setLabelRef] = useState(null)
  const {
    error,
    isLoading,
    collections,
    queryCollections,
    rootId,
    selectedGroupId,
    loadedGroups,
    createGroup
  } = useTargetGroupSelector(groupId)

  useEffect(() => {
    if (expanded) {
      setHasExpanded(true)
    } else if (hasExpanded && labelRef) {
      labelRef.focus()
    }
  }, [expanded, hasExpanded, labelRef])

  const onCreateGroupHandler = async (groupName, parentId) => {
    const newGroup = await createGroup(groupName, parentId)
    if (newGroup) {
      queryCollections({id: newGroup.id, parentGroupId: parentId, shouldLoad: false})
      setTargetGroup({
        targetGroup: newGroup,
        targetAncestorsIds: getAncestorsIds(newGroup, collections)
      })
    }
  }

  const onCollectionClick = (_, selectedCollection) => {
    queryCollections(selectedCollection)
    const selectedGroupObject = collections[selectedCollection.id]
    setTargetGroup({
      targetGroup: selectedGroupObject,
      targetAncestorsIds: getAncestorsIds(selectedGroupObject, collections)
    })
  }

  return (
    <View as="div">
      {isLoading ? (
        <div style={{textAlign: 'center'}}>
          <Spinner renderTitle={I18n.t('Loading')} size="large" />
        </div>
      ) : error && Object.keys(collections).length === 0 ? (
        <Text color="danger" data-testid="loading-error">
          {isCourse
            ? I18n.t('An error occurred while loading course outcomes: %{error}', {error})
            : I18n.t('An error occurred while loading account outcomes: %{error}', {error})}
        </Text>
      ) : (
        <>
          <GroupSelectionDrillDown
            onCollectionClick={onCollectionClick}
            collections={collections}
            selectedGroupId={selectedGroupId}
            rootId={rootId}
            movingGroupId={groupId}
            loadedGroups={loadedGroups}
          />
          {loadedGroups.includes(selectedGroupId || rootId) &&
            (expanded ? (
              <AddContentItem
                labelInstructions={I18n.t('Create new group')}
                onSaveHandler={name => {
                  const parentId = selectedGroupId || rootId
                  onCreateGroupHandler(name, parentId)
                  setExpanded(false)
                }}
                textInputInstructions={I18n.t('Enter new group name')}
                onHideHandler={() => setExpanded(false)}
              />
            ) : (
              <View as="div" margin="xx-small none small">
                <Link
                  isWithinText={false}
                  renderIcon={<IconPlusLine size="x-small" />}
                  onClick={() => setExpanded(true)}
                  size="x-small"
                  elementRef={elem => setLabelRef(elem)}
                >
                  {I18n.t('Create New Group')}
                </Link>
              </View>
            ))}
        </>
      )}
    </View>
  )
}

TargetGroupSelector.propTypes = {
  groupId: PropTypes.string,
  setTargetGroup: PropTypes.func.isRequired
}

export default TargetGroupSelector
