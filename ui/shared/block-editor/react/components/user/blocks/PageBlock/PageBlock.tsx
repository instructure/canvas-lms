/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import React, {useCallback, useEffect} from 'react'
import {useEditor, useNode, type Node} from '@craftjs/core'
import {useClassNames, getScrollParent} from '../../../../utils'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

export type PageBlockProps = {
  children?: React.ReactNode
}

export const PageBlock = ({children}: PageBlockProps) => {
  const {enabled, actions} = useEditor(state => {
    // console.log('>>>pageblock')
    // console.log(JSON.parse(query.serialize()))
    return {
      enabled: state.options.enabled,
    }
  })
  const {
    connectors: {connect},
  } = useNode()
  const clazz = useClassNames(enabled, {empty: !children}, ['page-block'])

  // So that a section newly dropped in the editor gets selected,
  // RenderNode selects them on initial render. As a side-effect this also
  // happens as the initial json is loaded.
  // This unselects whatever was last and scrolls to the top.
  useEffect(() => {
    requestAnimationFrame(() => {
      actions.selectNode()
      const scrollingContainer = getScrollParent()
      scrollingContainer.scrollTo({top: 0, behavior: 'instant'})
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handlePagekey = useCallback(
    (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        actions.selectNode()
      }
    },
    [actions]
  )

  useEffect(() => {
    document.addEventListener('keydown', handlePagekey)
    return () => {
      document.removeEventListener('keydown', handlePagekey)
    }
  }, [handlePagekey])

  const handlePaste = useCallback((_e: React.ClipboardEvent<HTMLDivElement>) => {
    // Some day we should take what's on the clipboard and convert it into
    // the appropriate blocks.
    // console.log('>>> paste')
  }, [])

  return (
    <div
      className={clazz}
      data-placeholder="Add a section to start your page"
      ref={el => el && connect(el)}
      onPaste={handlePaste}
    >
      <a id="page-top" href="#page-top">
        <ScreenReaderContent>page top</ScreenReaderContent>
      </a>
      {children}
    </div>
  )
}

PageBlock.craft = {
  displayName: 'Page',
  rules: {
    canMoveIn: (incomingNodes: Node[]) => {
      return incomingNodes.every((incomingNode: Node) => incomingNode.data.custom.isSection)
    },
  },
}
