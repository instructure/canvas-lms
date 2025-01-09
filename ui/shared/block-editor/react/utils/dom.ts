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

const trayHeight: string = ''

// Adjusts the height that slide-out trays should take up based on the presence
// or absence of the masquerade bottom bar. Caches the result of this check
// forever, since we always reload the bundle when you enter/leave masquerade.
// export const getTrayHeight = () => {
//   if (!trayHeight) {
//     const masqueradeBar = document.querySelector(MASQUERADE_SELECTOR)
//     trayHeight = masqueradeBar ? 'calc(100vh - 50px)' : '100vh'
//   }
//   return trayHeight
// }

// bold is unique because font-weight can be 'bold' or a number
export function isCaretAtBoldText(): boolean {
  const selection = window.getSelection()
  if (selection?.rangeCount) {
    const range = selection.getRangeAt(0)
    const caretNode = range.startContainer
    const caretElement =
      caretNode.nodeType === Node.TEXT_NODE ? caretNode.parentElement : (caretNode as Element)
    return isElementBold(caretElement)
  }
  return false
}

export function isElementBold(elem: Element | null): boolean {
  if (!elem) return false

  const computedStyle = window.getComputedStyle(elem)
  const isBold: boolean =
    computedStyle.fontWeight === 'bold' ||
    parseInt(computedStyle.fontWeight, 10) >= 700 ||
    elem.tagName === 'B' ||
    elem.tagName === 'STRONG'
  return isBold
}

export function isCaretAtStyledText(property: string, value: string): boolean {
  const selection = window.getSelection()
  if (selection?.rangeCount) {
    const range = selection.getRangeAt(0)
    const caretNode = range.startContainer
    const caretElement =
      caretNode.nodeType === Node.TEXT_NODE ? caretNode.parentElement : (caretNode as Element)
    return isElementOfStyle(property, value, caretElement)
  }
  return false
}

export function isElementOfStyle(property: string, value: string, elem: Element | null): boolean {
  if (!elem) return false

  let currentElem: Element | null = elem
  while (currentElem) {
    const computedStyle = window.getComputedStyle(currentElem)
    // @ts-expect-error
    if (computedStyle[property] === value) {
      return true
    }
    currentElem = currentElem.parentElement
  }
  return false
}

export function scrollIntoViewWithCallback(
  element: HTMLElement | null,
  scrollIntoViewOpts: any,
  callback: () => void,
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
    {threshold: 1.0},
  )

  // Observe the target element
  observer.observe(element)

  // Scroll the element into view
  element.scrollIntoView(scrollIntoViewOpts)
}

export function mountNode(): HTMLElement {
  return document.querySelector('.block-editor-editor') as HTMLElement
}

const focusableSelector = `
  a[href],
  button,
  input:not([type="hidden"]),
  select,
  textarea,
  [tabindex]:not([tabindex="-1"]),
  summary
`

function isFocusable(element: HTMLElement): boolean {
  return typeof element.focus === 'function' && !element.hasAttribute('disabled')
}
export function firstFocusableElement(parent?: HTMLElement): HTMLElement | undefined {
  if (!parent) return undefined
  const focusableElements = Array.from(parent.querySelectorAll(focusableSelector)) as HTMLElement[]
  const firstFocusable = focusableElements.find(isFocusable)
  return firstFocusable
}
