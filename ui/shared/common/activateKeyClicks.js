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

function fireKeyclick(e) {
  const kce = $.Event('keyclick')
  $(e.target).trigger(kce)
  if (kce.isDefaultPrevented()) e.preventDefault()
  if (kce.isPropagationStopped()) e.stopPropagation()
}

function keydownHandler(e) {
  switch (e.which) {
    case 13:
      return fireKeyclick(e)
    case 32:
      // prevent scrolling when the spacebar is pressed on a "button"
      return e.preventDefault()
  }
}

function keyupHandler(e) {
  switch (e.which) {
    case 32:
      return fireKeyclick(e)
  }
}

$.fn.activate_keyclick = function (selector = null) {
  this.on('keydown', selector, keydownHandler)
  return this.on('keyup', selector, keyupHandler)
}

$(document).activate_keyclick('[role=button], [role=checkbox]')
