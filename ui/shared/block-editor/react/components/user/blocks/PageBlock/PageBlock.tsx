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
import React, {useCallback, useEffect, useRef, useState} from 'react'
import {useEditor, useNode, type Node} from '@craftjs/core'
import {useClassNames, getScrollParent} from '../../../../utils'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {KBNavigator} from '../../../../utils/KBNavigator'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

export type PageBlockProps = {
  children?: React.ReactNode
}

export const PageBlock = ({children}: PageBlockProps) => {
  const {enabled, actions, query, selectedNodeId} = useEditor(state => {
    return {
      enabled: state.options.enabled,
      selectedNodeId: state.events.selected.values().next().value,
    }
  })
  const {
    connectors: {connect},
    selected,
  } = useNode((n: Node) => {
    return {
      selected: n.events.selected,
    }
  })
  const [kbnav] = useState(enabled ? new KBNavigator() : null)
  const clazz = useClassNames(enabled, {empty: !children}, ['block', 'page-block'])
  const pageRef = useRef<HTMLDivElement | null>(null)

  // So that a section newly dropped in the editor gets selected,
  // RenderNode selects them on initial render. As a side-effect this also
  // happens as the initial json is loaded.
  // This unselects whatever was last and scrolls to the top.
  useEffect(() => {
    if (enabled) {
      requestAnimationFrame(() => {
        actions.selectNode()
        const scrollingContainer = getScrollParent()
        scrollingContainer.scrollTo({top: 0, behavior: 'instant'})
      })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handlePagekey: React.KeyboardEventHandler<HTMLDivElement> = useCallback(
    e => {
      if (e.key === 'Escape') {
        actions.selectNode('ROOT')
        ;(document.querySelector('.page-block') as HTMLElement)?.focus()
      } else if (e.key === 'z') {
        if (e.ctrlKey || e.metaKey) {
          if (e.shiftKey) {
            actions.history.redo()
          } else {
            actions.history.undo()
          }
        }
      } else if (kbnav) {
        // @ts-expect-error
        kbnav.key(e, actions, query, selectedNodeId)
      }
    },
    [actions, kbnav, query, selectedNodeId],
  )

  // Per the w3c:
  // When a single-select tree receives focus:
  // If none of the nodes are selected before the tree receives focus, focus is set on the first node.
  // If a node is selected before the tree receives focus, focus is set on the selected node.
  const handleFocus: React.FocusEventHandler<HTMLDivElement> = useCallback(
    (e: React.FocusEvent) => {
      if (enabled) {
        if (e.target === pageRef.current) {
          e.preventDefault()
          actions.selectNode('ROOT')
          const scrollingContainer = getScrollParent()
          scrollingContainer.scrollTo({top: 0, behavior: 'instant'})
        }
      }
    },
    [actions, enabled],
  )

  const handlePaste = useCallback((_e: React.ClipboardEvent<HTMLDivElement>) => {
    // Some day we should take what's on the clipboard and convert it into
    // the appropriate blocks.
    // console.log('>>> paste')
  }, [])

  return (
    <div
      role="treeitem"
      aria-expanded="true"
      aria-selected={selected}
      tabIndex={0}
      className={clazz}
      data-placeholder={I18n.t('Add a section to start your page')}
      ref={el => {
        if (el) {
          connect(el)
        }
        pageRef.current = el
      }}
      onPaste={handlePaste}
      onKeyDown={handlePagekey}
      onFocus={handleFocus}
    >
      <a id="page-top" href="#page-top">
        <ScreenReaderContent>page top</ScreenReaderContent>
      </a>
      {children}
    </div>
  )
}

PageBlock.craft = {
  displayName: I18n.t('Page'),
  rules: {
    canMoveIn: (incomingNodes: Node[]) => {
      return incomingNodes.every((incomingNode: Node) => incomingNode.data.custom.isSection)
    },
    canMoveOut: (outgoingNodes: Node[], currentNode: Node) => {
      return currentNode.data.nodes.length > outgoingNodes.length
    },
  },
  custom: {
    isDeletable: (_myId: Node, _query: any) => {
      return false
    },
  },
}
