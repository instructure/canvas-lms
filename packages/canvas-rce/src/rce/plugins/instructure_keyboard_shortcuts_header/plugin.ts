/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
// @ts-expect-error
import {IconKeyboardShortcutsLine} from '@instructure/ui-icons/es/svg'

// Dynamically import the callback to avoid module resolution issues
const clickCallbackPromise = import('./clickCallback')

// @ts-expect-error: tinymce is available as a global variable
tinymce.PluginManager.add('instructure_keyboard_shortcuts_header', function (ed: any) {
  // Register custom icon
  ed.ui.registry.addIcon('keyboard-shortcuts', IconKeyboardShortcutsLine.src)

  ed.addCommand('instructureKeyboardShortcuts', () => {
    clickCallbackPromise.then(module => module.default(ed, document))
  })

  ed.ui.registry.addButton('instructure_keyboard_shortcuts_header', {
    icon: 'keyboard-shortcuts',
    tooltip: formatMessage('View keyboard shortcuts'),
    onAction: () => ed.execCommand('instructureKeyboardShortcuts'),
  })

  ed.ui.registry.addMenuItem('instructure_keyboard_shortcuts_header', {
    icon: 'keyboard-shortcuts',
    text: formatMessage('Keyboard Shortcuts'),
    onAction: () => ed.execCommand('instructureKeyboardShortcuts'),
  })
})
