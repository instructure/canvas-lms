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

const htmlEl = document.documentElement

let defaultDir
function getDefaultDir() {
  /**
   * use a cached value for the default of <html> element's "dir" so we don't
   * have to call the expensive getComputedStyle to look it it up every time
   */
  if (defaultDir) return defaultDir
  defaultDir = htmlEl.getAttribute('dir') || getComputedStyle(htmlEl, null).direction
  return defaultDir
}

/**
 * @param {Element} element, will use the <html> element by default
 * @returns {Boolean}
 */
export function isRTL(element) {
  return getDirection(element) === 'rtl'
}

const flipped = {
  left: 'right',
  right: 'left',
}

/**
 * works exactly like our sass helper named the same thing
 * @param {String} leftOrRight "left" or "right"
 * @param {ElementToCheck} [element], will use the <html> element by default
 * @returns {String} 'left' or 'right' (or `undefined` if no DOM is present)
 */
export function direction(leftOrRight, element) {
  if (leftOrRight !== 'left' && leftOrRight !== 'right')
    throw new Error('expected either left or right')
  return isRTL(element) ? flipped[leftOrRight] : leftOrRight
}

/**
 * Return the direction ('ltr' or 'rtl') of an element
 * @param {Element} [element], will use the <html> element by default
 * @returns {String} 'ltr' or 'rtl' (or `undefined` if no DOM is present)
 */
export function getDirection(element) {
  if (typeof element === 'undefined' || element === htmlEl) return getDefaultDir()
  return element.getAttribute('dir') || getComputedStyle(element, null).direction
}
