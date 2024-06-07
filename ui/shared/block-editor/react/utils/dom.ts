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

// this was lifted from canvas-rce/src/rce/plugins/shared/trayUtils.js

const MASQUERADE_SELECTOR = 'body.is-masquerading-or-student-view'

let trayHeight: string = ''

// Adjusts the height that slide-out trays should take up based on the presence
// or absence of the masquerade bottom bar. Caches the result of this check
// forever, since we always reload the bundle when you enter/leave masquerade.
export const getTrayHeight = () => {
  if (!trayHeight) {
    const masqueradeBar = document.querySelector(MASQUERADE_SELECTOR)
    trayHeight = masqueradeBar ? 'calc(100vh - 50px)' : '100vh'
  }
  return trayHeight
}

export type isStyledFunction = (node: Element) => boolean
export type unstyleFunction = (node: Element) => void
export type styleSelectionFunction = () => void

export function makeSelectionBold(): void {
  unstyleSelection(isElementBold, unboldElement)
  const selection = window.getSelection()
  if (selection?.rangeCount) {
    const range = selection.getRangeAt(0)
    const boldNode = document.createElement('span')
    boldNode.style.fontWeight = 'bold'
    boldNode.appendChild(range.extractContents())
    range.insertNode(boldNode)
    selection.removeAllRanges()
    selection.addRange(range)
  }
}

export function isElementBold(elem: Element): boolean {
  const computedStyle = window.getComputedStyle(elem)
  const isBold: boolean =
    computedStyle.fontWeight === 'bold' ||
    parseInt(computedStyle.fontWeight, 10) >= 700 ||
    elem.tagName === 'B' ||
    elem.tagName === 'STRONG'
  return isBold
}

export function unboldElement(elem: Element): void {
  if (
    elem.tagName === 'B' ||
    elem.tagName === 'STRONG' ||
    elem.getAttribute('style')?.split(':').length === 2 // font-weight is the only style attribute
  ) {
    // Replace the <b>, <strong>, or bold-styled tag with its contents
    const fragment = document.createDocumentFragment()
    while (elem.firstChild) {
      fragment.appendChild(elem.firstChild)
    }
    elem.parentNode?.replaceChild(fragment, elem)
  } else {
    // Remove bold styling from the element
    ;(elem as HTMLElement).style.fontWeight = 'normal'
  }
}

export function isSelectionAllStyled(styleChecker: isStyledFunction): boolean {
  const selection = window.getSelection()
  if (!selection || selection.rangeCount === 0) {
    return false
  }

  // Iterate over all ranges in the selection
  for (let i = 0; i < selection.rangeCount; i++) {
    const range: Range = selection.getRangeAt(i)
    const commonAncestor: Node = range.commonAncestorContainer

    // Create a tree walker to traverse all nodes within the range
    const walker: TreeWalker = document.createTreeWalker(commonAncestor, NodeFilter.SHOW_TEXT, {
      acceptNode: (node: Node): number => {
        // Only consider nodes that are fully or partially within the range
        return range.intersectsNode(node) ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT
      },
    })

    let node: Node | null

    // Special case handling for direct TextNode selection
    if (commonAncestor.nodeType === Node.TEXT_NODE) {
      node = commonAncestor
    } else {
      node = walker.nextNode()
    }

    while (node) {
      const parentElement = node.parentElement

      if (parentElement) {
        const isBold = styleChecker(parentElement)

        if (!isBold) {
          return false
        }
      }
      node = walker.nextNode()
    }
  }

  return true
}

export function unstyleSelection(
  isElemStyled: isStyledFunction,
  unStyleElement: unstyleFunction
): void {
  const selection = window.getSelection()
  if (!selection || selection.rangeCount === 0) {
    return
  }

  // Iterate over all ranges in the selection
  for (let i = 0; i < selection.rangeCount; i++) {
    const range: Range = selection.getRangeAt(i)
    const commonAncestor: Node = range.commonAncestorContainer

    // Create a tree walker to traverse all nodes within the range
    const walker: TreeWalker = document.createTreeWalker(commonAncestor, NodeFilter.SHOW_TEXT, {
      acceptNode: (node: Node): number => {
        // Only consider nodes that are fully or partially within the range
        return range.intersectsNode(node) ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT
      },
    })

    let node: Node | null

    // Special case handling for direct TextNode selection
    if (commonAncestor.nodeType === Node.TEXT_NODE) {
      node = commonAncestor
    } else {
      node = walker.nextNode()
    }

    while (node) {
      const parentElement = node.parentElement

      if (parentElement) {
        // Check if the parent element of the text node is bold
        const isBold = isElemStyled(parentElement)

        if (isBold) {
          unStyleElement(parentElement)
        }
      }
      node = walker.nextNode()
    }
  }
}

export function scrollIntoViewWithCallback(
  element: HTMLElement | null,
  scrollIntoViewOpts: any,
  callback: () => void
) {
  if (!element) return

  // Create an IntersectionObserver
  const observer = new IntersectionObserver(
    entries => {
      // Check if the element is in view
      if (entries[0].isIntersecting) {
        // Call the callback function
        callback()
        // Disconnect the observer
        observer.disconnect()
      }
    },
    {threshold: 1.0}
  )

  // Observe the target element
  observer.observe(element)

  // Scroll the element into view
  element.scrollIntoView(scrollIntoViewOpts)
}

export function validateSVG(svg: string): boolean {
  const parser = new DOMParser()
  const doc = parser.parseFromString(svg, 'image/svg+xml')
  if (doc.documentElement.childElementCount !== 1 || doc.querySelector('svg') === null) {
    return false
  }
  return true
}
