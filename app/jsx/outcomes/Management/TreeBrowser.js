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
import {isRTL} from 'jsx/shared/helpers/rtlHelper'

const TreeBrowser = ({collections, rootId, onCollectionToggle}) => {
  const margin = '0.8em'
  const iconMargin = isRTL() ? {marginLeft: margin} : {marginRight: margin}
  return (
    <InstuiTreeBrowser
      margin="small 0 0"
      collections={collections}
      items={{}}
      onCollectionToggle={onCollectionToggle}
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
      showRootCollection={false}
    />
  )
}

TreeBrowser.defaultProps = {
  onCollectionToggle: () => {},
  collections: {},
  rootId: 0
}

TreeBrowser.propTypes = {
  onCollectionToggle: PropTypes.func.isRequired,
  collections: PropTypes.object.isRequired,
  rootId: PropTypes.number.isRequired
}

export default TreeBrowser
