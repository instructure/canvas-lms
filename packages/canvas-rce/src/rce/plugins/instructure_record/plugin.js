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

import clickCallback from './clickCallback'
import bridge from '../../../bridge'
import formatMessage from '../../../format-message'
import TrayController from './VideoOptionsTray/TrayController'
import {isVideoElement} from '../shared/ContentSelection'

const trayController = new TrayController()

const COURSE_PLUGIN_KEY = 'course_media'
const USER_PLUGIN_KEY = 'user_media'

tinymce.create('tinymce.plugins.InstructureRecord', {
  init(ed) {
    const contextType = ed.settings.canvas_rce_user_context.type

    ed.addCommand('instructureRecord', clickCallback.bind(this, ed, document))
    ed.addCommand('instructureTrayForMedia', (ui, plugin_key) => {
      bridge.showTrayForPlugin(plugin_key)
    })

    ed.ui.registry.addMenuButton('instructure_record', {
      tooltip: formatMessage('Record/Upload Media'),
      icon: 'video',
      fetch(callback) {
        const items = [
          {
            type: 'menuitem',
            text: formatMessage('Upload/Record Media'),
            onAction: () => ed.execCommand('instructureRecord')
          },

          {
            type: 'menuitem',
            text: formatMessage('User Media'),
            onAction() {
              ed.focus(true)
              ed.execCommand('instructureTrayForMedia', false, USER_PLUGIN_KEY)
            }
          }
        ]

        if (contextType === 'course') {
          items.splice(1, 0, {
            type: 'menuitem',
            text: formatMessage('Course Media'),
            onAction() {
              ed.focus(true) // activate the editor without changing focus
              ed.execCommand('instructureTrayForMedia', false, COURSE_PLUGIN_KEY)
            }
          })
        }

        callback(items)
      }
    })

    /*
     * Register the Video "Options" button that will open the Video Options
     * tray.
     */
    const buttonAriaLabel = formatMessage('Show video options')
    ed.ui.registry.addButton('instructure-video-options', {
      onAction() {
        // show the tray
        trayController.showTrayForEditor(ed)
      },

      text: formatMessage('Options'),
      tooltip: buttonAriaLabel
    })

    ed.ui.registry.addContextToolbar('instructure-video-toolbar', {
      items: 'instructure-video-options',
      position: 'node',
      predicate: isVideoElement,
      scope: 'node'
    })
  },
  remove(editor) {
    trayController.hideTrayForEditor(editor)
  }
})

// Register plugin
tinymce.PluginManager.add('instructure_record', tinymce.plugins.InstructureRecord)
