/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import $ from 'jquery'

// Shared focus management for collaborator list views.
// Moves focus to the item at currentIndex after a render, falling back to
// adjacent items or the first visible button in the picker.
export function updateCollaboratorFocus($el, currentIndex) {
  let $target = $($el.find('li').get(currentIndex)).find('button')
  if ($target.length === 0) {
    $target = $($el.find('li').get(currentIndex - 1)).find('button')
  }
  if ($target.length === 0) {
    $target = $el.find('li button').first()
  }
  if ($target.length === 0) {
    $target = $el
      .parents('.collaborator-picker')
      .find('.list-wrapper:first ul:visible button')
      .first()
  }
  if ($target.length > 0) {
    const targetElement = $target[0]
    if (document.activeElement) {
      document.activeElement.blur()
    }
    setTimeout(() => {
      targetElement.focus()
    }, 100)
  }
}
