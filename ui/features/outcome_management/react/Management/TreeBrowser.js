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
import React, {useState, useCallback} from 'react'
import PropTypes from 'prop-types'
import {IconArrowOpenDownLine, IconArrowOpenEndLine, IconPlusLine} from '@instructure/ui-icons'
import {TreeBrowser as InstuiTreeBrowser} from '@instructure/ui-tree-browser'
import AddContentItem from '../shared/AddContentItem'
import {isRTL} from '@canvas/i18n/rtlHelper'
import I18n from 'i18n!OutcomeManagement'

const KEYCODES = {
  ENTER: 13,
  SPACE: 32
}

const contentItem = ({
  id,
  showAddContent,
  hideAddContent,
  expanded,
  containerRefs,
  onRefChange,
  onCreateGroup
}) => {
  const onClick = e => {
    e.stopPropagation()
    if (!expanded) {
      showAddContent(id)
    }
  }

  const onKeyDown = e => {
    // enter or space should expand the node
    if ((e.keyCode === KEYCODES.ENTER || e.keyCode === KEYCODES.SPACE) && !expanded) {
      e.stopPropagation()
      showAddContent(id)
    } else if (expanded) {
      // prevent changes in text input from propagating up to the collection
      e.stopPropagation()
    }
  }

  const focus = () => {
    setTimeout(() => containerRefs[id].focus(), 500)
  }

  const handleHide = e => {
    e.stopPropagation()
    hideAddContent()
    focus()
  }

  const handleSave = groupName => {
    onCreateGroup(groupName, id)
    hideAddContent()
    focus()
  }

  return (
    <InstuiTreeBrowser.Node
      containerRef={el => onRefChange(el, id)}
      onKeyDown={onKeyDown}
      onClick={onClick}
      itemIcon={expanded ? null : IconPlusLine}
      variant="indent"
    >
      {expanded ? (
        <AddContentItem
          textInputInstructions={I18n.t('Enter new group name')}
          labelInstructions={I18n.t('Create new group')}
          onHideHandler={handleHide}
          onSaveHandler={handleSave}
        />
      ) : (
        I18n.t('Create New Group')
      )}
    </InstuiTreeBrowser.Node>
  )
}

const TreeBrowser = ({
  collections: allCollections,
  rootId,
  onCollectionToggle,
  onCollectionClick,
  selectionType,
  showRootCollection,
  defaultExpandedIds,
  onCreateGroup,
  loadedGroups
}) => {
  const [expandedContentId, setExpandedContentId] = useState(null)
  const [containerRefs, setContainerRefs] = useState({})
  const margin = '0.8em'
  const iconMargin = isRTL() ? {marginLeft: margin} : {marginRight: margin}

  const onRefChange = useCallback((node, id) => {
    setContainerRefs(prevState => ({
      ...prevState,
      [id]: node
    }))
  }, [])

  const hideAddContent = () => {
    setExpandedContentId(null)
  }

  const showAddContent = id => {
    setExpandedContentId(id)
  }

  const handleCollectionToggle = collection => {
    hideAddContent()
    onCollectionToggle(collection)
  }

  const collections = Object.values(allCollections)
    .map(col => ({
      ...col,
      renderAfterItems:
        loadedGroups.includes(col.id) &&
        contentItem({
          id: col.id,
          hideAddContent,
          showAddContent,
          expanded: expandedContentId === col.id,
          containerRefs,
          onRefChange,
          onCreateGroup
        })
    }))
    .reduce((dict, collection) => {
      dict[collection.id] = collection
      return dict
    }, {})

  return (
    <InstuiTreeBrowser
      selectionType={selectionType}
      margin="small 0 0"
      collections={collections}
      items={{}}
      onCollectionToggle={handleCollectionToggle}
      onCollectionClick={onCollectionClick}
      collectionIcon={() => (
        <span style={{display: 'inline-block', ...iconMargin}}>
          <IconArrowOpenEndLine size="x-small" />
        </span>
      )}
      collectionIconExpanded={() => (
        <span style={{display: 'inline-block', ...iconMargin}}>
          <IconArrowOpenDownLine size="x-small" />
        </span>
      )}
      rootId={rootId}
      showRootCollection={showRootCollection}
      variant="indent"
      defaultExpanded={defaultExpandedIds}
    />
  )
}

TreeBrowser.defaultProps = {
  onCollectionToggle: () => {},
  onCollectionClick: () => {},
  collections: {},
  rootId: '0',
  selectionType: 'single',
  showRootCollection: false,
  defaultExpandedIds: [],
  loadedGroups: [],
  onCreateGroup: () => {}
}

TreeBrowser.propTypes = {
  onCollectionToggle: PropTypes.func.isRequired,
  onCollectionClick: PropTypes.func,
  collections: PropTypes.object.isRequired,
  rootId: PropTypes.string.isRequired,
  selectionType: PropTypes.string,
  showRootCollection: PropTypes.bool,
  defaultExpandedIds: PropTypes.arrayOf(PropTypes.string),
  loadedGroups: PropTypes.arrayOf(PropTypes.string),
  onCreateGroup: PropTypes.func
}

export default TreeBrowser
