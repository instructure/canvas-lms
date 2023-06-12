// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import tinymce from 'tinymce'
import formatMessage from '../../../format-message'
import bridge from '../../../bridge'
import {FS_ELEMENT} from '../../../util/fullscreenHelpers'

tinymce.PluginManager.add('instructure_fullscreen', function (editor) {
  editor.addCommand('instructureFullscreen', () => {
    bridge.activeEditor().toggleFullscreen()
  })

  editor.ui.registry.addMenuItem('instructure_fullscreen', {
    text: formatMessage('Fullscreen'),
    icon: 'fullscreen',
    onAction: () => editor.execCommand('instructureFullscreen'),
    onSetup(api) {
      api.setDisabled(!!document[FS_ELEMENT])
      return () => undefined
    },
  })

  editor.ui.registry.addMenuItem('instructure_exit_fullscreen', {
    text: formatMessage('Exit Fullscreen'),
    icon: 'fullscreen_exit',
    onAction: () => editor.execCommand('instructureFullscreen'),
    onSetup(api) {
      api.setDisabled(!document[FS_ELEMENT])
      return () => undefined
    },
  })
})
