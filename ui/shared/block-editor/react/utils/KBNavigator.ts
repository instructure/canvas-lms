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

import React from 'react'
import {type Node} from '@craftjs/core'
import {mountNode} from './dom'

function findFirstChildBlock(node: Node, query: any): Node | null {
  const nodehelpers = query.node(node.id)
  let descendants = nodehelpers.childNodes()
  if (descendants.length === 0) {
    descendants = nodehelpers.descendants(true)
  }
  for (const descendant of descendants) {
    const descendantNode = query.node(descendant).get()
    if (KBNavigator.isBlock(descendantNode)) {
      return descendantNode
    }
  }
  return null
}

class KBNavigator {
  #actions: any

  #query: any

  #currentNodeId: string

  #expanded: boolean

  #node: Node | null

  #domNode: HTMLElement | null

  constructor() {
    // TODO: will we ever have > 1 block editor on the page?
    this.#currentNodeId = 'ROOT'
    this.#expanded = true
    this.#node = null
    this.#domNode = null
  }

  static isBlock(node: Node): boolean {
    return node && (node.data.custom?.isBlock || node.data.custom?.isSection)
  }

  static isGroup(node: Node): boolean {
    return !!node.dom?.getAttribute('aria-expanded')
  }

  static isExpandedGroup(node: Node): boolean {
    return node.dom?.getAttribute('aria-expanded') === 'true'
  }

  #focusBlock(block: Node | null) {
    if (block) {
      block.dom?.focus()
      this.#actions.selectNode(block.id)
    }
  }

  #focusPageBlock() {
    const pageBlock = this.#query.node('ROOT').get()
    this.#focusBlock(pageBlock)
  }

  #findFirstChildBlock(node: Node): Node | null {
    return findFirstChildBlock(node, this.#query)
  }

  #findNextSiblingBlock(node: Node): Node | null {
    if (!(node && node.data.parent)) return null
    const parentId = node.data.parent
    const siblings = this.#query.node(parentId).childNodes()
    const myIndex = siblings.indexOf(node.id)
    if (siblings.length > myIndex + 1) {
      const nextSibling = this.#query.node(siblings[myIndex + 1]).get()
      if (KBNavigator.isBlock(nextSibling)) {
        return nextSibling
      }
    }
    return null
  }

  #findPreviousSiblingBlock(): Node | null {
    if (!(this.#node && this.#node.data.parent)) return null
    const parentId = this.#node.data.parent
    const siblings = this.#query.node(parentId).descendants()
    const myIndex = siblings.indexOf(this.#node.id)
    if (myIndex > 0) {
      const previousSibling = this.#query.node(siblings[myIndex - 1]).get()
      if (KBNavigator.isBlock(previousSibling)) {
        return previousSibling
      }
    }
    return null
  }

  #findParentBlock(node: Node): Node | null {
    if (!(this.#node && node.data.parent)) return null

    let parentNode = this.#query.node(node.data.parent).get()
    while (parentNode && parentNode.id !== 'ROOT' && !KBNavigator.isBlock(parentNode)) {
      parentNode = this.#query.node(parentNode.data.parent).get()
    }
    return parentNode
  }

  #findParentNextSiblingBlock(node: Node): Node | null {
    if (!this.#node) return null
    let parentBlock = this.#findParentBlock(node)
    while (parentBlock) {
      const parentNextSibling = this.#findNextSiblingBlock(parentBlock)
      if (parentNextSibling) {
        return parentNextSibling
      }
      parentBlock = this.#findParentBlock(parentBlock)
    }
    return null
  }

  #findParentPreviousSiblingBlock(): Node | null {
    if (!this.#node) return null
    let parentBlock = this.#findParentBlock(this.#node)
    while (parentBlock) {
      const parentPreviousSibling = this.#findPreviousSiblingBlock()
      if (parentPreviousSibling) {
        return parentPreviousSibling
      }
      parentBlock = this.#findParentBlock(parentBlock)
    }
    return null
  }

  #findLastChildBlock(nodeId: string): Node | null {
    const descendants = this.#query.node(nodeId).descendants(true)
    for (let i = descendants.length - 1; i >= 0; i--) {
      const descendantNode = this.#query.node(descendants[i]).get()
      if (KBNavigator.isBlock(descendantNode)) {
        return descendantNode
      }
    }
    return null
  }

  #findLastDirectChildBlock(nodeId: string): Node | null {
    let descendants = this.#query.node(nodeId).descendants(false)
    // might be an _inner
    let lastDescendantId = descendants.length ? descendants[descendants.length - 1] : null
    while (lastDescendantId && !KBNavigator.isBlock(this.#query.node(lastDescendantId).get())) {
      descendants = this.#query.node(lastDescendantId).descendants(false)
      lastDescendantId = descendants.length ? descendants[descendants.length - 1] : null
    }
    return lastDescendantId ? this.#query.node(lastDescendantId).get() : null
  }

  #findLastBlock(): Node | null {
    let currNode = this.#query.node('ROOT').get()
    let lastBlockNode = this.#findLastChildBlock('ROOT')
    while (lastBlockNode) {
      currNode = lastBlockNode
      lastBlockNode = this.#findLastChildBlock(lastBlockNode.id)
    }
    return currNode
  }

  #findNextFocusableBlockWithoutOpeningOrClosing(node: Node): Node | null {
    if (!node) return null

    if (KBNavigator.isExpandedGroup(node)) {
      const childBlockNode = this.#findFirstChildBlock(node)
      if (childBlockNode) return childBlockNode
    }
    const nextBlockNode = this.#findNextSiblingBlock(node)
    if (nextBlockNode) {
      return nextBlockNode
    } else {
      const parentNextSiblingBlock = this.#findParentNextSiblingBlock(node)
      return parentNextSiblingBlock
    }
  }

  // Moves focus to the next node that is focusable without opening or closing a node.
  // Returns the node it landed on
  #handleArrowDown() {
    if (!(this.#node && this.#domNode)) return

    const nextBlock = this.#findNextFocusableBlockWithoutOpeningOrClosing(this.#node)
    this.#focusBlock(nextBlock)
  }

  // When focus is on a closed node, opens the node; focus does not move.
  // When focus is on a open node, moves focus to the first child node.
  // When focus is on an end node, does nothing.
  #handleArrowRight() {
    if (!(this.#node && this.#domNode)) return

    if (KBNavigator.isExpandedGroup(this.#node)) {
      const firstBlockNode = this.#findFirstChildBlock(this.#node)
      this.#focusBlock(firstBlockNode)
    } else {
      this.#actions.setCustom(this.#node.id, (cstm: Record<string, any>) => {
        cstm.isExpanded = true
      })
    }
  }

  // the inverse of ArrowDown
  // Moves focus to the previous node that is focusable without opening or closing a node.
  #handleArrowUp() {
    if (!(this.#node && this.#domNode)) return

    const prevBlockNode = this.#findPreviousSiblingBlock()
    if (prevBlockNode) {
      if (KBNavigator.isExpandedGroup(prevBlockNode)) {
        let lastChild = this.#findLastDirectChildBlock(prevBlockNode.id)
        while (lastChild && KBNavigator.isExpandedGroup(lastChild)) {
          lastChild = this.#findLastDirectChildBlock(lastChild.id)
        }
        if (lastChild) {
          this.#focusBlock(lastChild)
          return
        }
      }
      this.#focusBlock(prevBlockNode)
    } else {
      // this block was the first in its parent
      // move to the parent
      const parentNode = this.#findParentBlock(this.#node)
      this.#focusBlock(parentNode)
    }
  }

  // When focus is on an open node, closes the node.
  // When focus is on a child node that is also either an end node or a closed node, moves focus to its parent node.
  // When focus is on a root node that is also either an end node or a closed node, does nothing.
  #handleArrowLeft() {
    if (!(this.#node && this.#domNode)) return

    if (KBNavigator.isExpandedGroup(this.#node)) {
      this.#actions.setCustom(this.#node.id, (cstm: Record<string, any>) => {
        cstm.isExpanded = false
      })
    } else {
      const parentNode = this.#findParentBlock(this.#node)
      this.#focusBlock(parentNode)
    }
  }

  // move to the page block
  #handleHome() {
    this.#focusPageBlock()
  }

  // move to the last block in the page
  #handleEnd() {
    if (!this.#node) return

    let lastBlock = this.#findNextFocusableBlockWithoutOpeningOrClosing(this.#node)
    while (lastBlock) {
      const nextLastBlock = this.#findNextFocusableBlockWithoutOpeningOrClosing(lastBlock)
      if (nextLastBlock) {
        lastBlock = nextLastBlock
      } else {
        break
      }
    }
    this.#focusBlock(lastBlock)
  }

  #getEditorControl(selector: string): HTMLElement | null {
    return mountNode()?.querySelector(selector) as HTMLElement
  }

  #handleShortcut(e: React.KeyboardEvent) {
    switch (e.key) {
      case 'F8':
        break
      case 'F9':
        if (e.ctrlKey) {
          // return focus to the last toolbar button that had focus
          this.#getEditorControl('.block-toolbar [tabIndex="0"]')?.focus()
        }
        break
      case 'F10':
        if (e.altKey) {
          this.#getEditorControl('.topbar')?.focus()
        }
        break
    }
  }

  // this is the keyDown handler for the block editor
  // currentNodeId is the selected node when the key was pressed
  key(e: React.KeyboardEvent, editorActions: any, query: any, currentNodeId: string) {
    if (['ArrowRight', 'ArrowLeft', 'ArrowUp', 'ArrowDown', 'Home', 'End'].includes(e.key)) {
      if (e.ctrlKey || e.metaKey || e.shiftKey || e.altKey) return

      this.#actions = editorActions
      this.#query = query

      this.#currentNodeId = currentNodeId

      this.#node = this.#query.node(this.#currentNodeId).get()
      if (!this.#node) return

      this.#domNode = this.#node.dom
      if (!this.#domNode) return

      this.#expanded = this.#node.data.custom?.isExpanded

      switch (e.key) {
        case 'ArrowRight':
          this.#handleArrowRight()
          break
        case 'ArrowLeft':
          this.#handleArrowLeft()
          break
        case 'ArrowDown':
          this.#handleArrowDown()
          e.preventDefault() // don't scroll
          break
        case 'ArrowUp':
          this.#handleArrowUp()
          e.preventDefault() // don't scroll
          break
        case 'Home':
          this.#handleHome()
          break
        case 'End':
          this.#handleEnd()
          break
      }
    } else if (['F8', 'F9', 'F10'].includes(e.key)) {
      this.#handleShortcut(e)
    }
  }
}

export {KBNavigator, findFirstChildBlock}
