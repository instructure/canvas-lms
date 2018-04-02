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

tinymce.create("tinymce.plugins.InstructureImagePlugin", {
  init: function(ed) {
    // Register commands
    ed.addCommand(
      "mceInstructureImage",
      clickCallback.bind(this, ed, document)
    );

    // Register buttons
    ed.addButton("instructure_image", {
      title: htmlEscape(
        formatMessage({
          default: "Embed Image",
          description: "Title for RCE button to embed an image"
        })
      ),
      cmd: "mceInstructureImage",
      icon: "image",
      onPostRender: function() {
        // highlight our button when an image is selected
        var btn = this;
        ed.on("NodeChange", function(event) {
          btn.active(
            event.nodeName == "IMG" && event.className != "equation_image"
          );
        });
      }
    });
  },

  getInfo: function() {
    return {
      longname: "Instructure image",
      author: "Instructure",
      authorurl: "http://instructure.com",
      infourl: "http://instructure.com",
      version: "1"
    };
  }
});

// Register plugin
tinymce.PluginManager.add(
  "instructure_image",
  tinymce.plugins.InstructureImagePlugin
);
