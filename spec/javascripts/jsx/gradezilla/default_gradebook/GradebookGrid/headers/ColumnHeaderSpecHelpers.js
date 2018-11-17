/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

function mouseover($el) {
  const event = new MouseEvent('mouseover', {
    bubbles: true,
    cancelable: true,
    view: window
  })
  $el.dispatchEvent(event)
}

function getMenuItemWithLabel($parent, label) {
  const $children = [...$parent.querySelectorAll('[role^="menuitem"]')]
  return $children.find($child => $child.textContent.trim() === label)
}

function getFlyoutWithLabel($parent, label) {
  const $children = [...$parent.querySelectorAll('[role="button"]')]
  return $children.find($child => $child.textContent.trim() === label)
}

function getSubmenu($menuItem) {
  return document.querySelector(`[aria-labelledby="${$menuItem.id}"]`)
}

export function getMenuContent($menu, ...path) {
  return path.reduce(($el, label) => {
    const $next = getFlyoutWithLabel($el, label)
    mouseover($next)
    return getSubmenu($next)
  }, $menu)
}

export function getMenuItem($menu, ...path) {
  return path.reduce(($el, label, index) => {
    if (index < path.length - 1) {
      const $next = getFlyoutWithLabel($el, label)
      mouseover($next)
      return getSubmenu($next)
    }

    return getMenuItemWithLabel($el, label) || getFlyoutWithLabel($el, label)
  }, $menu)
}

export function blurElement($el) {
  $el.blur()
  const event = new Event('blur', {bubbles: true, cancelable: true})
  $el.dispatchEvent(event)
}
