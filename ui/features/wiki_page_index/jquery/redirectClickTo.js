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

import $ from 'jquery'

// Redirects click events from one element to another
//
// This allows, for example, to make a row clickable but while
// preserving some built-in functionality provided by the browser
// (e.g. ctrl+click to open in a new tab)
//
// By default, the element with the click redirected is styled with
// cursor: pointer, this can be overwritten by providing a css
// option with the desired css. If css is set to false, no styling
// is performed.
//
// To prevent redirecting a particular click event, you must call
// preventDefault on the event before redirectClickTo receives the
// event. Click events on the target are allowed to pass through.
export default $.fn.redirectClickTo = function (target, options = {}) {
  // get the raw dom element
  target = $(target).get(0)
  if (!target) return

  // style the element to indicate to the user that it is clickable
  let css
  if (options.css !== false) css = options.css || {cursor: 'pointer'}
  if (css) this.css(css)

  this.off('.redirectClickTo')
  return this.on('click.redirectClickTo', event => {
    // ignore events for the target (prevents infinite recursion)
    let ignoreEvent = event.target === target
    // also ignore events that are marked to prevent default
    ignoreEvent = ignoreEvent || event.isDefaultPrevented()

    if (!ignoreEvent) {
      // stop processing this event (it'll be re-dispatched to the target anyway)
      event.stopPropagation()
      event.preventDefault()

      // clone the original event and re-dispatch on the target
      // note: cloning from the originalEvent to prevent jquery muckings
      const oevent = event.originalEvent

      const e = document.createEvent('MouseEvents')
      e.initMouseEvent(
        oevent.type,
        true,
        true,
        window,
        0,
        oevent.screenX,
        oevent.screenY,
        oevent.clientX,
        oevent.clientY,
        oevent.ctrlKey,
        oevent.altKey,
        oevent.shiftKey,
        oevent.metaKey,
        oevent.button,
        oevent.relatedTarget
      )
      return target.dispatchEvent(e)
    }
  })
}
