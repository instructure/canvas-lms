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
import tinymce, {Editor} from 'tinymce'

const COURSE_PLUGIN_KEY = 'course_documents'
const USER_PLUGIN_KEY = 'user_documents'
const GROUP_PLUGIN_KEY = 'group_documents'

function getMenuItems(ed: Editor) {
  const contextType = ed.settings.canvas_rce_user_context.type
  const items = [
    {
      text: formatMessage('Upload Document'),
      value: 'instructure_upload_document',
    },
  ]
  if (contextType === 'course') {
    items.push({
      text: formatMessage('Course Documents'),
      value: 'instructure_course_document',
    })
  } else if (contextType === 'group') {
    items.push({
      text: formatMessage('Group Documents'),
      value: 'instructure_group_document',
    })
  }
  items.push({
    text: formatMessage('User Documents'),
    value: 'instructure_user_document',
  })
  return items
}

function doMenuItem(ed: Editor, value: string) {
  switch (value) {
    case 'instructure_upload_document':
      ed.execCommand('mceInstructureDocuments')
      break
    case 'instructure_course_document':
      ed.focus(true)
      ed.execCommand('instructureTrayForDocuments', false, COURSE_PLUGIN_KEY)
      break
    case 'instructure_user_document':
      ed.focus(true)
      ed.execCommand('instructureTrayForDocuments', false, USER_PLUGIN_KEY)
      break
    case 'instructure_group_document':
      ed.focus(true)
      ed.execCommand('instructureTrayForDocuments', false, GROUP_PLUGIN_KEY)
      break
  }
}

// Register plugin
tinymce.PluginManager.add('instructure_documents', function (ed) {
  // Register commands
  ed.addCommand('mceInstructureDocuments', () => clickCallback(ed, document))
  ed.addCommand('instructureTrayForDocuments', (ui, plugin_key) => {
    bridge.showTrayForPlugin(plugin_key, ed.id)
  })

  // Register menu items
  ed.ui.registry.addNestedMenuItem('instructure_document', {
    text: formatMessage('Document'),
    icon: 'document',
    getSubmenuItems: () =>
      getMenuItems(ed).map(item => {
        return {
          type: 'menuitem',
          text: item.text,
          onAction: () => doMenuItem(ed, item.value),
          onSetup: api => {
            api.setDisabled(!isOKToLink(ed.selection.getContent()))
            return () => {}
          },
        }
      }),
  })

  // Register toolbar button
  ed.ui.registry.addMenuButton('instructure_documents', {
    tooltip: formatMessage('Documents'),
    icon: 'document',
    fetch: callback =>
      callback(
        getMenuItems(ed).map(item => ({
          type: 'menuitem',
          text: item.text,
          value: item.value,
          onAction: () => doMenuItem(ed, item.value),
        }))
      ),
    onSetup(api) {
      function handleNodeChange() {
        api.setDisabled(!isOKToLink(ed.selection.getContent()))
      }
      setTimeout(handleNodeChange)
      ed.on('NodeChange', handleNodeChange)
      return () => {
        ed.off('NodeChange', handleNodeChange)
      }
    },
  })
})
