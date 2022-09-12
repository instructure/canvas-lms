/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

export function hidden(elem) {
  const width = elem.offsetWidth,
    height = elem.offsetHeight

  return width === 0 && height === 0
}

export function visible(elem) {
  return !hidden(elem)
}

export function siblings(elem, selector) {
  const r = []
  const parent = elem.parentNode
  if (!parent) return r

  const candidates = Array.from(parent.querySelectorAll(selector))
  if (candidates.length === 0) return r

  let n = parent.firstChild
  for (; n; n = n.nextSibling) {
    if (n.nodeType === 1 && n !== elem && candidates.includes(n)) {
      r.push(n)
    }
  }
  return r
}

// start: the element where we start
// selector: find an ancestor to elem that matches this
// context: optional DOM element within which the matching element may be found
export function closest(start, selector, context) {
  const upperbound = context || document.body
  let elem = start
  while (elem) {
    if (elem.matches(selector)) {
      return elem
    }
    if (elem === upperbound) {
      return null
    }
    elem = elem.parentElement
  }
}

export function hide(elem) {
  setData(elem, 'olddisplay', elem.style.display)
  elem.style.display = 'none'
}

export function show(elem) {
  elem.style.display = getData(elem, 'olddisplay')
}

export function capitalize(word) {
  return word.replace(/^./, letter => letter.toUpperCase())
}

// this implementation of get|setData does not
// deal with elements being recreated in the dom
// but that seems to be OK
//
// If jquery exists, use it because if this file is used
// from canvas, there is other code that expects to use
// jquery data saved in enhanceUserContent, but if not
// so something useful anyway.
/* eslint-disable no-undef */
export function setData(elem, key, value) {
  if ($) {
    $(elem).data(key, value)
  } else {
    if (!elem.data) elem.data = {}
    elem.data[key] = value
  }
}

export function getData(elem, key) {
  if ($) {
    return $(elem).data(key)
  }
  return elem.data?.[key]
}
/* eslint-enable no-undef */

export function insertAfter(new_elem, reference_element) {
  reference_element.parentNode.insertBefore(new_elem, reference_element.nextSibling)
}
