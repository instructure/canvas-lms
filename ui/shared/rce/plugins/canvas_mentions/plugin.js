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

export const name = 'canvas_mentions'

function onInputChange() {
  const tinySelection = tinymce.activeEditor.selection

  if (mentionWasInitiated(tinySelection.getSel())) {
    console.log('Mount the mentions component!')
  }
}

export const pluginDefinition = {
  init(editor) {
    // TODO: Remove console log
    console.log('@mentions plugin loaded')
    editor.on('input', onInputChange)
  }
}

tinymce.create('tinymce.plugins.CanvasMentionsPlugin', pluginDefinition)
tinymce.PluginManager.add(name, tinymce.plugins.CanvasMentionsPlugin)
