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

import $ from 'jquery'
import htmlEscape from 'escape-html'

import formatMessage from '../../../format-message'
import bridge from '../../../bridge'
import TrayController from './ImageOptionsTray/TrayController'
import clickCallback from './clickCallback'

const PLUGIN_KEY = 'images'

import {globalRegistry} from '../instructure-context-bindings/BindingRegistry'

const trayController = new TrayController()

tinymce.create('tinymce.plugins.InstructureImagePlugin', {
  init(editor) {
    // Register commands
    editor.addCommand(
      "mceInstructureImage",
      clickCallback.bind(this, editor, document)
    );

    // Register buttons
    editor.ui.registry.addMenuButton("instructure_image", {
      tooltip: htmlEscape(
        formatMessage({
          default: "Images",
          description: "Title for RCE button to embed an image"
        })
      ),

      icon: "image",

      fetch(callback) {
        const items = [
          {
            type: 'menuitem',
            text: formatMessage('Upload Image'),
            onAction: () => editor.execCommand('mceInstructureImage'),
          },

          {
            type: 'menuitem',
            text: formatMessage('Course Images'), // This item needs to be adjusted to be user/context aware, i.e. User Images
            onAction() {
              editor.focus(true) // activate the editor without changing focus
              bridge.showTrayForPlugin(PLUGIN_KEY)
            }
          }
        ]
        callback(items);
      }
    });

    /*
     * Register the Image "Options" button that will open the Image Options
     * tray.
     */
    const buttonAriaLabel = formatMessage('Show image options')
    editor.ui.registry.addButton('instructure-image-options', {
      onAction(buttonApi) {
        // show the tray
        trayController.showTrayForEditor(editor)
      },

      onSetup(buttonApi) {
        globalRegistry.bindToolbarToEditor(editor, buttonAriaLabel)
      },

      text: formatMessage('Options'),
      tooltip: buttonAriaLabel
    });

    const defaultFocusSelector = `.tox-pop__dialog button[aria-label="${buttonAriaLabel}"]`
    globalRegistry.addContextKeydownListener(editor, defaultFocusSelector)

    function isImageElement($el) {
      return $el.nodeName.toLowerCase() === 'img'
    }

    editor.ui.registry.addContextToolbar('instructure-image-toolbar', {
      items: 'instructure-image-options',
      position: 'node',
      predicate: isImageElement,
      scope: 'node'
    })
  },

  destroy() {
    trayController.hideTrayForEditor(editor)
  }
});

// Register plugin
tinymce.PluginManager.add(
  "instructure_image",
  tinymce.plugins.InstructureImagePlugin
);
