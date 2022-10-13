/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

export const TRIGGER_CHAR = '@'
export const MARKER_ID = 'mentions-marker'
export const MARKER_SELECTOR = `span#${MARKER_ID}`
export const MENTION_MENU_ID = 'mention-menu'
export const MENTION_MENU_SELECTOR = 'span#mention-menu'
export const TRUSTED_MESSAGE_ORIGIN = ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN

export const NAVIGATION_MESSAGE = 'mentions.NavigationEvent'
export const INPUT_CHANGE_MESSAGE = 'mentions.InputChangeEvent'
export const SELECTION_MESSAGE = 'mentions.SelectionEvent'

export const KEY_CODES = {
  backspace: 8,
  enter: 13,
  up: 38,
  down: 40,
  escape: 27,
  tab: 9,
}

export const KEY_NAMES = {
  [KEY_CODES.up]: 'UpArrow',
  [KEY_CODES.down]: 'DownArrow',
  [KEY_CODES.enter]: 'Enter',
}

export const ARIA_ID_TEMPLATES = {
  ariaControlTemplate: instanceId => {
    return `${instanceId}-mention-popup`
  },
  activeDescendant: (instanceId, itemId) => {
    return `${instanceId}-mention-popup-item-${itemId}`
  },
}
