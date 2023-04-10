/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import tinymce, {Editor} from 'tinymce'
import {isStudioEmbeddedMedia, handleBeforeObjectSelected} from '../shared/StudioLtiSupportUtils'
import VideoTrayController from '../instructure_record/VideoOptionsTray/TrayController'
import formatMessage from '../../../format-message'

const studioTrayController = new VideoTrayController()

tinymce.PluginManager.add('instructure_studio_media_options', function (ed: Editor) {
  ed.ui.registry.addButton('studio-media-options', {
    onAction() {
      studioTrayController.showTrayForEditor(ed)
    },
    text: formatMessage('Studio Media Options'),
    tooltip: formatMessage('Show Studio media options'),
  })

  ed.ui.registry.addContextToolbar('studio-media-options-toolbar', {
    items: 'studio-media-options',
    position: 'node',
    predicate: isStudioEmbeddedMedia,
    scope: 'node',
  })

  ed.on('BeforeObjectSelected', handleBeforeObjectSelected)

  ed.on('remove', editor => {
    studioTrayController.hideTrayForEditor(editor)
  })
})
