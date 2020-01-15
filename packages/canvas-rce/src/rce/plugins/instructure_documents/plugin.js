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
import clickCallback from './clickCallback'
import bridge from '../../../bridge'

const COURSE_PLUGIN_KEY = 'course_documents'
const USER_PLUGIN_KEY = 'user_documents'

tinymce.create('tinymce.plugins.InstructureDocumentsPlugin', {
  init(ed) {
    const contextType = ed.settings.canvas_rce_user_context.type

    // Register commands
    ed.addCommand('mceInstructureDocuments', clickCallback.bind(this, ed, document))

    const menuItems = [
      {
        type: 'menuitem',
        text: formatMessage('Upload Document'),
        onAction: () => {
          ed.execCommand('mceInstructureDocuments')
        }
      },
      {
        type: 'menuitem',
        text: formatMessage('User Documents'),
        onAction() {
          ed.focus(true) // activate the editor without changing focus
          bridge.showTrayForPlugin(USER_PLUGIN_KEY)
        }
      }
    ]
    if (contextType === 'course') {
      menuItems.splice(1, 0, {
        type: 'menuitem',
        text: formatMessage('Course Documents'),
        onAction() {
          ed.focus(true) // activate the editor without changing focus
          bridge.showTrayForPlugin(COURSE_PLUGIN_KEY)
        }
      })
    }

    // Register button
    ed.ui.registry.addMenuButton('instructure_documents', {
      tooltip: formatMessage('Documents'),
      icon: 'document',
      fetch(callback) {
        const items = menuItems
        callback(items)
      }
    })
  }
})

// Register plugin
tinymce.PluginManager.add('instructure_documents', tinymce.plugins.InstructureDocumentsPlugin)
