/* * Copyright (C) 2021 - present Instructure, Inc.
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

export function makeSelection(wrapper, selectId, optionId) {
  const select = getSelect(wrapper, selectId)
  select.getDOMNode().click()
  const menu = getSelectMenu(select)
  menu.querySelector(`[id="${optionId}"]`).click()
}

export function getSelect(wrapper, selectId) {
  if (selectId) {
    return wrapper.find(`SelectMenu#${selectId}`)
  }
  return wrapper.find('SelectMenu')
}

export function getSelectMenu(select) {
  return document.getElementById(
    select
      .getDOMNode()
      .querySelector('[aria-haspopup="listbox"]')
      .getAttribute('aria-controls')
  )
}

export function getSelectMenuOptions(wrapper, selectId) {
  const select = getSelect(wrapper, selectId)
  let popupMenu = getSelectMenu(select)
  if (!popupMenu) {
    select.getDOMNode().click()
    popupMenu = getSelectMenu(select)
  }

  return popupMenu.querySelectorAll('[role="option"]')
}

export function selectedValue(wrapper, selectId) {
  return getSelect(wrapper, selectId)
    .getDOMNode()
    .querySelector('[aria-haspopup="listbox"]').value
}

export function isSelectDisabled(wrapper, selectId) {
  return getSelect(wrapper, selectId)
    .last()
    .getDOMNode()
    .querySelector('[aria-haspopup="listbox"]').disabled
}
