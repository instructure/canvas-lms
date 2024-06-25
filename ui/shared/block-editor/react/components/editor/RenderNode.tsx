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

import {
  IconArrowUpLine,
  IconPlusLine,
  IconTrashLine,
  IconDragHandleLine,
} from '@instructure/ui-icons'
import {CondensedButton, IconButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {View, type ViewProps} from '@instructure/ui-view'
import {ToolbarSeparator} from './ToolbarSeparator'
import {getScrollParent, getNodeIndex} from '../../utils'
import {BlankSection} from '../user/sections/BlankSection'

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

interface RenderNodeProps {
  render: React.ReactElement
}

interface RenderNodeComponent extends React.FC<RenderNodeProps> {
  globals: {
    selectedSectionId: string
  }
}

export const RenderNode: RenderNodeComponent = ({render}: RenderNodeProps) => {
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

  const [currentToolbarOrTagRef, setCurrentToolbarOrTagRef] = useState<HTMLDivElement | null>(null)
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
      const {top, left, height} = domNode
        ? domNode.getBoundingClientRect()
        : {top: 0, left: 0, height: 0}
      const bottom = top + height

      // 5 is the offset of the hover/focus rings
      const offset = currentToolbarOrTagRef
        ? currentToolbarOrTagRef.getBoundingClientRect().height + 5
        : 0
      return {
        top: `${top > 0 ? top - offset : bottom - offset}px`,
        left: `${left}px`,
      }
    },
    [currentToolbarOrTagRef]
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
    if (currentToolbarOrTagRef) {
      const {top, left} = getToolbarPos(dom)
      currentToolbarOrTagRef.style.top = top
      currentToolbarOrTagRef.style.left = left
    }
  }, [currentMenuRef, currentToolbarOrTagRef, dom, getMenuPos, getToolbarPos])

  useEffect(() => {
    const scrollingContainer = getScrollParent()
    scrollingContainer.addEventListener('scroll', scroll)

    return () => {
      scrollingContainer.removeEventListener('scroll', scroll)
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

  const handleAppendSection = useCallback(() => {
    const parentId = node.data.parent || 'ROOT'
    const myIndex = getNodeIndex(node, query)
    const nodeTree = query.parseReactElement(<BlankSection />).toNodeTree()
    actions.addNodeTree(nodeTree, parentId, myIndex + 1)
  }, [actions, node, query])

  const handlePrependSection = useCallback(() => {
    const nodeTree = query.parseReactElement(<BlankSection />).toNodeTree()
    actions.addNodeTree(nodeTree, 'ROOT', 0)
  }, [actions, query])

  // TODO: this should be role="toolbar" and nav with arrow keys
  const renderBlockToolbar = () => {
    if (node.data?.custom?.noToolbar) return null
    const mountPoint = document.querySelector('.block-editor-editor')
    if (!mountPoint) return null

    return ReactDOM.createPortal(
      <div
        ref={(el: HTMLDivElement) => setCurrentToolbarOrTagRef(el)}
        className="block-toolbar"
        style={{
          left: getToolbarPos(dom).left,
          top: getToolbarPos(dom).top,
        }}
      >
        <View as="div" background="brand" padding="0 xx-small" borderRadius="small">
          <Text size="small">{name}</Text>
        </View>
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

  const renderHoverTag = () => {
    if (node.data?.custom?.noToolbar) return null

    const parentSection = findContainingSection(node, query)
    if (!parentSection) return null

    const isMySectionSelected = RenderNode.globals.selectedSectionId === parentSection.id
    if (!isMySectionSelected) return null

    const mountPoint = document.querySelector('.block-editor-editor')
    if (!mountPoint) return null

    return ReactDOM.createPortal(
      <div
        ref={(el: HTMLDivElement) => setCurrentToolbarOrTagRef(el)}
        className="block-tag"
        style={{
          left: getToolbarPos(dom).left,
          top: getToolbarPos(dom).top,
        }}
      >
        <View as="div" background="secondary" padding="0 xx-small" borderRadius="small">
          <Text size="small">{name}</Text>
        </View>
      </div>,
      mountPoint
    )
  }

  const renderRelated = () => {
    return (
      <>
        {renderBlockToolbar()}
        {renderSectionMenu()}
      </>
    )
  }

  const sectionIsFirst = () => {
    return getNodeIndex(node, query) === 0
  }

  const renderSectionAdder = (isBefore: boolean) => {
    return (
      <div className="section-adder">
        <span>
          <CondensedButton
            onClick={isBefore ? handlePrependSection : handleAppendSection}
            renderIcon={<IconPlusLine size="x-small" />}
          >
            Section
          </CondensedButton>
        </span>
      </div>
    )
  }

  return (
    <>
      {node.data.custom?.isSection && sectionIsFirst() && renderSectionAdder(true)}
      {selected && node.related && renderRelated()}
      {!selected && hovered && renderHoverTag()}
      {render}
      {node.data.custom?.isSection && renderSectionAdder()}
    </>
  )
}

RenderNode.globals = {
  selectedSectionId: '',
}
