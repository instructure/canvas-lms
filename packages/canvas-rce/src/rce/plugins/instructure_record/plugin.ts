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

import clickCallback from './clickCallback'
import bridge from '../../../bridge'
import formatMessage from '../../../format-message'
import VideoTrayController from './VideoOptionsTray/TrayController'
import AudioTrayController from './AudioOptionsTray/TrayController'
import {isAudioElement, isVideoElement} from '../shared/ContentSelection'
import {isOKToLink} from '../../contentInsertionUtils'
import tinymce from 'tinymce'

const videoTrayController = new VideoTrayController()
const audioTrayController = new AudioTrayController()

const COURSE_PLUGIN_KEY = 'course_media'
const USER_PLUGIN_KEY = 'user_media'
const GROUP_PLUGIN_KEY = 'group_media'

function getMenuItems(ed) {
  const contextType = ed.settings.canvas_rce_user_context.type
  const items: Array<{text: string; value: string}> = []
  if (ed.getParam('show_media_upload')) {
    // test if it's ok
    items.push({
      text: formatMessage('Upload/Record Media'),
      value: 'instructure_upload_media',
    })
  }
  if (contextType === 'course') {
    items.push({
      text: formatMessage('Course Media'),
      value: 'instructure_course_media',
    })
  } else if (contextType === 'group') {
    items.push({
      text: formatMessage('Group Media'),
      value: 'instructure_group_media',
    })
  }
  items.push({
    text: formatMessage('User Media'),
    value: 'instructure_user_media',
  })
  return items
}

function doMenuItem(ed, value) {
  switch (value) {
    case 'instructure_upload_media':
      ed.execCommand('instructureRecord')
      break
    case 'instructure_course_media':
      ed.focus(true)
      ed.execCommand('instructureTrayForMedia', false, COURSE_PLUGIN_KEY)
      break
    case 'instructure_group_media':
      ed.focus(true)
      ed.execCommand('instructureTrayForMedia', false, GROUP_PLUGIN_KEY)
      break
    case 'instructure_user_media':
      ed.focus(true)
      ed.execCommand('instructureTrayForMedia', false, USER_PLUGIN_KEY)
      break
  }
}

// Register plugin
tinymce.PluginManager.add('instructure_record', function (ed) {
  ed.addCommand('instructureRecord', () => clickCallback(ed, document))
  ed.addCommand('instructureTrayForMedia', (ui, plugin_key) => {
    bridge.showTrayForPlugin(plugin_key, ed.id)
  })

  // Register menu items
  ed.ui.registry.addNestedMenuItem('instructure_media', {
    text: formatMessage('Media'),
    icon: 'video',
    getSubmenuItems: () =>
      getMenuItems(ed).map(item => {
        return {
          type: 'menuitem',
          text: item.text,
          onAction: () => doMenuItem(ed, item.value),
          onSetup: api => {
            api.setDisabled(!isOKToLink(ed.selection.getContent()))
            return () => undefined
          },
        }
      }),
  })

  // Register buttons
  ed.ui.registry.addMenuButton('instructure_record', {
    tooltip: formatMessage('Record/Upload Media'),
    icon: 'video',
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

  /*
   * Register the Video "Options" button that will open the Video Options
   * tray.
   */
  const buttonAriaLabel = formatMessage('Show video options')
  ed.ui.registry.addButton('instructure-video-options', {
    onAction() {
      // show the tray
      videoTrayController.showTrayForEditor(ed)
    },

    text: formatMessage('Video Options'),
    tooltip: buttonAriaLabel,
  })

  ed.ui.registry.addContextToolbar('instructure-video-toolbar', {
    items: 'instructure-video-options',
    position: 'node',
    predicate: isVideoElement,
    scope: 'node',
  })

  ed.ui.registry.addButton('instructure-audio-options', {
    onAction() {
      audioTrayController.showTrayForEditor(ed)
    },
    text: formatMessage('Audio Options'),
    tooltip: formatMessage('Show audio options'),
  })

  ed.ui.registry.addContextToolbar('instructure-audio-toolbar', {
    items: 'instructure-audio-options',
    position: 'node',
    predicate: isAudioElement,
    scope: 'node',
  })

  ed.on('remove', editor => {
    audioTrayController.hideTrayForEditor(editor)
    videoTrayController.hideTrayForEditor(editor)
  })
})
