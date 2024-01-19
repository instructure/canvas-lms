/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

//
// NOTE!: Be sure to call RichContentEditor.closeRCE(target) in your source page
//        whenever the user purposfully leaves the page (by clicking Cancel or Submit)
//        This gets any autosaved content cleared so they won't be prompted next
//        time around.

import serviceRCELoader from './serviceRCELoader'
import {RCELOADED_EVENT_NAME, send, destroy, focus} from '@canvas/rce-command-shim/RceCommandShim'
import $ from 'jquery'
import {escape} from 'lodash'

function loadServiceRCE(target, tinyMCEInitOptions, callback) {
  target.css('display', 'none')

  const originalOnFocus = tinyMCEInitOptions.onFocus

  tinyMCEInitOptions.onFocus = (...args) => {
    if (originalOnFocus instanceof Function) {
      originalOnFocus(...args)
    }
  }

  serviceRCELoader.loadOnTarget(target, tinyMCEInitOptions, (textarea, remoteEditor) => {
    const $target = node2jquery(target)
    const $textarea = freshNode($(textarea))
    $textarea.data('remoteEditor', remoteEditor)
    $target.trigger(RCELOADED_EVENT_NAME, remoteEditor)
    if (callback) {
      callback(remoteEditor)
    }
  })
}

function establishParentNode(target) {
  const $target = node2jquery(target)
  // some areas would wipe out the whole form
  // if we rendered a new editor into the textarea parent
  // element, so this is some helper functionality to create/reuse
  // a parent element if that's the case
  const targetId = escape($target.attr('id'))
  // xsslint safeString.identifier targetId parentId
  const parentId = `tinymce-parent-of-${targetId}`
  if ($target.parent().attr('id') === parentId) {
    // parent wrapper already exits
  } else {
    return $target.wrap(`<div id='${parentId}' style='visibility: hidden'></div>`)
  }
}

function hideResizeHandleForScreenReaders() {
  $('.mce-resizehandle').attr('aria-hidden', true)
}

// Returns a unique id
let _editorUid = 0
function nextID() {
  return `random_editor_id_${_editorUid++}`
}

/**
 * Make sure each the element has an id. If it
 * doesn't, give it a random one.
 * @private
 */
function ensureID(el) {
  const $el = $(el)
  const id = 'attr' in $el ? $el.attr('id') : $el.id
  if (!id || id == '') {
    $el.attr('id', nextID())
  }
}

/**
 * we need to make sure we have the latest node in order to capture any
 * changes, lots of views like to use stale nodes
 *
 * @private
 */
function freshNode(target) {
  const $target = node2jquery(target)
  // Try to get the id
  const targetId = $target.attr('id')
  if (!targetId || targetId == '') {
    return $target
  }
  // Try to get the element on the DOM
  const newTarget = $(`#${targetId}`)
  if (newTarget.length <= 0) {
    return $target
  }
  return newTarget
}

const RichContentEditor = {
  /**
   * start the remote module (if the feature flag is on) loading so that it's
   * hopefully done by the time loadNewEditor is called.
   * should typically be called at the top of any source file that calls one
   * of those.
   *
   * @public
   */
  preloadRemoteModule(cb = () => {}) {
    return serviceRCELoader.preload(cb)
  },

  /**
   * load an editor into the target element with the given options. most
   * options are passed on to tinymce, but locally:
   *
   *   focus (boolean)
   *     claim the new editor as active immediately after it's loaded
   *
   *   manageParent (boolean)
   *     ensure the target element has a containing div that doesn't contain
   *     the element's siblings, so when the RCE is rendered into the
   *     container it doesn't wipe out other parts of the DOM
   *
   *   optionsToMerge (Array<string>)
   *     Sometimes it is desirable to _merge_ custom tinymce configuration with
   *     the default values rather than completely _overwriting_ those defaults.
   *
   *     When this is desired, set "optionsToMerge" to an array of the config
   *     keys you wish to have merged rather than overwritten. For example:
   *
   *     ```
   *      loadNewEditor(textarea, {
   *        optionsToMerge: ['plugins'],
   *        tinyOptions: {
   *          plugins: ['canvas_mentions']
   *        }
   *      }, cb)
   *     ```
   *
   *     This example will merge `tinyOptions.plugins` with the list of default
   *     plugins rather than overriding them.
   *
   *
   * Be sure to call RichContentEditor.closeRCE(target) if the user cleanly exits the page
   *
   * @public
   */
  loadNewEditor(target, tinyMCEInitOptions = {}, cb) {
    let $target = node2jquery(target)
    if ($target.length <= 0) {
      // no actual target, just short circuit out
      return
    }

    ensureID($target)

    // avoid modifying the original options object provided
    tinyMCEInitOptions = $.extend({}, tinyMCEInitOptions)

    const callback = rce => {
      if (tinyMCEInitOptions.focus) {
        // call activateRCE once loaded
        this.activateRCE($target)
      }
      if (cb) {
        cb(rce)
      }
    }

    $target = this.freshNode($target)

    if (tinyMCEInitOptions.manageParent) {
      delete tinyMCEInitOptions.manageParent
      establishParentNode($target)
    }

    loadServiceRCE($target, tinyMCEInitOptions, callback)

    hideResizeHandleForScreenReaders()
  },

  /**
   * call a function on the target editor.
   *
   * @public
   */
  callOnRCE(target, methodName, ...args) {
    let $target = node2jquery(target)
    $target = this.freshNode($target)
    return send($target, methodName, ...args)
  },

  /**
   * remove the target editor.
   *
   * @public
   */
  destroyRCE(target) {
    let $target = node2jquery(target)
    $target = this.freshNode($target)
    destroy($target)
  },

  /**
   * Tell the RCE we're closing
   *
   * @public
   */
  closeRCE(target) {
    this.callOnRCE(target, 'RCEClosed')
  },

  /**
   * make the target the active editor
   *
   * @private
   */
  activateRCE(target) {
    let $target = node2jquery(target)
    $target = this.freshNode($target)
    focus($target)
  },

  freshNode,
  ensureID,
  node2jquery,
}

// while the internals work with jquery, let's not
// require that of our consumer
function node2jquery(node) {
  return node && node.length ? node : $(node)
}

export default RichContentEditor
