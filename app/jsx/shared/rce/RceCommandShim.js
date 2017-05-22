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

import $ from 'jquery'
import wikiSidebar from 'wikiSidebar'

// for each command, there are three possibilities:
//
//   .data('remoteEditor') is set:
//     feature flag is on and succeeded, just use the remote editor call
//
//   .data('rich_text') is set:
//     feature flag is off, use the legacy editorBox/wikiSidebar interface
//
//   neither is set:
//     probably feature flag is on but failed, or maybe just a poorly set up
//     spec (or worst case, poorly set up actual usage... booo). the action
//     will do the best it can (see send for example), but often will be a
//     no-op
//
export function send ($target, methodName, ...args) {
  const remoteEditor = $target.data('remoteEditor')
  if (remoteEditor) {
    if (methodName === 'get_code' && remoteEditor.isHidden()) {
      return $target.val()
    }
    if (methodName === 'create_link') {
      // correct for link insertion api difference between editor_box and
      // canvas-rce
      methodName = 'insertLink'
      args[0].href = args[0].url
      args[0].class = args[0].classes
      const dataAttributes = args[0].dataAttributes
      args[0]['data-preview-alt'] = dataAttributes && dataAttributes['preview-alt']
    }
    return remoteEditor.call(methodName, ...args)
  } else if ($target.data('rich_text')) {
    return $target.editorBox(methodName, ...args)
  } else {
    // we're not set up, so tell the caller that `exists?` is false,
    // `get_code` is the textarea value, and ignore anything else.
    if (methodName === 'exists?') {
      return false
    } else if (methodName === 'get_code') {
      return $target.val()
    } else {
      console.warn(`called send('${methodName}') on an RCE instance that hasn't fully loaded, ignored`)
    }
  }
}

export function focus ($target) {
  const remoteEditor = $target.data('remoteEditor')
  if (remoteEditor) {
    remoteEditor.focus()
  } else if ($target.data('rich_text')) {
    wikiSidebar.attachToEditor($target)
  } else {
    console.warn("called focus() on an RCE instance that hasn't fully loaded, ignored")
  }
}

export function destroy ($target) {
  const remoteEditor = $target.data('remoteEditor')
  if (remoteEditor) {
    // detach the remote editor reference after destroying it
    remoteEditor.destroy()
    $target.data('remoteEditor', null)
  } else if ($target.data('rich_text')) {
    $target.editorBox('destroy')
  } else {
    console.warn("called destroy() on an RCE instance that hasn't fully loaded, ignored")
  }
}
