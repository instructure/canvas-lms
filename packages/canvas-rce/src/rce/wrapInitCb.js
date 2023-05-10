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

import $ from 'jquery'

// mirror attributes onto tinymce editor (if this can be done
// via tiny api, it is preferable, but I dont see a way)
export default function wrapInitCb(mirroredAttrs, editorOptions) {
  const oldInitInstCb = editorOptions.init_instance_callback
  editorOptions.init_instance_callback = function (ed) {
    const attrs = mirroredAttrs || {}
    const el = ed.getElement()
    if (el) {
      Object.keys(attrs).forEach(attr => {
        el.setAttribute(attr, attrs[attr])
      })
    }

    // *** moved from setupAndFocusTinyMCEConfig ***
    const $editor = $('#' + ed.id)
    // KeyboardShortcuts.js needs to listen to events
    // fired from inside the editor, so we pass out
    // keyup events to the document
    ed.on('keyup', e => {
      $(document).trigger('editorKeyUp', [e])
    })

    ed.on('change', () => {
      $editor.trigger('change')
    })

    // *** I cannot find a place where last_bookmark is used ***
    // *** or where enableBookmarkingOverride is not falsey  ***
    // // no equivalent of "onEvent" in tinymce4
    // ed.on('keyup keydown click mousedown', () => {
    //   if (enableBookmarking && ed.selection) {
    //     $editor.data('last_bookmark', ed.selection.getBookmark(1))
    //   }
    // })

    $(window).triggerHandler('resize')

    // tiny sets a focusout event handler, which only IE supports
    // (Chrome/Safari/Opera support DOMFocusOut, FF supports neither)
    // we attach a blur event that does the same thing (which in turn
    // ensures the change callback fires)
    // this fixes FF's broken behavior (http://www.tinymce.com/develop/bugtracker_view.php?id=4004 )
    // as well as an issue in Safari where tiny didn't register some
    // change events if the previously focused element was a numerical
    // quiz input (something to do with changing its value in a change
    // handler)
    if (!('onfocusout' in ed.contentWindow)) {
      $(ed.contentWindow).blur(_e => {
        if (!ed.removed && ed.undoManager.typing) {
          ed.undoManager.typing = false
          ed.undoManager.add()
        }
      })
    }
    // *************

    // wrap old cb (dont overwrite)
    oldInitInstCb && oldInitInstCb(ed)
  }
  return editorOptions
}
