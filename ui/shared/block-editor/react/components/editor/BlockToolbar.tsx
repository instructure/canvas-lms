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

import React, {useCallback, useEffect, useState} from 'react'
import {useEditor, useNode, type Node} from '@craftjs/core'
import {
  IconArrowOpenStartLine,
  IconArrowOpenEndLine,
  IconTrashLine,
  IconDragHandleLine,
} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {type ViewProps} from '@instructure/ui-view'
import {findFocusable} from '@instructure/ui-dom-utils'
import {
  notDeletableIfLastChild,
  mountNode,
  findUpNode,
  findDownNode,
  getToolbarPos,
  getArrowNext,
  getArrowPrev,
} from '../../utils'

const Arrows = ['ArrowDown', 'ArrowRight', 'ArrowUp', 'ArrowLeft']

type BlockToolbarProps = {}

const BlockToolbar = (_props: BlockToolbarProps) => {
  const {actions, query} = useEditor()
  const {
    node,
    name,
    moveable,
    deletable,
    connectors: {drag},
  } = useNode((n: Node) => {
    const node_helpers = query.node(n.id)
    return {
      node: n,
      name: n.data.custom.displayName || n.data.displayName,
      moveable: node_helpers.isDraggable(),
      deletable: n.data.custom?.isSection
        ? notDeletableIfLastChild(n.id, query)
        : (typeof n.data.custom?.isDeletable === 'function'
            ? n.data.custom.isDeletable?.(n.id, query)
            : true) && node_helpers.isDeletable(),
    }
  })
  const [arrowNext] = useState<string[]>(getArrowNext())
  const [arrowPrev] = useState<string[]>(getArrowPrev())
  const [mountPoint] = useState(mountNode())
  const [currentToolbarRef, setCurrentToolbarRef] = useState<HTMLDivElement | null>(null)
  const [upnodeId] = useState<string | undefined>(findUpNode(node, query)?.id)
  const [downnodeId] = useState<string | undefined>(findDownNode(node, query)?.id)
  const [focusable, setFocusable] = useState<HTMLElement[]>([])
  const [currFocusedIndex, setCurrFocusedIndex] = useState<number>(0)

  useEffect(() => {
    setFocusable(findFocusable(currentToolbarRef) as HTMLElement[])
  }, [currentToolbarRef])

  useEffect(() => {
    focusable.forEach((el, index) => {
      el.setAttribute('tabindex', index === currFocusedIndex ? '0' : '-1')
    })
  }, [currFocusedIndex, currentToolbarRef, focusable])

  const handleFocus = useCallback(
    (e: React.FocusEvent) => {
      if (e.target === currentToolbarRef) {
        focusable[currFocusedIndex]?.focus()
      } else {
        const fidx = focusable.indexOf(e.target as HTMLElement)
        if (fidx !== -1) {
          setCurrFocusedIndex(fidx)
        }
      }
    },
    [currFocusedIndex, currentToolbarRef, focusable]
  )

  const handleKey = useCallback(
    (e: React.KeyboardEvent<HTMLDivElement>) => {
      if (e.key === 'Escape' || arrowNext.includes(e.key) || arrowPrev.includes(e.key)) {
        e.preventDefault()
        e.stopPropagation()
      }

      if (e.key === 'Escape') {
        if (currentToolbarRef?.contains(document.activeElement)) {
          node.dom?.focus()
          return
        }
      }

      if (Arrows.includes(e.key)) {
        let focusedIndex = currFocusedIndex
        if (arrowNext.includes(e.key)) {
          focusedIndex = ++focusedIndex % focusable.length
        } else if (arrowPrev.includes(e.key)) {
          focusedIndex = (--focusedIndex + focusable.length) % focusable.length
        }
        setCurrFocusedIndex(focusedIndex)
        focusable[focusedIndex]?.focus()
      }
    },
    [arrowNext, arrowPrev, currFocusedIndex, currentToolbarRef, focusable, node.dom]
  )

  const handleGoUp = useCallback(
    (e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      e.stopPropagation()
      actions.selectNode(upnodeId)
      if (upnodeId) {
        query.node(upnodeId).get()?.dom?.focus()
      }
    },
    [actions, query, upnodeId]
  )

  const handleGoDown = useCallback(
    (e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      e.stopPropagation()
      actions.selectNode(downnodeId)
      if (downnodeId) {
        query.node(downnodeId).get()?.dom?.focus()
      }
    },
    [actions, query, downnodeId]
  )

  const handleDeleteNode = useCallback(
    (e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      e.stopPropagation()
      actions.delete(node.id)
    },
    [actions, node.id]
  )

  if (node.data?.custom?.noToolbar) return null
  if (!mountPoint) return null

  const {top, left} = getToolbarPos(node.dom, mountPoint, currentToolbarRef, true)

  // TODO: this should be role="toolbar" and nav with arrow keys
  return (
    <div
      ref={(el: HTMLDivElement) => setCurrentToolbarRef(el)}
      className="block-toolbar"
      role="toolbar"
      style={{
        left: `${left}px`,
        top: `${top}px`,
      }}
      tabIndex={-1}
      onFocus={handleFocus}
      onKeyDown={focusable.length > 0 ? handleKey : undefined}
    >
      <Flex as="div" padding="0 xx-small" gap="x-small">
        {upnodeId && (
          <IconButton
            cursor="pointer"
            size="small"
            onClick={handleGoUp}
            screenReaderLabel="Go up"
            withBackground={false}
            withBorder={false}
          >
            <IconArrowOpenStartLine />
          </IconButton>
        )}

        <Text>{name}</Text>

        {downnodeId && (
          <IconButton
            cursor="pointer"
            size="small"
            onClick={handleGoDown}
            screenReaderLabel="Go down"
            withBackground={false}
            withBorder={false}
          >
            <IconArrowOpenEndLine />
          </IconButton>
        )}

        {node.related.toolbar && (
          <>
            <div className="toolbar-separator" />
            {React.createElement(node.related.toolbar)}
          </>
        )}
        {moveable ? (
          <>
            <div className="toolbar-separator" />
            <IconButton
              cursor="move"
              size="small"
              elementRef={el => el && drag(el as HTMLElement)}
              screenReaderLabel="Drag to move"
              withBackground={false}
              withBorder={false}
            >
              <IconDragHandleLine />
            </IconButton>
          </>
        ) : null}
        {deletable ? (
          <>
            <div className="toolbar-separator" />
            <IconButton
              cursor="pointer"
              size="small"
              onClick={handleDeleteNode}
              screenReaderLabel="Delete"
              withBackground={false}
              withBorder={false}
              color="danger"
            >
              <IconTrashLine />
            </IconButton>
          </>
        ) : null}
      </Flex>
    </div>
  )
}

export {BlockToolbar}
