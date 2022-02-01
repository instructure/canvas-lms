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

import formatMessage from '../../../format-message'

const BUTTON_ID = 'inst-button-and-icons-edit'
const TOOLBAR_ID = 'inst-button-and-icons-edit-toolbar'

export const BTN_AND_ICON_ATTRIBUTE = 'data-inst-buttons-and-icons'
export const BUTTONS_AND_ICONS = 'buttons_and_icons'

export const shouldShowEditButton = node => !!node?.getAttribute(BTN_AND_ICON_ATTRIBUTE)

export default function registerEditToolbar(editor, onAction) {
  addButton(editor, onAction)
  addContextToolbar(editor)
}

function addButton(editor, onAction) {
  editor.ui.registry.addButton(BUTTON_ID, {
    onAction,
    text: formatMessage('Edit'),
    tooltip: formatMessage('Edit Existing Button / Icon')
  })
}

function addContextToolbar(editor) {
  editor.ui.registry.addContextToolbar(TOOLBAR_ID, {
    items: BUTTON_ID,
    position: 'node',
    scope: 'node',
    predicate: shouldShowEditButton
  })
}
