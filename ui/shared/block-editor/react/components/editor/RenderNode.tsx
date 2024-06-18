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

/*
 * MIT License
 *
 * Copyright (c) 2020 Previnash Wong Sze Chuan
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import React, {useCallback, useEffect, useState} from 'react'
import ReactDOM from 'react-dom'
import {useNode, useEditor, type Node} from '@craftjs/core'
import {ROOT_NODE} from '@craftjs/utils'

import {IconArrowUpLine, IconTrashLine, IconDragHandleLine} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {type ViewProps} from '@instructure/ui-view'
import {ToolbarSeparator} from './ToolbarSeparator'

const findUpNode = (node: Node, query: any): Node | undefined => {
  let upnode = node.data.parent ? query.node(node.data.parent).get() : undefined
  while (upnode && upnode.data.parent && upnode.data.custom?.noToolbar) {
    upnode = upnode.data.parent ? query.node(upnode.data.parent).get() : undefined
  }
  return upnode && upnode.id !== ROOT_NODE ? upnode : undefined
}

const findContainingSection = (node: Node, query: any): Node | undefined => {
  if (node.data.custom?.isSection) return node
  let upnode = findUpNode(node, query)
  while (upnode && !upnode.data.custom?.isSection) {
    upnode = findUpNode(upnode, query)
  }
  return upnode && upnode.data.custom?.isSection ? upnode : undefined
}

type RenderNodeProps = {
  render: React.ReactElement
}

export const RenderNode = ({render}: RenderNodeProps) => {
  const {actions, query} = useEditor(state => {
    if (state.events.selected.size === 0) {
      RenderNode.globals.selectedSectionId = ''
    }
  })
  const {
    nodeActions,
    hovered,
    selected,
    node,
    dom,
    name,
    moveable,
    deletable,
    connectors: {drag},
  } = useNode((n: Node) => ({
    nodeActions: actions,
    node: n,
    hovered: n.events.hovered,
    selected: n.events.selected,
    dom: n.dom,
    name: n.data.custom.displayName || n.data.displayName,
    moveable: query.node(n.id).isDraggable(),
    deletable: query.node(n.id).isDeletable(),
    props: n.data.props,
  }))

  const [currentToolbarRef, setCurrentToolbarRef] = useState<HTMLDivElement | null>(null)
  const [currentMenuRef, setCurrentMenuRef] = useState<HTMLDivElement | null>(null)
  const [upnodeId] = useState<string | undefined>(findUpNode(node, query)?.id)

  useEffect(() => {
    // get a newly dropped block selected
    // select once will select it's section
    // select again to get the block
    // (see the following useEffect for details)
    if (node.id !== 'ROOT') {
      actions.selectNode(node.id)
      requestAnimationFrame(() => {
        actions.selectNode(node.id)
      })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // first click/select on a block will select its parent section
  // if the section is selected, a click on a block will select the block
  useEffect(() => {
    if (selected) {
      const parentSection = findContainingSection(node, query)
      if (parentSection) {
        const isMySectionSelected = RenderNode.globals.selectedSectionId === parentSection.id
        if (!isMySectionSelected) {
          RenderNode.globals.selectedSectionId = parentSection.id
          actions.selectNode(parentSection.id)
        } else if (node.data.custom?.noToolbar) {
          const upnode = findUpNode(node, query)
          if (upnode) {
            actions.selectNode(upnode.id)
          }
        }
      }
    }
  }, [actions, node, nodeActions, query, selected])

  useEffect(() => {
    if (dom) {
      if (selected) dom.classList.add('selected')
      else dom.classList.remove('selected')

      if (hovered) dom.classList.add('hovered')
      else dom.classList.remove('hovered')
    }
  }, [dom, selected, hovered])

  const getToolbarPos = useCallback(
    (domNode: HTMLElement | null) => {
      const {top, left, bottom} = domNode
        ? domNode.getBoundingClientRect()
        : {top: 0, left: 0, bottom: 0}
      const offset = currentToolbarRef ? currentToolbarRef.getBoundingClientRect().height : 0
      return {
        top: `${top > 0 ? top - offset : bottom - offset}px`,
        left: `${left}px`,
      }
    },
    [currentToolbarRef]
  )
  const getMenuPos = useCallback(
    (domNode: HTMLElement | null) => {
      const {top, left, bottom, width} = domNode
        ? domNode.getBoundingClientRect()
        : {top: 0, left: 0, bottom: 0, width: 0}
      const offset = currentMenuRef ? width - currentMenuRef.getBoundingClientRect().width : 0
      return {
        top: `${top > 0 ? top : bottom}px`,
        left: `${left + offset}px`,
      }
    },
    [currentMenuRef]
  )

  const scroll = useCallback(() => {
    if (currentMenuRef) {
      const {top, left} = getMenuPos(dom)
      currentMenuRef.style.top = top
      currentMenuRef.style.left = left
    }
    if (currentToolbarRef) {
      const {top, left} = getToolbarPos(dom)
      currentToolbarRef.style.top = top
      currentToolbarRef.style.left = left
    }
  }, [currentMenuRef, currentToolbarRef, dom, getMenuPos, getToolbarPos])

  useEffect(() => {
    const scroller = document.getElementById('drawer-layout-content') || document
    scroller.addEventListener('scroll', scroll)

    return () => {
      scroller.removeEventListener('scroll', scroll)
    }
  }, [dom, scroll])

  // TODO: maybe setState the upnode so we know whether to show the up button or not
  const handleGoUp = useCallback(
    (e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      e.stopPropagation()
      actions.selectNode(upnodeId)
    },
    [actions, upnodeId]
  )

  const handleDeleteNode = useCallback(
    (e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      e.stopPropagation()
      actions.delete(node.id)
    },
    [actions, node.id]
  )

  // TODO: this should be role="toolbar" and nav with arrow keys
  const renderBlockToolbar = () => {
    if (node.data?.custom?.noToolbar) return null
    const mountPoint = document.querySelector('.block-editor-editor')
    if (!mountPoint) return null

    return ReactDOM.createPortal(
      <div
        ref={(el: HTMLDivElement) => setCurrentToolbarRef(el)}
        className="block-toolbar"
        style={{
          left: getToolbarPos(dom).left,
          top: getToolbarPos(dom).top,
        }}
        data-timestamp={Date.now()}
      >
        <Text size="small">{name}</Text>
        {moveable ? (
          <IconButton
            cursor="move"
            size="small"
            elementRef={el => el && drag(el as HTMLElement)}
            screenReaderLabel="Drag to move"
            withBackground={false}
            withBorder={false}
          >
            <IconDragHandleLine size="x-small" />
          </IconButton>
        ) : null}
        {upnodeId && (
          <IconButton
            cursor="pointer"
            size="small"
            onClick={handleGoUp}
            screenReaderLabel="Go to parent"
            withBackground={false}
            withBorder={false}
          >
            <IconArrowUpLine size="x-small" />
          </IconButton>
        )}
        {node.related.toolbar && (
          <>
            <ToolbarSeparator />
            {React.createElement(node.related.toolbar)}
          </>
        )}
        {deletable ? (
          <>
            <ToolbarSeparator />
            <IconButton
              cursor="pointer"
              size="small"
              onClick={handleDeleteNode}
              screenReaderLabel="Delete"
              withBackground={false}
              withBorder={false}
              color="danger"
            >
              <IconTrashLine size="x-small" />
            </IconButton>
          </>
        ) : null}
      </div>,
      mountPoint
    )
  }

  const renderSectionMenu = () => {
    const mountPoint = document.querySelector('.block-editor-editor')
    if (!mountPoint) return null
    return node.related?.sectionMenu
      ? ReactDOM.createPortal(
          <div
            ref={(el: HTMLDivElement) => setCurrentMenuRef(el)}
            className="block-menu"
            style={{
              left: getMenuPos(dom).left,
              top: getMenuPos(dom).top,
            }}
          >
            {React.createElement(node.related.sectionMenu)}
          </div>,
          mountPoint
        )
      : null
  }

  const renderRelated = () => {
    return (
      <>
        {renderBlockToolbar()}
        {renderSectionMenu()}
      </>
    )
  }

  return (
    <>
      {selected && node.related && renderRelated()}
      {render}
    </>
  )
}

RenderNode.globals = {
  selectedSectionId: '',
}
