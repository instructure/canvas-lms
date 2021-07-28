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
import {IconArrowOpenDownLine, IconArrowOpenEndLine} from '@instructure/ui-icons'
import {TreeBrowser as InstuiTreeBrowser} from '@instructure/ui-tree-browser'
import {isRTL} from '@canvas/i18n/rtlHelper'

const TreeBrowser = ({
  collections,
  rootId,
  onCollectionToggle,
  onCollectionClick,
  selectionType,
  showRootCollection,
  defaultExpandedIds
}) => {
  const margin = '0.8em'
  const iconMargin = isRTL() ? {marginLeft: margin} : {marginRight: margin}
  return (
    <InstuiTreeBrowser
      selectionType={selectionType}
      margin="small 0 0"
      collections={collections}
      items={{}}
      onCollectionToggle={onCollectionToggle}
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
  showRootCollection: false
}

TreeBrowser.propTypes = {
  onCollectionToggle: PropTypes.func.isRequired,
  onCollectionClick: PropTypes.func,
  collections: PropTypes.object.isRequired,
  rootId: PropTypes.string.isRequired,
  selectionType: PropTypes.string,
  showRootCollection: PropTypes.bool,
  defaultExpandedIds: PropTypes.arrayOf(PropTypes.string)
}

export default TreeBrowser
