/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {getContentFromElement, FILE_LINK_TYPE} from '../shared/ContentSelection'
import EmbedTrayController from './EmbedOptionsTray/EmbedOptionsTrayController'

const trayController = new EmbedTrayController()

tinymce.create('tinymce.plugins.InstructureEmbedsPlugin', {
  init(editor) {
    editor.addCommand('instructureTrayToEditEmbed', (ui, ed) => {
      trayController.showTrayForEditor(ed)
    })

    /*
     * Register the Embed "Options" button that will open the Embed Options
     * tray.
     */
    const buttonAriaLabel = formatMessage('Show embed options')
    editor.ui.registry.addButton('instructure-embed-options', {
      onAction(/* buttonApi */) {
        // show the tray
        editor.execCommand('instructureTrayToEditEmbed', false, editor)
      },

      text: formatMessage('Options'),
      tooltip: buttonAriaLabel
    })

    function isEmbeddable($element) {
      return getContentFromElement($element).type === FILE_LINK_TYPE
    }

    editor.ui.registry.addContextToolbar('instructure-embed-toolbar', {
      items: 'instructure-embed-options',
      position: 'node',
      predicate: isEmbeddable,
      scope: 'node'
    })
  },

  remove(editor) {
    trayController.hideTrayForEditor(editor)
  }
})

// Register plugin
tinymce.PluginManager.add('instructure-embeds', tinymce.plugins.InstructureEmbedsPlugin)
