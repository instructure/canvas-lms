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

const MENU_CONTENT_REF_MAP = {
  'Sort by': 'sortByMenuContent',
  'Display as': 'displayAsMenuContent',
  'Secondary info': 'secondaryInfoMenuContent',
};

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

// the only requirement is that the individual spec files define their own
// `mountAndOpenOptions` function on `this`.
export function findMenuItem (props, ...path) {
  this.wrapper = this.mountAndOpenOptions(props);
  const $el = this.wrapper.instance().optionsMenuContent
  return getMenuItem($el, ...path)
}
