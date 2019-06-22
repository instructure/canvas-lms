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

import formatMessage from "../../../format-message"
import clickCallback from "./clickCallback"
import bridge from '../../../bridge'

const PLUGIN_KEY = 'links'

tinymce.create("tinymce.plugins.InstructureLinksPlugin", {
  init(ed) {
    const getLink = function (editor, elm) {
      return editor.dom.getParent(elm, 'a[href]');
    }
    const isCursorOnAnchorElement = function () {
      return isAnchorElement(ed.selection.getNode()) || isAnchorElement(ed.selection.getStart())
    }

    const isAnchorElement = function (node) {
      const link = node.nodeName.toLowerCase() === 'a' ? node : getLink(ed, node)
      return link && link.href
    };

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
        let items
        if (isCursorOnAnchorElement()) {
          items = [
            {
              type: 'menuitem',
              text: formatMessage('Edit Link'),
              onAction: () => {
                ed.execCommand('mceLink')
              }
            },
            {
              type: 'menuitem',
              text: formatMessage('Remove Link'),
              onAction() {
                ed.execCommand('unlink')
              }
            }
          ]
        } else {
          items = [
            {
              type: 'menuitem',
              text: formatMessage('External Links'),
              onAction: () => {
                ed.execCommand('mceLink');
              }
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
        }
        callback(items)
      },
      onSetup: function(api) {
        function handleNodeChange(e) {
          api.setActive(isAnchorElement(e.element))
        }

        ed.on('NodeChange', handleNodeChange)

        return () => {
          ed.off('NodeChange', handleNodeChange)
        }
      }
    });
  }
});

// Register plugin
tinymce.PluginManager.add(
  "instructure_links",
  tinymce.plugins.InstructureLinksPlugin
);
