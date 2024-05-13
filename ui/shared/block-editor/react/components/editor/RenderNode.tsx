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
import {SectionMenu} from './SectionMenu'

type RenderNodeProps = {
  render: React.ReactElement
}

export const RenderNode = ({render}: RenderNodeProps) => {
  const {id} = useNode()
  const {actions, query, selected} = useEditor((_, qry) => ({
    selected: qry.getEvent('selected').contains(id),
  }))
  const {
    hovered,
    node,
    dom,
    name,
    moveable,
    deletable,
    connectors: {drag},
    parent,
  } = useNode((node: Node) => ({
    node,
    hovered: node.events.hovered,
    dom: node.dom,
    name: node.data.custom.displayName || node.data.displayName,
    moveable: query.node(node.id).isDraggable(),
    deletable: query.node(node.id).isDeletable(),
    parent: node.data.parent,
    props: node.data.props,
  }))

  const [currentToolbarRef, setCurrentToolbarRef] = useState<HTMLDivElement | null>(null)
  const [currentMenuRef, setCurrentMenuRef] = useState<HTMLDivElement | null>(null)

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

  const handleGoUp = useCallback(
    (e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      e.stopPropagation()
      actions.selectNode(parent || undefined)
      // if (parent) {
      //   query.node(parent).get().dom?.scrollIntoView({behavior: 'smooth', block: 'start'})
      // }
    },
    [actions, parent]
  )

  const handleDeleteNode = useCallback(
    (e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      e.stopPropagation()
      actions.delete(node.id)
    },
    [actions, node.id]
  )

  const renderBlockToolbar = () => {
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
            elementRef={el => el && drag(el)}
            screenReaderLabel="Drag to move"
            withBackground={false}
            withBorder={false}
          >
            <IconDragHandleLine size="x-small" />
          </IconButton>
        ) : null}
        {node.id !== ROOT_NODE && (
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
      document.querySelector('.block-editor') as HTMLElement
    )
  }

  const renderSectionMenu = () => {
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
          document.querySelector('.block-editor') as HTMLElement
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
