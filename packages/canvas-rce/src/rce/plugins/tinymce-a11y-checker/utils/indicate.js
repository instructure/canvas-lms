/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

// The styling used to highlight the a11y violation.
// These rules will be assigned to the selector we build below
// that locates the violating element in the DOM
export const INDICATOR_STYLE = `
outline:2px solid #2D3B45;
outline-offset:2px;
`

// id of the style element where we inject CSS that will generate the
// a11y violation hightlight.
export const A11Y_CHECKER_STYLE_ELEM_ID = 'a11y-checker-style'

// Remove the current indicator(s) by removing the contents of
// the style element
export function clearIndicators(doc) {
  const checker_style = doc.getElementById(A11Y_CHECKER_STYLE_ELEM_ID)
  if (checker_style) {
    checker_style.textContent = ''
  }
}

// build a selector in the shape of
// "body>:nth-child(x)>:nth-child(y)"
// that will select the given elem in the body
export function buildDepthSelector(elem) {
  const elemBody = elem.ownerDocument.body
  const depths = []
  let target = elem
  let parent = target.parentElement
  while (target && parent && target !== elemBody) {
    const depth = findChildDepth(parent, target)
    depths.unshift(`>:nth-child(${depth})`)
    target = parent
    parent = target?.parentElement
  }

  return `body${depths.join('')}`
}

// compute the ordinal of target relative to its parent
export function findChildDepth(parent, target) {
  if (!(parent && target)) return 0
  const children = parent.children
  const depth = Array.from(children).findIndex(child => child === target)
  return depth + 1
}

// guarantee that the <style> element we use for adding the
// CSS that generates the a11y violation indicator exists in the dom
export function ensureA11yCheckerStyleElement(doc) {
  let styleElem = doc.getElementById(A11Y_CHECKER_STYLE_ELEM_ID)
  if (!styleElem) {
    styleElem = doc.createElement('style')
    styleElem.id = A11Y_CHECKER_STYLE_ELEM_ID
    doc.head.appendChild(styleElem)
  }
  return styleElem
}

// highlight the given element
export default function indicate(elem) {
  const doc = elem.ownerDocument
  const styleElem = ensureA11yCheckerStyleElement(doc)
  const selector = buildDepthSelector(elem)
  styleElem.textContent = `${selector}{${INDICATOR_STYLE}}`
}
