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

import React, {useEffect, useRef, useState} from 'react'
import useBoolean from '@canvas/outcomes/react/hooks/useBoolean'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {Link} from '@instructure/ui-link'
import {IconPlusLine} from '@instructure/ui-icons'
import AddContentItem from './AddContentItem'
import GroupSelectionDrillDown from './GroupSelectionDrillDown'
import {useTargetGroupSelector} from '@canvas/outcomes/react/treeBrowser'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'

const I18n = useI18nScope('MoveOutcomesModal')

const getAncestorsIds = (targetGroup, collections) => {
  const ids = []
  let group = targetGroup && collections[targetGroup.id]

  while (group) {
    ids.push(group.id)
    group = collections[group.parentGroupId]
  }

  return ids
}

const TargetGroupSelector = ({groupId, starterGroupId, setTargetGroup, notifyGroupCreated}) => {
  const {isCourse} = useCanvasContext()
  const [expanded, setExpanded] = useState(false)
  const [hasExpanded, setHasExpanded] = useState(false)
  const [groupCreated, setGroupCreated, setGroupNotCreated] = useBoolean(false)
  const [labelRef, setLabelRef] = useState(null)
  const canCallSetTargetGroupWithStarterGroup = useRef(true)
  const {
    error,
    isLoading,
    collections,
    queryCollections,
    rootId,
    selectedGroupId,
    loadedGroups,
    createGroup,
  } = useTargetGroupSelector({skipGroupId: groupId, initialGroupId: starterGroupId})

  // When pass starterGroupId, call setTargetGroup with the group and it ancestors
  useEffect(() => {
    // only call setTargetGroup once, but only when collection object has info about the starterGroupId
    if (
      starterGroupId &&
      collections[starterGroupId] &&
      canCallSetTargetGroupWithStarterGroup.current
    ) {
      canCallSetTargetGroupWithStarterGroup.current = false
      const selectedGroupObject = collections[starterGroupId]
      setTargetGroup({
        targetGroup: selectedGroupObject,
        targetAncestorsIds: getAncestorsIds(selectedGroupObject, collections),
      })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [collections])

  useEffect(() => {
    if (expanded) {
      setHasExpanded(true)
    } else if (hasExpanded && labelRef && !groupCreated) {
      labelRef.focus()
    }
  }, [expanded, hasExpanded, labelRef, groupCreated])

  const onCreateGroupHandler = async (groupName, parentId) => {
    const newGroup = await createGroup(groupName, parentId)
    if (newGroup) {
      canCallSetTargetGroupWithStarterGroup.current = false
      queryCollections({id: newGroup.id, parentGroupId: parentId, shouldLoad: false})
      setTargetGroup({
        targetGroup: newGroup,
        targetAncestorsIds: getAncestorsIds(newGroup, collections),
      })

      // notify parent of group creation (if applicable)
      typeof notifyGroupCreated === 'function' && notifyGroupCreated()
    }
  }

  const onCollectionClick = (_, selectedCollection) => {
    canCallSetTargetGroupWithStarterGroup.current = false
    queryCollections(selectedCollection)
    const selectedGroupObject = collections[selectedCollection.id] || selectedCollection
    setTargetGroup({
      targetGroup: selectedGroupObject,
      targetAncestorsIds: getAncestorsIds(selectedGroupObject, collections),
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
                  setGroupCreated()
                  setExpanded(false)
                }}
                textInputInstructions={I18n.t('Enter new group name')}
                onHideHandler={() => {
                  setGroupNotCreated()
                  setExpanded(false)
                }}
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
  starterGroupId: PropTypes.string,
  setTargetGroup: PropTypes.func.isRequired,
  notifyGroupCreated: PropTypes.func,
}

export default TargetGroupSelector
