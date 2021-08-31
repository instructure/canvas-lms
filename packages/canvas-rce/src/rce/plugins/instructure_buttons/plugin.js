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

import bridge from '../../../bridge'
import formatMessage from '../../../format-message'
import {isOKToLink} from '../../contentInsertionUtils'
import clickCallback, {CREATE_BUTTON, LIST_BUTTON, EDIT_BUTTON} from './clickCallback'
import registerEditToolbar from './registerEditToolbar'

function getMenuItems() {
  return [
    {
      text: formatMessage('Create Button and Icon'),
      value: 'instructure_create_button'
    },
    {
      text: formatMessage('Saved Buttons and Icons'),
      value: 'instructure_list_buttons'
    }
  ]
}

function handleOptionSelected(ed, value) {
  switch (value) {
    case 'instructure_create_button':
      ed.focus(true)
      ed.execCommand('instructureTrayForButtonsPlugin', false, CREATE_BUTTON)
      break
    case 'instructure_list_buttons':
      ed.focus(true)
      ed.execCommand('instructureTrayForButtonsPlugin', false, LIST_BUTTON)
      break
    case 'instructure_edit_button':
      ed.focus(true)
      ed.execCommand('instructureTrayForButtonsPlugin', false, EDIT_BUTTON)
      break
  }
}

tinymce.create('tinymce.plugins.InstructureButtonsPlugin', {
  init(ed) {
    // Register tray control command
    ed.addCommand('instructureTrayForButtonsPlugin', (_ui, type) => {
      if (type === LIST_BUTTON) {
        bridge.showTrayForPlugin(type, ed.id)
      } else {
        clickCallback(ed, document, type)
      }
    })

    // Register menu items
    ed.ui.registry.addNestedMenuItem('instructure_buttons', {
      text: formatMessage('Buttons and Icons'),
      icon: 'buttons',
      getSubmenuItems: () =>
        getMenuItems().map(item => ({
          type: 'menuitem',
          text: item.text,
          onAction: () => handleOptionSelected(ed, item.value),
          onSetup: api => {
            api.setDisabled(!isOKToLink(ed.selection.getContent()))
            return () => {}
          }
        }))
    })

    // Register button
    ed.ui.registry.addSplitButton('instructure_buttons', {
      tooltip: formatMessage('Buttons and Icons'),
      icon: 'buttons',
      fetch(callback) {
        const items = getMenuItems().map(item => ({
          type: 'choiceitem',
          text: item.text,
          value: item.value
        }))
        callback(items)
      },
      onAction(api) {
        if (!api.isDisabled()) {
          handleOptionSelected(ed, 'instructure_create_button')
        }
      },
      onItemAction: (_splitButtonApi, value) => handleOptionSelected(ed, value),
      onSetup(api) {
        function handleNodeChange(_e) {
          api.setDisabled(!isOKToLink(ed.selection.getContent()))
        }
        setTimeout(handleNodeChange)
        ed.on('NodeChange', handleNodeChange)
        return () => {
          ed.off('NodeChange', handleNodeChange)
        }
      }
    })

    // Register context toolbar for editing existing buttons / icons
    registerEditToolbar(ed, (api) => {
      if (!api.isDisabled()) {
        handleOptionSelected(ed, 'instructure_edit_button')
      }
    })
  }
})

// Register plugin
tinymce.PluginManager.add('instructure_buttons', tinymce.plugins.InstructureButtonsPlugin)
