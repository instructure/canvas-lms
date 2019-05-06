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
  }
});

// Register plugin
tinymce.PluginManager.add(
  "instructure_record",
  tinymce.plugins.InstructureRecord
);
