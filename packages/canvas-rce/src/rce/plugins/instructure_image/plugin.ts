// @ts-nocheck
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
import {ICON_MAKER_ATTRIBUTE} from '../instructure_icon_maker/svg/constants'
import tinymce from 'tinymce'

const COURSE_PLUGIN_KEY = 'course_images'
const USER_PLUGIN_KEY = 'user_images'
const GROUP_PLUGIN_KEY = 'group_images'

const trayController = new TrayController()

function getMenuItems(ed) {
  const contextType = ed.settings.canvas_rce_user_context?.type
  const items = [
    {
      text: formatMessage('Upload Image'),
      value: 'instructure_upload_image',
    },
  ]
  if (contextType === 'course') {
    items.push({
      text: formatMessage('Course Images'),
      value: 'instructure_course_image',
    })
  } else if (contextType === 'group') {
    items.push({
      text: formatMessage('Group Images'),
      value: 'instructure_group_image',
    })
  }
  items.push({
    text: formatMessage('User Images'),
    value: 'instructure_user_image',
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
    case 'instructure_group_image':
      ed.focus(true)
      ed.execCommand('instructureTrayForImages', false, GROUP_PLUGIN_KEY)
      break
    case 'instructure_user_image':
      ed.focus(true)
      ed.execCommand('instructureTrayForImages', false, USER_PLUGIN_KEY)
      break
  }
}

tinymce.PluginManager.add('instructure_image', function (editor) {
  // Register commands
  editor.addCommand('mceInstructureImage', () => clickCallback(editor, document))
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
          onAction: () => doMenuItem(editor, item.value),
          onSetup: api => {
            api.setDisabled(!isOKToLink(editor.selection.getContent()))
            return () => {}
          },
        }
      }),
  })

  // Register toolbar button
  editor.ui.registry.addMenuButton('instructure_image', {
    tooltip: formatMessage('Images'),
    icon: 'image',
    fetch: callback =>
      callback(
        getMenuItems(editor).map(item => ({
          type: 'menuitem',
          text: item.text,
          value: item.value,
          onAction: () => doMenuItem(editor, item.value),
        }))
      ),
    onSetup(api) {
      function handleNodeChange(_e) {
        api.setDisabled(!isOKToLink(editor.selection.getContent()))
      }

      setTimeout(handleNodeChange)
      editor.on('NodeChange', handleNodeChange)
      return () => {
        editor.off('NodeChange', handleNodeChange)
      }
    },
  })

  /*
   * Register the Image "Options" button that will open the Image Options
   * tray.
   */

  function canUpdateImageProps(node: Element) {
    return (
      !node.classList.contains('equation_image') &&
      isImageEmbed(node) &&
      // don't show for icon maker
      !node.getAttribute(ICON_MAKER_ATTRIBUTE)
    )
  }

  const buttonAriaLabel = formatMessage('Show image options')
  editor.ui.registry.addButton('instructure-image-options', {
    onAction(/* buttonApi */) {
      // show the tray
      trayController.showTrayForEditor(editor)
    },

    text: formatMessage('Image Options'),
    tooltip: buttonAriaLabel,
  })

  editor.ui.registry.addContextToolbar('instructure-image-toolbar', {
    items: 'instructure-image-options',
    position: 'node',
    predicate: canUpdateImageProps,
    scope: 'node',
  })

  editor.on('remove', ed => trayController.hideTrayForEditor(ed))
})
