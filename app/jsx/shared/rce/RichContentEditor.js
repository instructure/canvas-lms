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

import serviceRCELoader from '../rce/serviceRCELoader'
import {RCELOADED_EVENT_NAME, send, destroy, focus} from '../rce/RceCommandShim'
import Sidebar from '../rce/Sidebar'
import featureFlag from '../rce/featureFlag'
import $ from 'jquery'

function loadServiceRCE(target, tinyMCEInitOptions, callback) {
  target.css('display', 'none')

  const originalOnFocus = tinyMCEInitOptions.onFocus
  // eslint-disable-next-line no-param-reassign
  tinyMCEInitOptions.onFocus = (...args) => {
    RichContentEditor.showSidebar()
    if (originalOnFocus instanceof Function) {
      originalOnFocus(...args)
    }
  }

  serviceRCELoader.loadOnTarget(target, tinyMCEInitOptions, (textarea, remoteEditor) => {
    const $textarea = freshNode($(textarea))
    $textarea.data('remoteEditor', remoteEditor)
    target.trigger(RCELOADED_EVENT_NAME, remoteEditor)
    if (callback) {
      callback()
    }
  })
}

let legacyTinyMCELoaded = false
function loadLegacyTinyMCE(callback) {
  if (legacyTinyMCELoaded) {
    callback()
    return
  }

  require.ensure(
    [],
    require => {
      legacyTinyMCELoaded = true
      require('tinymce.editor_box')
      require('compiled/tinymce')
      require('./initA11yChecker')
      callback()
    },
    'legacyTinymceAsyncChunk'
  )
}

function hideTextareaWhileLoadingLegacyRCE(target, callback) {
  if (legacyTinyMCELoaded) {
    callback()
    return
  }

  const previousOpacity = target[0].style.opacity
  target.css('opacity', 0)
  loadLegacyTinyMCE(() => {
    target.css('opacity', previousOpacity)
    callback()
  })
}

function loadLegacyRCE(target, tinyMCEInitOptions, callback) {
  target.css('display', '')
  hideTextareaWhileLoadingLegacyRCE(target, () => {
    tinyMCEInitOptions.defaultContent
      ? target
          .editorBox(tinyMCEInitOptions)
          .editorBox('set_code', tinyMCEInitOptions.defaultContent)
      : target.editorBox(tinyMCEInitOptions)
    if (callback) callback()
  })
}

function establishParentNode(target) {
  // some areas would wipe out the whole form
  // if we rendered a new editor into the textarea parent
  // element, so this is some helper functionality to create/reuse
  // a parent element if that's the case
  const targetId = target.attr('id')
  // xsslint safeString.identifier targetId parentId
  const parentId = `tinymce-parent-of-${targetId}`
  if (target.parent().attr('id') == parentId) {
    // parent wrapper already exits
  } else {
    return target.wrap(`<div id='${parentId}' style='visibility: hidden'></div>`)
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
function ensureID($el) {
  const id = $el.attr('id')
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
function freshNode($target) {
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
   * hopefully done by the time initSidebar and loadNewEditor are called.
   * should typically be called at the top of any source file that calls one
   * of those.
   *
   * @public
   */
  preloadRemoteModule() {
    if (featureFlag()) {
      serviceRCELoader.preload()
    }
  },

  /**
   * load the sidebar. can pass callbacks to execute any time the sidebar is
   * shown (`show`) or hidden (`hide`).
   *
   * @public
   */
  initSidebar(subscriptions = {}) {
    Sidebar.init(subscriptions)
  },

  /**
   * show the sidebar if it's around
   *
   * @public
   */

  showSidebar() {
    Sidebar.show()
  },

  /**
   * hide the sidebar if it's around
   *
   * @public
   */

  hideSidebar() {
    Sidebar.hide()
  },

  /**
   * load an editor into the target element with the given options. most
   * options are passed on to tinymce, but locally:
   *
   *   focus (boolean)
   *     claim the new editor as active immediately after it's loaded
   *     (including showing the sidebar if any)
   *
   *   manageParent (boolean)
   *     ensure the target element has a containing div that doesn't contain
   *     the element's siblings, so when the RCE is rendered into the
   *     container it doesn't wipe out other parts of the DOM
   *
   * @public
   */
  loadNewEditor($target, tinyMCEInitOptions = {}, cb) {
    if ($target.length <= 0) {
      // no actual target, just short circuit out
      return
    }

    ensureID($target)

    // avoid modifying the original options object provided
    tinyMCEInitOptions = $.extend({}, tinyMCEInitOptions)

    const callback = () => {
      if (tinyMCEInitOptions.focus) {
        // call activateRCE once loaded
        this.activateRCE($target)
      }
      if (cb) {
        cb()
      }
    }

    if (featureFlag()) {
      $target = this.freshNode($target)

      if (tinyMCEInitOptions.manageParent) {
        delete tinyMCEInitOptions.manageParent
        establishParentNode($target)
      }

      loadServiceRCE($target, tinyMCEInitOptions, callback)
    } else {
      loadLegacyRCE($target, tinyMCEInitOptions, callback)

      // listen for editor_box_focus events on our target, and trigger
      // activateRCE from them
      $target.on('editor_box_focus', () => this.activateRCE($target))
    }

    hideResizeHandleForScreenReaders()
  },

  /**
   * call a function on the target editor.
   *
   * @public
   */
  callOnRCE($target, methodName, ...args) {
    if (featureFlag()) {
      $target = this.freshNode($target)
    }
    return send($target, methodName, ...args)
  },

  /**
   * remove the target editor. if there's a sidebar, hide it
   *
   * @public
   */
  destroyRCE($target) {
    if (featureFlag()) {
      $target = this.freshNode($target)
    }
    destroy($target)
    Sidebar.hide()
  },

  /**
   * make the target the active editor, including to be recipient of sidebar
   * events. if there's a sidebar, make sure it's showing
   *
   * @private
   */
  activateRCE($target) {
    if (featureFlag()) {
      $target = this.freshNode($target)
    }
    focus($target)
    Sidebar.show()
  },

  freshNode,
  ensureID
}

export default RichContentEditor
