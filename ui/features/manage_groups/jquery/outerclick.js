//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

// Custom jQuery element event 'outerclick'
//
// Usage:
//   $el = $ '#el'
//   $el.on 'outerclick', (event) ->
//     doStuff()
//
//   class SomeView extends Backbone.View
//     events:
//       'outerclick': 'handler'
//     handler: (event) ->
//       @hide()
import $ from 'jquery'

let $els = $()
const $doc = $(document)
const outerClick = 'outerclick'
const eventName = `click.${outerClick}-special`

$.event.special[outerClick] = {
  setup() {
    $els = $els.add(this)
    if ($els.length === 1) {
      $doc.on(eventName, handleEvent)
    }
  },

  teardown() {
    $els = $els.not(this)
    if ($els.length === 0) {
      $doc.off(eventName)
    }
  },

  add(handleObj) {
    const oldHandler = handleObj.handler
    handleObj.handler = function (event, el) {
      event.target = el
      return oldHandler.apply(this, arguments)
    }
  },
}

export default function handleEvent(event) {
  return $els.each(function () {
    const $el = $(this)
    if (this !== event.target && $el.has(event.target).length === 0) {
      $el.triggerHandler(outerClick, [event.target])
    }
  })
}
