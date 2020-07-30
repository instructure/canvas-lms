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

tinymce.create('tinymce.plugins.InstructureImagePlugin', {
  init(editor) {
    const contextType = editor.settings.canvas_rce_user_context.type

    // Register commands
    editor.addCommand('mceInstructureImage', clickCallback.bind(this, editor, document))
    editor.addCommand('instructureTrayForImages', (ui, plugin_key) => {
      bridge.showTrayForPlugin(plugin_key, editor.id)
    })

    // Register menu items
    editor.ui.registry.addNestedMenuItem('instructure_image', {
      text: formatMessage('Image'),
      icon: 'image',
      getSubmenuItems: () => [
        'instructure_upload_image',
        'instructure_course_image',
        'instructure_user_image'
      ]
    })
    editor.ui.registry.addMenuItem('instructure_upload_image', {
      text: formatMessage('Upload Image'),
      onAction: () => editor.execCommand('mceInstructureImage')
    })
    if (contextType === 'course') {
      editor.ui.registry.addMenuItem('instructure_course_image', {
        text: formatMessage('Course Images'),
        onAction: () => {
          editor.focus(true)
          editor.execCommand('instructureTrayForImages', false, COURSE_PLUGIN_KEY)
        }
      })
    }
    editor.ui.registry.addMenuItem('instructure_user_image', {
      text: formatMessage('User Images'),
      onAction: () => {
        editor.focus(true)
        editor.execCommand('instructureTrayForImages', false, USER_PLUGIN_KEY)
      }
    })

    // Register buttons
    editor.ui.registry.addMenuButton('instructure_image', {
      tooltip: formatMessage('Images'),
      icon: 'image',

      fetch(callback) {
        const items = [
          {
            type: 'menuitem',
            text: formatMessage('Upload Image'),
            onAction: () => editor.execCommand('mceInstructureImage')
          },
          {
            type: 'menuitem',
            text: formatMessage('User Images'),
            onAction() {
              editor.focus(true)
              editor.execCommand('instructureTrayForImages', false, USER_PLUGIN_KEY)
            }
          }
        ]

        if (contextType === 'course') {
          items.splice(1, 0, {
            type: 'menuitem',
            text: formatMessage('Course Images'),
            onAction() {
              editor.focus(true) // activate the editor without changing focus
              editor.execCommand('instructureTrayForImages', false, COURSE_PLUGIN_KEY)
            }
          })
        }

        callback(items)
      },
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
      predicate: isImageEmbed,
      scope: 'node'
    })
  },

  remove(editor) {
    trayController.hideTrayForEditor(editor)
  }
})

// Register plugin
tinymce.PluginManager.add('instructure_image', tinymce.plugins.InstructureImagePlugin)
