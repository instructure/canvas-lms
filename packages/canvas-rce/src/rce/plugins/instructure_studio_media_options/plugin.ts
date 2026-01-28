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

import tinymce, {Editor, Events} from 'tinymce'
import {
  isStudioEmbeddedMedia,
  handleBeforeObjectSelected,
  notifyStudioEmbedTypeChange,
  updateStudioIframeDimensions,
  validateStudioEmbedTypeChangeResponse,
} from '../shared/StudioLtiSupportUtils'
import VideoTrayController from '../instructure_record/VideoOptionsTray/TrayController'
import formatMessage from '../../../format-message'
import RCEGlobals from '../../RCEGlobals'
import {
  thumbnailViewIcon,
  learnViewIcon,
  collabViewIcon,
  optionsIcon,
  removeIcon,
} from './studioToolbarIcons'

const studioTrayController = new VideoTrayController()

const handleStudioMessage = (e: MessageEvent) => {
  // can be extended in the future to handle more message types from Studio LTI
  switch (e.data?.subject) {
    case 'studio.embedTypeChanged.response':
      if (validateStudioEmbedTypeChangeResponse(e.data)) {
        updateStudioIframeDimensions(tinymce.activeEditor, e.data)
      }

      break

    default:
      return
  }
}

const isEmbedButtonActive = (buttonName: string, currentSelectedElement: Element) => {
  return (currentSelectedElement.getAttribute('data-mce-p-src') || '').includes(buttonName)
}

tinymce.PluginManager.add('instructure_studio_media_options', function (ed: Editor) {
  if (RCEGlobals.getFeatures().rce_studio_embed_improvements) {
    window.addEventListener('message', handleStudioMessage)

    ed.on('init', () => {
      const existingStyle = document.getElementById('studio-toolbar-styles')
      if (!existingStyle) {
        const style = document.createElement('style')
        style.id = 'studio-toolbar-styles'
        style.textContent = `
        .tox .tox-pop .tox-tbtn {
          font-size: 16px;
          border-radius: 0;
        }

        .tox .tox-pop .tox-tbtn:hover {
          background-color: #2B7ABC;
          color: white;
        }

        .tox .tox-pop .tox-tbtn.tox-tbtn--enabled {
          background-color: #6A7883;
          color: white;
        }

        .tox .tox-pop .tox-tbtn.tox-tbtn--enabled:hover {
          background-color: #2B7ABC;
          color: white;
        }
      `
        document.head.appendChild(style)
      }
    })

    ed.ui.registry.addIcon('thumbnail-view-icon', thumbnailViewIcon)
    ed.ui.registry.addIcon('learn-view-icon', learnViewIcon)
    ed.ui.registry.addIcon('collab-view-icon', collabViewIcon)
    ed.ui.registry.addIcon('options-icon', optionsIcon)
    ed.ui.registry.addIcon('remove-icon', removeIcon)

    ed.ui.registry.addToggleButton('thumbnail-view', {
      onSetup: buttonApi => {
        buttonApi.setActive(isEmbedButtonActive('thumbnail_embed', ed.selection.getNode()))
        const editorEventCallback = (eventApi: Events.NodeChangeEvent) => {
          buttonApi.setActive(isEmbedButtonActive('thumbnail_embed', eventApi.element))
        }
        ed.on('NodeChange', editorEventCallback)
        return () => ed.off('NodeChange', editorEventCallback)
      },
      onAction() {
        notifyStudioEmbedTypeChange(ed, 'thumbnail_embed')
      },
      icon: 'thumbnail-view-icon',
      text: formatMessage('Thumbnail'),
      tooltip: formatMessage('Thumbnail'),
    })

    ed.ui.registry.addToggleButton('learn-view', {
      onSetup: buttonApi => {
        buttonApi.setActive(isEmbedButtonActive('learn_embed', ed.selection.getNode()))
        const editorEventCallback = (eventApi: Events.NodeChangeEvent) => {
          buttonApi.setActive(isEmbedButtonActive('learn_embed', eventApi.element))
        }
        ed.on('NodeChange', editorEventCallback)
        return () => ed.off('NodeChange', editorEventCallback)
      },
      onAction() {
        notifyStudioEmbedTypeChange(ed, 'learn_embed')
      },
      icon: 'learn-view-icon',
      text: formatMessage('Learn'),
      tooltip: formatMessage('Learn'),
    })

    ed.ui.registry.addToggleButton('collab-view', {
      onSetup: buttonApi => {
        buttonApi.setActive(isEmbedButtonActive('collaboration_embed', ed.selection.getNode()))
        const editorEventCallback = (eventApi: Events.NodeChangeEvent) => {
          buttonApi.setActive(isEmbedButtonActive('collaboration_embed', eventApi.element))
        }
        ed.on('NodeChange', editorEventCallback)
        return () => ed.off('NodeChange', editorEventCallback)
      },
      onAction() {
        notifyStudioEmbedTypeChange(ed, 'collaboration_embed')
      },
      icon: 'collab-view-icon',
      text: formatMessage('Collab'),
      tooltip: formatMessage('Collab'),
    })

    ed.ui.registry.addButton('studio-media-options', {
      onAction() {
        if (!studioTrayController.isOpen) {
          studioTrayController.showTrayForEditor(ed)
          ed.focus()
        }
      },
      icon: 'options-icon',
      text: formatMessage('Options'),
      tooltip: formatMessage('Options'),
    })

    ed.ui.registry.addButton('remove-studio-media', {
      onAction() {
        const selectedElement = ed.selection.getNode()
        if (selectedElement && isStudioEmbeddedMedia(selectedElement)) {
          studioTrayController.hideTrayForEditor(ed)

          // Hide toolbar, reset selection
          ed.fire('hidecontexttoolbar')

          ed.dom.remove(selectedElement)
          ed.nodeChanged()
          ed.selection.select(ed.getBody())

          // Force focus back to editor
          ed.focus()
        }
      },
      icon: 'remove-icon',
      text: formatMessage('Remove'),
      tooltip: formatMessage('Remove Studio Media'),
    })

    ed.ui.registry.addContextToolbar('studio-extra-toolbar', {
      items:
        'thumbnail-view | learn-view | collab-view | studio-media-options | remove-studio-media',
      position: 'node',
      predicate: isStudioEmbeddedMedia,
      scope: 'node',
    })

    ed.on('NodeChange', (e: Events.NodeChangeEvent) => {
      if (isStudioEmbeddedMedia(e.element) && studioTrayController.isOpen) {
        studioTrayController.hideTrayForEditor(ed, true)
      }
    })
  } else {
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
  }

  ed.on('BeforeObjectSelected', handleBeforeObjectSelected)

  ed.on('remove', editor => {
    studioTrayController.hideTrayForEditor(editor)
  })
})
