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
import {globalRegistry} from '../instructure-context-bindings/BindingRegistry'
import {getContentFromElement, FILE_LINK_TYPE} from '../shared/ContentSelection'
import LinkOptionsTrayController from './components/LinkOptionsTray/LinkOptionsTrayController'

const trayController = new LinkOptionsTrayController()

const PLUGIN_KEY = 'links'
const CREATE_LINK = 'create'
const EDIT_LINK = 'edit'

const getLink = function (editor, elm) {
  return editor.dom.getParent(elm, 'a[href]');
}
const getLinkIfCursorOnAnchorElement = function (editor) {
  return getAnchorElement(editor, editor.selection.getNode()) ||
         getAnchorElement(editor, editor.selection.getStart())
}

const getAnchorElement = function (editor, node) {
  const link = node.nodeName.toLowerCase() === 'a' ? node : getLink(editor, node)
  return (link && link.href) ? link : null
};

tinymce.create("tinymce.plugins.InstructureLinksPlugin", {
  init(ed) {
    // Register commands
    ed.addCommand(
      "instructureLinkCreate",
      clickCallback.bind(this, ed, CREATE_LINK)
    );
    ed.addCommand(
      "instructureLinkEdit",
      clickCallback.bind(this, ed, EDIT_LINK)
    )

    // Register toolbar button
    ed.ui.registry.addMenuButton("instructure_links", {
      tooltip: formatMessage('Links'),
      icon: "link",
      fetch(callback) {
        let items
        const link = getLinkIfCursorOnAnchorElement(ed)
        if (link) {
          items = [
            {
              type: 'menuitem',
              text: formatMessage('Edit Link'),
              onAction: () => {
                if (isFileLink(link)) {
                  trayController.showTrayForEditor(ed)
                } else {
                  ed.execCommand('instructureLinkEdit')
                }
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
                ed.execCommand('instructureLinkCreate');
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
          api.setActive(!!getAnchorElement(ed, e.element))
        }

        ed.on('NodeChange', handleNodeChange)

        return () => {
          ed.off('NodeChange', handleNodeChange)
        }
      }
    });

    // the context toolbar button
    const buttonAriaLabel = formatMessage('Show link options')
    ed.ui.registry.addButton('instructure-link-options', {
      onAction(/* buttonApi */) {
        // show the tray
        trayController.showTrayForEditor(ed)
      },

      onSetup(/* buttonApi */) {
        globalRegistry.bindToolbarToEditor(ed, buttonAriaLabel)
      },

      text: formatMessage('Options'),
      tooltip: buttonAriaLabel
    })

    const defaultFocusSelector = `.tox-pop__dialog button[aria-label="${buttonAriaLabel}"]`
    globalRegistry.addContextKeydownListener(ed, defaultFocusSelector)

    const isFileLink = ($element) => getContentFromElement($element, ed).type === FILE_LINK_TYPE

    ed.ui.registry.addContextToolbar('instructure-link-toolbar', {
      items: 'instructure-link-options',
      position: 'node',
      predicate: isFileLink,
      scope: 'node'
    })
  }
});

// Register plugin
tinymce.PluginManager.add(
  "instructure_links",
  tinymce.plugins.InstructureLinksPlugin
);
