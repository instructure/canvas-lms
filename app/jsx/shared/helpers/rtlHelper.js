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


/**
 * @param {Element} element, will use the <html> element by default
 * @returns {Booean}
 */
export function isRTL(element) {
  return getDirection(element) === 'rtl'
}

/**
 * Return the direction ('ltr' or 'rtl') of an element
 * @param {Element} element, will use the <html> element by default
 * @returns {String} 'ltr' or 'rtl' (or `undefined` if no DOM is present)
 */
export function getDirection(element = document.documentElement){
  return window.getComputedStyle(element, null).direction
}