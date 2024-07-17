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

import type {AddSectionPlacement} from './types'
import {SectionBrowser} from './SectionBrowser'

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
  } = useNode((n: Node) => {
    const node_helpers = query.node(n.id)
    return {
      nodeActions: actions,
      node: n,
      hovered: n.events.hovered,
      selected: n.events.selected,
      dom: n.dom,
      name: n.data.custom.displayName || n.data.displayName,
      moveable: node_helpers.isDraggable(),
      deletable: n.data.custom?.isDeletable?.(n.id, query) && node_helpers.isDeletable(),
      props: n.data.props,
    }
  })

  const [currentToolbarOrTagRef, setCurrentToolbarOrTagRef] = useState<HTMLDivElement | null>(null)
  const [currentMenuRef, setCurrentMenuRef] = useState<HTMLDivElement | null>(null)
  const [upnodeId] = useState<string | undefined>(findUpNode(node, query)?.id)
  const [sectionBrowserOpen, setSectionBrowserOpen] = useState<AddSectionPlacement>(undefined)

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
    (domNode: HTMLElement | null, mountPoint: HTMLElement) => {
      if (!domNode) return {top: 0, left: 0}

      const nodeRect = domNode.getBoundingClientRect()
      const ntop = nodeRect.top
      const nleft = nodeRect.left

      const refRect = mountPoint.getBoundingClientRect()
      const ptop = refRect.top
      const pleft = refRect.left

      // 5 is the offset of the hover/focus rings
      const offset = currentToolbarOrTagRef
        ? currentToolbarOrTagRef.getBoundingClientRect().height + 5
        : 0

      return {
        top: `${ntop - ptop - offset}px`,
        left: `${nleft - pleft - 5}px`,
      }
    },
    [currentToolbarOrTagRef]
  )

  const getMenuPos = useCallback(
    (domNode: HTMLElement | null, mountPoint: HTMLElement) => {
      if (!domNode) return {top: 0, left: 0}

      const nodeRect = domNode.getBoundingClientRect()
      const refRect = mountPoint.getBoundingClientRect()

      const top = nodeRect.top - refRect.top
      const menuWidth = currentMenuRef ? currentMenuRef.getBoundingClientRect().width : 0
      const left = nodeRect.left + nodeRect.width - refRect.left - menuWidth

      return {
        top: `${top}px`,
        left: `${left}px`,
      }
    },
    [currentMenuRef]
  )

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
    const mountPoint = document.querySelector('.block-editor-editor') as HTMLElement | null
    if (!mountPoint) return null

    return ReactDOM.createPortal(
      <div
        ref={(el: HTMLDivElement) => setCurrentToolbarOrTagRef(el)}
        className="block-toolbar"
        style={{
          left: getToolbarPos(dom, mountPoint).left,
          top: getToolbarPos(dom, mountPoint).top,
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
    const mountPoint = document.querySelector('.block-editor-editor') as HTMLElement | null
    if (!mountPoint) return null
    if (node.related?.sectionMenu) {
      const {left, top} = getMenuPos(dom, mountPoint)

      return ReactDOM.createPortal(
        <div
          ref={(el: HTMLDivElement) => setCurrentMenuRef(el)}
          className="section-menu"
          style={{left, top}}
        >
          {React.createElement(node.related.sectionMenu, {onAddSection: handleAddSection})}
        </div>,
        mountPoint
      )
    }
    return null
  }

  const renderHoverTag = () => {
    if (node.data?.custom?.noToolbar) return null

    const parentSection = findContainingSection(node, query)
    if (!parentSection) return null

    const isMySectionSelected = RenderNode.globals.selectedSectionId === parentSection.id
    if (!isMySectionSelected) return null

    const mountPoint = document.querySelector('.block-editor-editor') as HTMLElement | null
    if (!mountPoint) return null

    const {left, top} = getToolbarPos(dom, mountPoint)
    return ReactDOM.createPortal(
      <div
        ref={(el: HTMLDivElement) => setCurrentToolbarOrTagRef(el)}
        className="block-tag"
        style={{left, top}}
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

  const handleAddSection = useCallback((where: AddSectionPlacement) => {
    setSectionBrowserOpen(where)
  }, [])

  const renderSectionAdder = (isBefore: boolean = false) => {
    return (
      !!sectionBrowserOpen && (
        <SectionBrowser
          open={true}
          onClose={() => setSectionBrowserOpen(undefined)}
          where={sectionBrowserOpen}
        />
      )
    )
  }

  return (
    <>
      {node.data.name === 'PageBlock' && renderSectionAdder(true)}
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
