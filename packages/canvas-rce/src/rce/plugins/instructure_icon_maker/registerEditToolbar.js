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
import {BUTTON_ID, TOOLBAR_ID, ICON_MAKER_ATTRIBUTE} from './svg/constants'
import TrayController from '../instructure_image/ImageOptionsTray/TrayController'

export const shouldShowEditButton = node => !!node?.getAttribute(ICON_MAKER_ATTRIBUTE)
export const EDIT_ALT_TEXT_BUTTON_ID = 'inst-icon-maker-edit-alt-text'

const trayController = new TrayController()

export default function registerEditToolbar(editor, onAction) {
  addButton(editor, onAction)
  addAltTextButton(editor)
  addContextToolbar(editor)
}

function addButton(editor, onAction) {
  editor.ui.registry.addButton(BUTTON_ID, {
    onAction,
    text: formatMessage('Edit Icon'),
    tooltip: formatMessage('Edit Existing Icon Maker Icon'),
  })
}

function addAltTextButton(editor) {
  editor.ui.registry.addButton(EDIT_ALT_TEXT_BUTTON_ID, {
    onAction: () => {
      // show the Image Options tray
      trayController.showTrayForEditor(editor, true)
    },
    text: formatMessage('Icon Options'),
    tooltip: formatMessage('Edit alt text for this icon instance'),
  })
}

function addContextToolbar(editor) {
  editor.ui.registry.addContextToolbar(TOOLBAR_ID, {
    items: `${BUTTON_ID} ${EDIT_ALT_TEXT_BUTTON_ID}`,
    position: 'node',
    scope: 'node',
    predicate: shouldShowEditButton,
  })
}
