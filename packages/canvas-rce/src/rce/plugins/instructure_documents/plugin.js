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
import {isOKToLink} from '../../contentInsertionUtils'

const COURSE_PLUGIN_KEY = 'course_documents'
const USER_PLUGIN_KEY = 'user_documents'

tinymce.create('tinymce.plugins.InstructureDocumentsPlugin', {
  init(ed) {
    const contextType = ed.settings.canvas_rce_user_context.type

    // Register commands
    ed.addCommand('mceInstructureDocuments', clickCallback.bind(this, ed, document))
    ed.addCommand('instructureTrayForDocuments', (ui, plugin_key) => {
      bridge.showTrayForPlugin(plugin_key, ed.id)
    })

    // Register menu items
    ed.ui.registry.addNestedMenuItem('instructure_document', {
      text: formatMessage('Document'),
      icon: 'document',
      getSubmenuItems: () => [
        'instructure_upload_document',
        'instructure_course_document',
        'instructure_user_document'
      ]
    })
    ed.ui.registry.addMenuItem('instructure_upload_document', {
      text: formatMessage('Upload Document'),
      onAction: () => ed.execCommand('mceInstructureDocuments')
    })
    if (contextType === 'course') {
      ed.ui.registry.addMenuItem('instructure_course_document', {
        text: formatMessage('Course Documents'),
        onAction: () => {
          ed.focus(true)
          ed.execCommand('instructureTrayForDocuments', false, COURSE_PLUGIN_KEY)
        }
      })
    }
    ed.ui.registry.addMenuItem('instructure_user_document', {
      text: formatMessage('User Documents'),
      onAction: () => {
        ed.focus(true)
        ed.execCommand('instructureTrayForDocuments', false, USER_PLUGIN_KEY)
      }
    })

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
          ed.execCommand('instructureTrayForDocuments', false, USER_PLUGIN_KEY)
        }
      }
    ]
    if (contextType === 'course') {
      menuItems.splice(1, 0, {
        type: 'menuitem',
        text: formatMessage('Course Documents'),
        onAction() {
          ed.focus(true) // activate the editor without changing focus
          ed.execCommand('instructureTrayForDocuments', false, COURSE_PLUGIN_KEY)
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
      },
      onSetup(api) {
        function handleNodeChange(_e) {
          api.setDisabled(!isOKToLink(ed.selection.getContent()))
        }
        ed.on('NodeChange', handleNodeChange)
        return () => {
          ed.off('NodeChange', handleNodeChange)
        }
      }
    })
  }
})

// Register plugin
tinymce.PluginManager.add('instructure_documents', tinymce.plugins.InstructureDocumentsPlugin)
