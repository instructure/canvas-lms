// @ts-nocheck
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
import {getAnchorElement, isOKToLink} from '../../contentInsertionUtils'
import LinkOptionsTrayController from './components/LinkOptionsTray/LinkOptionsTrayController'
import {CREATE_LINK, EDIT_LINK} from './components/LinkOptionsDialog/LinkOptionsDialogController'
import tinymce, {Editor} from 'tinymce'

const trayController = new LinkOptionsTrayController()

const COURSE_PLUGIN_KEY = 'course_links'
const GROUP_PLUGIN_KEY = 'group_links'

function getCommandName(selectedNode: Element) {
  const isCourseLink = selectedNode.getAttribute('data-course-type')
  return isCourseLink ? 'instructureTrayForCourseLinks' : 'instructureTrayToEditLink'
}

function selectedAnchorCount(ed: Editor) {
  return ed.selection.getRng().cloneContents().querySelectorAll('a').length
}

function getMenuItems(ed: Editor): Array<{text: string; value: string}> {
  const contextType = ed.settings.canvas_rce_containing_context?.type
  const sel_anchors = ed.selection.isCollapsed() ? 0 : selectedAnchorCount(ed)
  let items: Array<{text: string; value: string}>
  if (getAnchorElement(ed, ed.selection.getNode())) {
    // cursor is on an anchor, edit or remove it
    items = [
      {
        text: formatMessage('Edit Link'),
        value: getCommandName(ed.selection.getNode()),
      },
      {
        text: formatMessage('Remove Link'),
        value: 'instructureUnlink',
      },
    ]
  } else {
    items = [
      {
        text: formatMessage('External Link'),
        value: 'instructureLinkCreate',
      },
    ]
    if (contextType === 'course') {
      items.push({
        text: formatMessage('Course Link'),
        value: 'instructure_course_links',
      })
    } else if (contextType === 'group') {
      items.push({
        text: formatMessage('Group Link'),
        value: 'instructure_group_links',
      })
    }
    if (sel_anchors > 0) {
      // selection contains anchor(s), so the user can remove them
      items.push({
        text: formatMessage.plural(sel_anchors, {
          one: 'Remove Link',
          other: 'Remove Links',
        }),
        value: 'instructureUnlinkAll',
      })
    }
  }
  return items
}

function removeAnchorFromSelectedElement(ed: Editor) {
  const selectedElem = ed.selection.getNode()
  const anchorElem = getAnchorElement(ed, selectedElem)
  ed.selection.select(anchorElem)
  ed.undoManager.add()
  ed.execCommand('Unlink')
}

function doMenuItem(ed: Editor, actionName: string) {
  switch (actionName) {
    case 'instructureTrayToEditLink':
    case 'instructureTrayForCourseLinks':
    case 'instructureLinkCreate':
      ed.execCommand(actionName)
      break
    case 'instructureUnlink':
      removeAnchorFromSelectedElement(ed)
      break
    case 'instructureUnlinkAll':
      ed.undoManager.add()
      ed.execCommand('unlink')
      break
    case 'instructure_course_links':
      ed.focus(true) // activate the editor without changing focus
      ed.execCommand('instructureTrayForLinks', false, COURSE_PLUGIN_KEY)
      break
    case 'instructure_group_links':
      ed.focus(true) // activate the editor without changing focus
      ed.execCommand('instructureTrayForLinks', false, GROUP_PLUGIN_KEY)
      break
  }
}

tinymce.PluginManager.add('instructure_links', function (ed) {
  // Register commands
  ed.addCommand('instructureLinkCreate', () => clickCallback(ed, CREATE_LINK))
  ed.addCommand('instructureLinkEdit', () => clickCallback(ed, EDIT_LINK))
  ed.addCommand('instructureTrayForLinks', (ui, plugin_key) => {
    bridge.showTrayForPlugin(plugin_key, ed.id)
  })
  ed.addCommand('instructureTrayToEditLink', _ui => {
    trayController.showTrayForEditor(ed)
  })
  ed.addCommand('instructureTrayForCourseLinks', () => {
    ed.selection.select(ed.selection.getNode())
    return bridge.showTrayForPlugin('course_link_edit', ed.id)
  })

  // Register shortcuts
  ed.addShortcut('Meta+K', '', 'instructureLinkCreate')

  // Register menu item
  ed.ui.registry.addNestedMenuItem('instructure_links', {
    text: formatMessage('Link'),
    icon: 'link',
    getSubmenuItems: () =>
      getMenuItems(ed).map(item => {
        return {
          type: 'menuitem',
          text: item.text,
          onAction: () => doMenuItem(ed, item.value),
          onSetup: api => {
            api.setDisabled(!isOKToLink(ed.selection.getContent()))
            return () => {}
          },
        }
      }),
  })

  // Register toolbar button
  ed.ui.registry.addMenuButton('instructure_links', {
    tooltip: formatMessage('Links'),
    icon: 'link',
    fetch: callback =>
      callback(
        getMenuItems(ed).map(item => ({
          type: 'menuitem',
          text: item.text,
          value: item.value,
          onAction: () => doMenuItem(ed, item.value),
        }))
      ),
    onSetup(api) {
      function handleNodeChange(e) {
        if (e?.element) {
          api.setActive(!!getAnchorElement(ed, e.element))
        }
        api.setDisabled(!isOKToLink(ed.selection.getContent()))
      }

      // if the user selects all the content w/in a link and deletes it via the keyboard
      // make sure the surrounding <a> gets deleted too.
      function deleteEmptyLink() {
        let node: Element | null = null

        if (ed.selection.getNode().tagName === 'A') {
          node = ed.selection.getNode()
        } else {
          // Type checking is disabled here because the code below isn't type safe. The code below
          // should be updated, specifically rng.endContainer.nextSibling?.tagName
          const rng = ed.selection.getRng() as any

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
          if (node.firstElementChild) {
            return
          }
          const txt = node.textContent?.trim()
          if (txt?.length === 0) {
            ed.execCommand('Unlink')
          }
        }
      }

      setTimeout(handleNodeChange, 0, null)

      ed.on('NodeChange', handleNodeChange)
      ed.on('Change', deleteEmptyLink)

      return () => {
        ed.off('NodeChange', handleNodeChange)
        ed.off('Change', deleteEmptyLink)
      }
    },
  })

  // the context toolbar buttons
  ed.ui.registry.addButton('instructure-link-options', {
    onAction(/* buttonApi */) {
      ed.execCommand(getCommandName(ed.selection.getNode()), false, ed)
    },

    text: formatMessage('Link Options'),
    tooltip: formatMessage('Show link options'),
  })

  const remButtonLabel = formatMessage('Remove Link')
  ed.ui.registry.addButton('instructureUnlink', {
    onAction() {
      removeAnchorFromSelectedElement(ed)
    },

    text: remButtonLabel,
  })

  ed.ui.registry.addContextToolbar('instructure-link-toolbar', {
    items: 'instructure-link-options instructureUnlink',
    position: 'node',
    predicate: elem => !!getAnchorElement(ed, elem),
    scope: 'node',
  })
})
