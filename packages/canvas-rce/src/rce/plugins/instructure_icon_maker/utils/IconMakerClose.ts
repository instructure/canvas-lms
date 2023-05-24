// @ts-nocheck
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

export const ICON_MAKER_ADD_IMAGE_MENU_ID = 'AddImageMenu'

export const shouldIgnoreClose = (target: HTMLElement, editorId?: string): boolean => {
  try {
    if (editorId) {
      return (
        elementTreeHasAttribute(target, 'data-position-content', ICON_MAKER_ADD_IMAGE_MENU_ID) ||
        elementTreeHasAttribute(target, 'data-id', editorId)
      )
    } else {
      return elementTreeHasAttribute(target, 'data-position-content', ICON_MAKER_ADD_IMAGE_MENU_ID)
    }
  } catch (e) {
    return false
  }
}

const elementTreeHasAttribute = (
  target: HTMLElement | null,
  attribute: string,
  value: string
): boolean => {
  while (target) {
    if (target?.attributes?.[attribute]?.value === value) {
      return true
    }
    target = target?.parentElement
  }
  return false
}
