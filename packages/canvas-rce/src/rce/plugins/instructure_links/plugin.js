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

/*
 * here's how linking works
 * Creation:
 * 1. No text is selected, user clicks create link button:
 *    - display the create link dialog with text and URL input
 *    - insert an <a> at the caret, linked to the URL with the text content
 * 2. Text is selected, user clicks create link button:
 *    - display the create link dialog with text and URL input
 *    - the text input displays the plain-text content of the selection
 *    - on saving, if the plain-text has not changed, leave it unchanged in the RCE,
 *      if it has changed, replace the selection with the new plain-text.
 *      Wrap the text in an <a>, linked to the URL
 * 3. An image + optional text is selected, user clicks create link button
 *    - display the create link dialog with URL input only
 *    - on saving, the selection is wrapped in an <a>, linked to the URL
 * 4. An iframe is w/in the selection
 *    - disable the create link function
 *
 * Editing:
 * 1. the caret is w/in a text link, but nothing is selected or
 *    some subset of the link's text is selected
 *    - display the link Options popup button. when clicked...
 *    - expand the selection to be the whole link text
 *    - display the tray with the link's plain-text in the text input and the href
 *      in the URL input
 *    - on saving, if the plain-text is unchanged, leave the text unchanged in the RCE,
 *      if it has changed, replace the link text with the new plain-text.
 *      Update the <a>'s href to the new URL
 * 2. An image w/in a link is selected, or the caret is on the image, or the image
 *    plus some surrounding text that's all part of the existing link is selected, or
 *    the caret is w/in a link that contains an image
 *    a. for now: show the link and image Options buttons in a popup toolbar
 *       - on clicking the link Options...
 *       - expand the selection to be the whole link contents
 *       - show the link options tray, with no text input
 *       - on saving, update the link's href
 *    b. new-improved: show a single Options button, when clicked...
 *       - expand the selection to be the whole link contents
 *       - show the options tray with Image Options and Link Options sections
 *         the link text input is empty.
 *       - on saving, if the link text input is still empty, replace the link's
 *         href with the new URL.  if the link text is updated, replace the link's
 *         content with the new plain text (deleting the image)
 */

import formatMessage from '../../../format-message'
import clickCallback from './clickCallback'
import bridge from '../../../bridge'
import {isFileLink, asLink} from '../shared/ContentSelection'
import {getAnchorElement, isOKToLink} from '../../contentInsertionUtils'
import LinkOptionsTrayController from './components/LinkOptionsTray/LinkOptionsTrayController'
import {CREATE_LINK, EDIT_LINK} from './components/LinkOptionsDialog/LinkOptionsDialogController'

const trayController = new LinkOptionsTrayController()

const COURSE_PLUGIN_KEY = 'course_links'
const GROUP_PLUGIN_KEY = 'group_links'

tinymce.create('tinymce.plugins.InstructureLinksPlugin', {
  init(ed) {
    const contextType = ed.settings.canvas_rce_user_context.type

    // Register commands
    ed.addCommand('instructureLinkCreate', clickCallback.bind(this, ed, CREATE_LINK))
    ed.addCommand('instructureLinkEdit', clickCallback.bind(this, ed, EDIT_LINK))
    ed.addCommand('instructureTrayForLinks', (ui, plugin_key) => {
      bridge.showTrayForPlugin(plugin_key, ed.id)
    })
    ed.addCommand('instructureTrayToEditLink', (ui, editor) => {
      trayController.showTrayForEditor(editor)
    })

    // Register shortcuts
    ed.addShortcut('Meta+K', '', 'instructureLinkCreate')

    // Register menu item
    ed.ui.registry.addNestedMenuItem('instructure_links', {
      text: formatMessage('Link'),
      icon: 'link',
      getSubmenuItems: () => [
        'instructure_external_link',
        'instructure_course_link',
        'instructure_group_link'
      ]
    })
    ed.ui.registry.addMenuItem('instructure_external_link', {
      text: formatMessage('External Links'),
      shortcut: 'Meta+K',
      onAction: () => ed.execCommand('instructureLinkCreate')
    })
    if (contextType === 'course') {
      ed.ui.registry.addMenuItem('instructure_course_link', {
        text: formatMessage('Course Links'),
        onAction: () => {
          ed.focus(true) // activate the editor without changing focus
          ed.execCommand('instructureTrayForLinks', false, COURSE_PLUGIN_KEY)
        }
      })
    } else if (contextType === 'group') {
      ed.ui.registry.addMenuItem('instructure_group_link', {
        text: formatMessage('Group Links'),
        onAction: () => {
          ed.focus(true) // activate the editor without changing focus
          ed.execCommand('instructureTrayForLinks', false, GROUP_PLUGIN_KEY)
        }
      })
    }

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
                const selectedElm = ed.selection.getNode()
                const anchorElm = getAnchorElement(ed, selectedElm)
                ed.selection.select(anchorElm)
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
            }
          ]

          if (contextType === 'course') {
            items.push({
              type: 'menuitem',
              text: formatMessage('Course Links'),
              onAction() {
                ed.focus(true) // activate the editor without changing focus
                ed.execCommand('instructureTrayForLinks', false, COURSE_PLUGIN_KEY)
              }
            })
          } else if (contextType === 'group') {
            items.push({
              type: 'menuitem',
              text: formatMessage('Group Links'),
              onAction() {
                ed.focus(true) // activate the editor without changing focus
                ed.execCommand('instructureTrayForLinks', false, GROUP_PLUGIN_KEY)
              }
            })
          }
        }
        callback(items)
      },
      onSetup(api) {
        function handleNodeChange(e) {
          api.setActive(!!getAnchorElement(ed, e.element))
          api.setDisabled(!isOKToLink(ed.selection.getContent()))
        }

        // if the user selects all the content w/in a link and deletes it via the keyboard
        // make sure the surrounding <a> gets deleted too.
        function deleteEmptyLink() {
          let node
          if (ed.selection.getNode().tagName === 'A') {
            node = ed.selection.getNode()
          } else {
            const rng = ed.selection.getRng()
            if (
              rng.commonAncestorContainer === rng.endContainer &&
              rng.endContainer.nextSibling?.tagName === 'A'
            ) {
              node = rng.endContainer.nextSibling
            } else if (rng.nextSibling?.tagName === 'A') {
              node = rng.nextSibling
            }
          }
          if (node) {
            const txt = node.textContent?.trim()
            if (txt.length === 0) {
              ed.execCommand('Unlink')
            }
          }
        }

        ed.on('NodeChange', handleNodeChange)
        ed.on('Change', deleteEmptyLink)

        return () => {
          ed.off('NodeChange', handleNodeChange)
          ed.off('Change', deleteEmptyLink)
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

      text: formatMessage('Link Options'),
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
