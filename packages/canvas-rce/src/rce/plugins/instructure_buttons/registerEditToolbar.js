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

export const BUTTON_ID = 'inst-icon-maker-edit'
export const TOOLBAR_ID = 'inst-icon-maker-edit-toolbar'

export const ICON_MAKER_ATTRIBUTE = 'data-inst-icon-maker-icon'
export const ICON_MAKER_DOWNLOAD_URL_ATTR = 'data-download-url'
export const ICON_MAKER_ICONS = 'icon_maker_icons'

export const shouldShowEditButton = node => !!node?.getAttribute(ICON_MAKER_ATTRIBUTE)

export default function registerEditToolbar(editor, onAction) {
  addButton(editor, onAction)
  addContextToolbar(editor)
}

function addButton(editor, onAction) {
  editor.ui.registry.addButton(BUTTON_ID, {
    onAction,
    text: formatMessage('Edit'),
    tooltip: formatMessage('Edit Existing Icon Maker Icon')
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
