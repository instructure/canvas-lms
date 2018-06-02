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

tinymce.create("tinymce.plugins.InstructureEquation", {
  init(ed) {
    ed.addCommand(
      "instructureEquation",
      clickCallback.bind(this, ed, document)
    );

    ed.addButton("instructure_equation", {
      title: htmlEscape(
        formatMessage({
          default: "Insert Math Equation",
          description: "Title for RCE button to insert a math equation"
        })
      ),
      cmd: "instructureEquation",
      icon: "equation icon-equation",
      onPostRender: function() {
        var btn = this;
        ed.on("NodeChange", e => {
          btn.active(e.nodeName == "IMG" && e.className == "equation_image");
        });
      }
    });
  }
});

// Register plugin
tinymce.PluginManager.add(
  "instructure_equation",
  tinymce.plugins.InstructureEquation
);
