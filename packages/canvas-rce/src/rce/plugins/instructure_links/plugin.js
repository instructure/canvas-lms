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

import formatMessage from '../../../format-message'
import clickCallback from './clickCallback'
import bridge from '../../../bridge'
import {isFileLink, asLink} from '../shared/ContentSelection'
import LinkOptionsTrayController from './components/LinkOptionsTray/LinkOptionsTrayController'
import {CREATE_LINK, EDIT_LINK} from './components/LinkOptionsDialog/LinkOptionsDialogController'

const trayController = new LinkOptionsTrayController()

const PLUGIN_KEY = 'links'

const getLink = function(editor, elm) {
  return editor.dom.getParent(elm, 'a[href]')
}

const getAnchorElement = function(editor, node) {
  const link = node.nodeName.toLowerCase() === 'a' ? node : getLink(editor, node)
  return link && link.href ? link : null
}

tinymce.create('tinymce.plugins.InstructureLinksPlugin', {
  init(ed) {
    // Register commands
    ed.addCommand('instructureLinkCreate', clickCallback.bind(this, ed, CREATE_LINK))
    ed.addCommand('instructureLinkEdit', clickCallback.bind(this, ed, EDIT_LINK))
    ed.addCommand('instructureTrayForLinks', (ui, plugin_key) => {
      bridge.showTrayForPlugin(plugin_key)
    })
    ed.addCommand('instructureTrayToEditLink', (ui, editor) => {
      trayController.showTrayForEditor(editor)
    })

    // Register toolbar button
    ed.ui.registry.addMenuButton('instructure_links', {
      tooltip: formatMessage('Links'),
      icon: 'link',
      fetch(callback) {
        let items
        const linkContents = asLink(ed.selection.getNode(), ed)
        if (linkContents) {
          items = [
            {
              type: 'menuitem',
              text: formatMessage('Edit Link'),
              onAction: () => {
                ed.execCommand('instructureTrayToEditLink', false, ed)
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
                ed.execCommand('instructureLinkCreate')
              }
            },
            {
              type: 'menuitem',
              text: formatMessage('Course Links'),
              onAction() {
                ed.focus(true) // activate the editor without changing focus
                ed.execCommand('instructureTrayForLinks', false, PLUGIN_KEY)
              }
            }
          ]
        }
        callback(items)
      },
      onSetup(api) {
        function handleNodeChange(e) {
          api.setActive(!!getAnchorElement(ed, e.element))
        }

        ed.on('NodeChange', handleNodeChange)

        return () => {
          ed.off('NodeChange', handleNodeChange)
        }
      }
    })

    // the context toolbar button
    const buttonAriaLabel = formatMessage('Show link options')
    ed.ui.registry.addButton('instructure-link-options', {
      onAction(/* buttonApi */) {
        // show the tray
        ed.execCommand('instructureTrayToEditLink', false, ed)
      },

      text: formatMessage('Options'),
      tooltip: buttonAriaLabel
    })

    ed.ui.registry.addContextToolbar('instructure-link-toolbar', {
      items: 'instructure-link-options',
      position: 'node',
      predicate: elem => isFileLink(elem, ed),
      scope: 'node'
    })
  }
})

// Register plugin
tinymce.PluginManager.add('instructure_links', tinymce.plugins.InstructureLinksPlugin)
