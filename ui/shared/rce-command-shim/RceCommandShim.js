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

// for each command, there are three possibilities:
//
//   .data('remoteEditor') is set:
//     feature flag is on and succeeded, just use the remote editor call
//
//   neither is set:
//     probably feature flag is on but failed, or maybe just a poorly set up
//     spec (or worst case, poorly set up actual usage... booo). in the case
//     of send action, we use event triggering (see RichContentEditor for the
//     trigger) to wait until it's loaded and send the event
//
import {registerJQueryValueHandler} from '@canvas/serialize-form'

export const RCELOADED_EVENT_NAME = 'RceLoaded'
// eslint-disable-next-line import/no-mutable-exports
export let tmce

function delaySend($target, methodName, ...args) {
  $target.one(
    RCELOADED_EVENT_NAME,
    {
      method_name: methodName,
      args,
    },
    (e, remoteEditor) => {
      remoteEditor.call(e.data.method_name, ...e.data.args)
    }
  )
}

export function setTinymce(t) {
  tmce = t
}

export function getTinymce() {
  return tmce || tinymce
}

export function send($target, methodName, ...args) {
  const remoteEditor = $target.data('remoteEditor') || $target[0]?.remoteEditor

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
    const ret = remoteEditor.call(methodName, ...args)
    if (methodName === 'toggle') {
      if ($target.is(':visible')) {
        $target.focus()
      } else {
        remoteEditor.focus()
      }
    }
    return ret
    // we're not set up, so tell the caller that `exists?` is false,
    // `get_code` is the textarea value, and ignore anything else.
  } else if (methodName === 'exists?') {
    return false
  } else if (methodName === 'get_code') {
    return $target.val()
  } else {
    // eslint-disable-next-line no-console
    console.warn(
      `called send('${methodName}') on an RCE instance that hasn't fully loaded, delaying send`
    )
    delaySend($target, methodName, ...args)
  }
}

export function focus($target) {
  const remoteEditor = $target.data('remoteEditor')
  if (remoteEditor) {
    remoteEditor.focus()
  } else {
    console.warn("called focus() on an RCE instance that hasn't fully loaded, ignored")
  }
}

export function destroy($target) {
  const remoteEditor = $target.data('remoteEditor')
  if (remoteEditor) {
    // detach the remote editor reference after destroying it
    remoteEditor.destroy()
    $target.data('remoteEditor', null)
  } else {
    console.warn("called destroy() on an RCE instance that hasn't fully loaded, ignored")
  }
}

registerJQueryValueHandler(input => {
  if (input.data('rich_text')) {
    return {
      tag: 'value',
      value: send(input, 'get_code', false),
    }
  } else {
    return {tag: 'none'}
  }
})
