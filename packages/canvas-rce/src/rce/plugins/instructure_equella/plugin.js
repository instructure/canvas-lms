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

tinymce.create("tinymce.plugins.InstructureEquella", {
  init: function(ed) {
    ed.addCommand("instructureEquella", clickCallback.bind(this, ed, document));

    ed.addButton("instructure_equella", {
      title: htmlEscape(
        formatMessage({
          default: "Insert Equella Links",
          description: "Title for RCE button to insert links to Equella content"
        })
      ),
      cmd: "instructureEquella",
      icon: "equella icon-equella"
    });
  },

  getInfo: function() {
    return {
      longname: "InstructureEquella",
      author: "Brian Whitmer",
      authorurl: "http://www.instructure.com",
      infourl: "http://www.instructure.com",
      version: tinymce.majorVersion + "." + tinymce.minorVersion
    };
  }
});

// Register plugin
tinymce.PluginManager.add(
  "instructure_equella",
  tinymce.plugins.InstructureEquella
);
