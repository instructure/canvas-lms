// @ts-nocheck
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
import clickCallback, {CREATE_ICON_MAKER, EDIT_ICON_MAKER, LIST_ICON_MAKER} from './clickCallback'
import registerEditToolbar from './registerEditToolbar'
import tinymce, {Editor} from 'tinymce'

function getMenuItems() {
  return [
    {
      text: formatMessage('Create Icon Maker Icon'),
      value: 'instructure_create_icon_maker',
    },
    {
      text: formatMessage('Saved Icon Maker Icons'),
      value: 'instructure_list_icon_maker',
    },
  ]
}

function handleOptionSelected(ed: Editor, value: string) {
  switch (value) {
    case 'instructure_create_icon_maker':
      ed.focus(true)
      ed.execCommand('instructureTrayForIconMakerPlugin', false, CREATE_ICON_MAKER)
      break
    case 'instructure_list_icon_maker':
      ed.focus(true)
      ed.execCommand('instructureTrayForIconMakerPlugin', false, LIST_ICON_MAKER)
      break
    case 'instructure_edit_icon_maker':
      ed.focus(true)
      ed.execCommand('instructureTrayForIconMakerPlugin', false, EDIT_ICON_MAKER)
      break
  }
}

// Register plugin
tinymce.PluginManager.add('instructure_icon_maker', function (ed) {
  // Register tray control command
  ed.addCommand('instructureTrayForIconMakerPlugin', (_ui, type) => {
    if (type === LIST_ICON_MAKER) {
      bridge.showTrayForPlugin(type, ed.id)
    } else {
      clickCallback(ed, document, type)
    }
  })

  // Register menu items
  ed.ui.registry.addNestedMenuItem('instructure_icon_maker', {
    text: formatMessage('Icon Maker Icons'),
    icon: 'buttons',
    getSubmenuItems: () =>
      getMenuItems().map(item => ({
        type: 'menuitem',
        text: item.text,
        onAction: () => handleOptionSelected(ed, item.value),
        onSetup: api => {
          api.setDisabled(!isOKToLink(ed.selection.getContent()))
          return () => {}
        },
      })),
  })

  // Register button
  ed.ui.registry.addMenuButton('instructure_icon_maker', {
    tooltip: formatMessage('Icon Maker Icons'),
    icon: 'buttons',
    fetch: callback =>
      callback(
        getMenuItems().map(item => ({
          type: 'menuitem',
          text: item.text,
          value: item.value,
          onAction: () => handleOptionSelected(ed, item.value),
        }))
      ),
    onSetup(api) {
      function handleNodeChange(_e) {
        api.setDisabled(!isOKToLink(ed.selection.getContent()))
      }

      setTimeout(handleNodeChange)
      ed.on('NodeChange', handleNodeChange)
      return () => {
        ed.off('NodeChange', handleNodeChange)
      }
    },
  })

  // Register context toolbar for editing existing icon maker icons
  registerEditToolbar(ed, api => {
    if (!api.isDisabled()) {
      handleOptionSelected(ed, 'instructure_edit_icon_maker')
    }
  })
})
