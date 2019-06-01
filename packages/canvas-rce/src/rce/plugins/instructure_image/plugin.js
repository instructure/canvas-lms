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

import formatMessage from "../../../format-message";
import clickCallback from "./clickCallback";
import bridge from '../../../bridge'

const PLUGIN_KEY = 'images'

tinymce.create("tinymce.plugins.InstructureImagePlugin", {
  init(ed) {
    // Register commands
    ed.addCommand(
      "mceInstructureImage",
      clickCallback.bind(this, ed, document)
    );

    // Register buttons
    ed.ui.registry.addMenuButton("instructure_image", {
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
            onAction: () => ed.execCommand("mceInstructureImage"),
          },

          {
            type: 'menuitem',
            text: formatMessage('Course Images'), // This item needs to be adjusted to be user/context aware, i.e. User Images
            onAction() {
              ed.focus(true) // activate the editor without changing focus
              bridge.showTrayForPlugin(PLUGIN_KEY)
            }
          }
        ]
        callback(items);
      }
    });
  }
});

// Register plugin
tinymce.PluginManager.add(
  "instructure_image",
  tinymce.plugins.InstructureImagePlugin
);
