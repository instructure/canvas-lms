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

// To get the right "tinymce" global object
import tinymce from '@instructure/canvas-rce/es/rce/tinyRCE'
import mentionWasInitiated from './mentionWasInitiated'
import {makeMarkerEditable} from './contentEditable'
import {onKeyDown, onKeyUp, onSetContent, onMouseDown} from './events'
import {MARKER_SELECTOR, MARKER_ID} from './constants'

export const name = 'canvas_mentions'

function onInputChange(_e, ed = false) {
  // editor objects are explicitly passed in unit tests
  const editor = ed || tinymce.activeEditor
  const tinySelection = editor.selection

  if (mentionWasInitiated(tinySelection.getSel())) {
    // Insert a "marker" node so we can find the cursor position
    // xsslint safeString.identifier MARKER_ID
    editor.execCommand(
      'mceInsertContent',
      false,
      `<span id="${MARKER_ID}" data-testid="${MARKER_ID}" aria-autocomplete="list" aria-controls="" aria-activedescendant=""></span>`
    )

    // Make the mentions marker editable for A11y
    makeMarkerEditable(editor, MARKER_SELECTOR)

    // TODO: Render the mentions component at that position
  }
}

export const pluginDefinition = {
  init(editor) {
    // TODO: Remove console log
    editor.on('input', onInputChange)
    editor.on('SetContent', onSetContent)
    editor.on('KeyDown', onKeyDown)
    editor.on('KeyUp', onKeyUp)
    editor.on('MouseDown', onMouseDown)
  }
}

tinymce.create('tinymce.plugins.CanvasMentionsPlugin', pluginDefinition)
tinymce.PluginManager.add(name, tinymce.plugins.CanvasMentionsPlugin)
