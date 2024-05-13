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

const isAnyModifierKeyPressed = (event: React.KeyboardEvent) =>
  event.ctrlKey || event.metaKey || event.shiftKey || event.altKey

const getCaretPosition = (editableElement: HTMLElement): number => {
  let caretOffset = 0
  const doc = editableElement.ownerDocument
  const win = doc.defaultView
  if (win) {
    const sel = win.getSelection()
    if (sel) {
      if (sel.rangeCount > 0) {
        const range = sel.getRangeAt(0)
        const preCaretRange = range.cloneRange()
        preCaretRange.selectNodeContents(editableElement)
        preCaretRange.setEnd(range.endContainer, range.endOffset)
        caretOffset = preCaretRange.toString().length
      }
    }
  }

  return caretOffset
}

const isCaretAtEnd = (editableElement: HTMLElement): boolean => {
  const caretPosition = getCaretPosition(editableElement)
  const textContentLength = editableElement.textContent?.length || 0
  return caretPosition === textContentLength
}

// TODO: I would like to set the caret after deleteNodeAndSelectPrevSibling
// but it's going to take more logic to know when to call this.
// it would be better if
const setCaretToEnd = (editableElement: HTMLElement) => {
  const range = document.createRange()
  const sel = window.getSelection()
  if (sel) {
    range.selectNodeContents(editableElement)
    range.collapse(false) // Collapse the range to the end

    sel.removeAllRanges()
    sel.addRange(range)
  }
}

// const setCaretToOffset = (editableElement: HTMLElement, offset: number) => {
//   const range = document.createRange()
//   const sel = window.getSelection()
//   if (sel) {
//     const textNode = editableElement.querySelector('p')?.firstChild
//     if (textNode) {
//       range.setStart(textNode, offset)
//       range.collapse(true)

//       sel.removeAllRanges()
//       sel.addRange(range)
//     }
//   }
// }

const addNewNodeAsNextSibling = (
  newNode: React.ReactElement,
  currentComponentId: string,
  actions: any,
  query: any
) => {
  const currentNode = query.node(currentComponentId).get()
  const parentId = currentNode.data.parent
  const siblings = query.node(parentId).descendants()
  const myIndex = siblings.indexOf(currentComponentId)
  const newNodeTree = query.parseReactElement(newNode).toNodeTree()
  actions.addNodeTree(newNodeTree, parentId, myIndex + 1)
  actions.selectNode(newNodeTree.rootNodeId)
}

const shouldAddNewNode = (e: React.KeyboardEvent, lastChar: string) => {
  if (!e.currentTarget.textContent) return false
  return (
    e.key === 'Enter' &&
    !isAnyModifierKeyPressed(e) &&
    isCaretAtEnd(e.currentTarget as HTMLElement) &&
    lastChar === 'Enter'
  )
}

const removeLastParagraphTag = elem => {
  const paras = elem.querySelectorAll('p')
  if (paras.length > 0) {
    const lastPara = paras[paras.length - 1]
    lastPara.remove()
  }
}

const deleteNodeAndSelectPrevSibling = (currentComponentId: string, actions: any, query: any) => {
  const currentNode = query.node(currentComponentId).get()
  const parentId = currentNode.data.parent
  const parent = query.node(parentId)
  const siblings = parent.descendants()
  const prevSibling = siblings[siblings.indexOf(currentComponentId) - 1]
  actions.delete(currentComponentId)
  actions.selectNode(prevSibling)
}

const shouldDeleteNode = (e: React.KeyboardEvent) => {
  return e.key === 'Backspace' && e.currentTarget.textContent === ''
}

export {
  isAnyModifierKeyPressed,
  getCaretPosition,
  isCaretAtEnd,
  setCaretToEnd,
  shouldAddNewNode,
  shouldDeleteNode,
  addNewNodeAsNextSibling,
  deleteNodeAndSelectPrevSibling,
  removeLastParagraphTag,
}
