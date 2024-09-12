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

import {type Node} from '@craftjs/core'
import {ROOT_NODE} from '@craftjs/utils'

const getToolbarPos = (
  domNode: HTMLElement | null,
  mountPoint: HTMLElement,
  currentToolbarOrTagRef: HTMLElement | null,
  includeOffset: boolean = true
) => {
  if (!domNode) return {top: 0, left: 0}

  const nodeRect = domNode.getBoundingClientRect()
  const ntop = nodeRect.top
  const nleft = nodeRect.left

  const refRect = mountPoint.getBoundingClientRect()
  const ptop = refRect.top
  const pleft = refRect.left

  // 5 is the offset of the hover/focus rings
  const offsetTop =
    currentToolbarOrTagRef && includeOffset
      ? currentToolbarOrTagRef.getBoundingClientRect().height + 5
      : 0

  const offsetLeft = includeOffset ? 5 : 0

  return {
    top: ntop - ptop - offsetTop,
    left: nleft - pleft - offsetLeft,
  }
}

const getMenuPos = (
  domNode: HTMLElement | null,
  mountPoint: HTMLElement,
  currentMenuRef: HTMLElement | null
) => {
  if (!domNode) return {top: 0, left: 0}

  const nodeRect = domNode.getBoundingClientRect()
  const refRect = mountPoint.getBoundingClientRect()

  const top = nodeRect.top - refRect.top
  const menuWidth = currentMenuRef ? currentMenuRef.getBoundingClientRect().width : 0
  const left = nodeRect.left + nodeRect.width - refRect.left - menuWidth

  return {top, left}
}

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

export {getToolbarPos, getMenuPos, findUpNode, findContainingSection}
