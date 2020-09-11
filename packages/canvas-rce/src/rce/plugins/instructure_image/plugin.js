/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import bridge from '../../../bridge'
import {isImageEmbed} from '../shared/ContentSelection'
import {isOKToLink} from '../../contentInsertionUtils'
import TrayController from './ImageOptionsTray/TrayController'
import clickCallback from './clickCallback'

const COURSE_PLUGIN_KEY = 'course_images'
const USER_PLUGIN_KEY = 'user_images'

const trayController = new TrayController()

function getMenuItems(ed) {
  const contextType = ed.settings.canvas_rce_user_context.type
  const items = [
    {
      text: formatMessage('Upload Image'),
      value: 'instructure_upload_image'
    }
  ]
  if (contextType === 'course') {
    items.push({
      text: formatMessage('Course Images'),
      value: 'instructure_course_image'
    })
  }
  items.push({
    text: formatMessage('User Images'),
    value: 'instructure_user_image'
  })
  return items
}

function doMenuItem(ed, value) {
  switch (value) {
    case 'instructure_upload_image':
      ed.execCommand('mceInstructureImage')
      break
    case 'instructure_course_image':
      ed.focus(true)
      ed.execCommand('instructureTrayForImages', false, COURSE_PLUGIN_KEY)
      break
    case 'instructure_user_image':
      ed.focus(true)
      ed.execCommand('instructureTrayForImages', false, USER_PLUGIN_KEY)
      break
  }
}

tinymce.create('tinymce.plugins.InstructureImagePlugin', {
  init(editor) {
    // Register commands
    editor.addCommand('mceInstructureImage', clickCallback.bind(this, editor, document))
    editor.addCommand('instructureTrayForImages', (ui, plugin_key) => {
      bridge.showTrayForPlugin(plugin_key, editor.id)
    })

    // Register menu items
    editor.ui.registry.addNestedMenuItem('instructure_image', {
      text: formatMessage('Image'),
      icon: 'image',
      getSubmenuItems: () =>
        getMenuItems(editor).map(item => {
          return {
            type: 'menuitem',
            text: item.text,
            onAction: () => doMenuItem(editor, item.value)
          }
        })
    })

    // Register buttons
    editor.ui.registry.addSplitButton('instructure_image', {
      tooltip: formatMessage('Images'),
      icon: 'image',
      fetch(callback) {
        const items = getMenuItems(editor).map(item => {
          return {
            type: 'choiceitem',
            text: item.text,
            value: item.value
          }
        })
        callback(items)
      },
      onAction() {
        doMenuItem(editor, 'instructure_upload_image')
      },
      onItemAction: (_splitButtonApi, value) => doMenuItem(editor, value),
      onSetup(api) {
        function handleNodeChange(_e) {
          api.setDisabled(!isOKToLink(editor.selection.getContent()))
        }
        editor.on('NodeChange', handleNodeChange)
        return () => {
          editor.off('NodeChange', handleNodeChange)
        }
      }
    })

    /*
     * Register the Image "Options" button that will open the Image Options
     * tray.
     */

    function canUpdateImageProps(node) {
      return !node.classList.contains('equation_image') && isImageEmbed(node)
    }
    const buttonAriaLabel = formatMessage('Show image options')
    editor.ui.registry.addButton('instructure-image-options', {
      onAction(/* buttonApi */) {
        // show the tray
        trayController.showTrayForEditor(editor)
      },

      text: formatMessage('Image Options'),
      tooltip: buttonAriaLabel
    })

    editor.ui.registry.addContextToolbar('instructure-image-toolbar', {
      items: 'instructure-image-options',
      position: 'node',
      predicate: canUpdateImageProps,
      scope: 'node'
    })
  },

  remove(editor) {
    trayController.hideTrayForEditor(editor)
  }
})

// Register plugin
tinymce.PluginManager.add('instructure_image', tinymce.plugins.InstructureImagePlugin)
