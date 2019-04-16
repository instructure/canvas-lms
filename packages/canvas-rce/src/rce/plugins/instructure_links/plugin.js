/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

const PLUGIN_KEY = 'links'

tinymce.create("tinymce.plugins.InstructureLinksPlugin", {
  init(ed) {
    // Register commands
    ed.addCommand(
      "instructureLinks",
      clickCallback.bind(this, ed, document)
    );

    // Register button
    ed.ui.registry.addMenuButton("instructure_links", {
      tooltip: formatMessage('Links'),
      icon: "link",
      fetch(callback) {
        const items = [
          {
            type: 'menuitem',
            text: formatMessage('External Links'),
            onAction: () => ed.execCommand("instructureLinks")
          },
          {
            type: 'menuitem',
            text: formatMessage('Course Links'),
            onAction() {
              ed.focus(true) // activate the editor without changing focus
              bridge.showTrayForPlugin(PLUGIN_KEY)
            }
          }
        ]
        callback(items)
      }
    });
  }
});

// Register plugin
tinymce.PluginManager.add(
  "instructure_links",
  tinymce.plugins.InstructureLinksPlugin
);
