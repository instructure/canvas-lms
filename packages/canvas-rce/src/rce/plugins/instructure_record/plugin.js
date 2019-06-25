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

import htmlEscape from "escape-html";
import clickCallback from "./clickCallback";
import formatMessage from "../../../format-message";
import TrayController from './VideoOptionsTray/TrayController'
import {getContentFromElement, VIDEO_EMBED_TYPE} from '../shared/ContentSelection'
import {globalRegistry} from '../instructure-context-bindings/BindingRegistry'

const trayController = new TrayController()

tinymce.create("tinymce.plugins.InstructureRecord", {
  init: function(ed) {
    ed.addCommand("instructureRecord", clickCallback.bind(this, ed, document));
    ed.ui.registry.addMenuButton("instructure_record", {
      tooltip: htmlEscape(
        formatMessage({
          default: "Record/Upload Media",
          description: "Title for RCE button to insert or record media"
        })
      ),
      icon: "video",
      fetch(callback) {
        const items = [
          {
            type: 'menuitem',
            text: formatMessage('Upload/Record Media'),
            onAction: () => ed.execCommand("instructureRecord"),
          },

          {
            type: 'menuitem',
            text: formatMessage('Course Media'), // This item needs to be adjusted to be user/context aware, i.e. Use Media
            onAction() {
              ed.focus(true) // activate the editor without changing focus
            }
          }
        ]
        callback(items);
      }
    });

    /*
     * Register the Video "Options" button that will open the Video Options
     * tray.
     */
    const buttonAriaLabel = formatMessage('Show video options')
    ed.ui.registry.addButton('instructure-video-options', {
      onAction() {
        // show the tray
        trayController.showTrayForEditor(ed)
      },

      onSetup() {
        globalRegistry.bindToolbarToEditor(ed, buttonAriaLabel)
      },

      text: formatMessage('Options'),
      tooltip: buttonAriaLabel
    });

    const defaultFocusSelector = `.tox-pop__dialog button[aria-label="${buttonAriaLabel}"]`
    globalRegistry.addContextKeydownListener(ed, defaultFocusSelector)

    function isVideoElement($el) {
      return getContentFromElement($el).type === VIDEO_EMBED_TYPE
    }

    ed.ui.registry.addContextToolbar('instructure-video-toolbar', {
      items: 'instructure-video-options',
      position: 'node',
      predicate: false,
      scope: 'node'
    })
  },
  remove(editor) {
    trayController.hideTrayForEditor(editor)
  }
});

// Register plugin
tinymce.PluginManager.add(
  "instructure_record",
  tinymce.plugins.InstructureRecord
);
