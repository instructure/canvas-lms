/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

// Catches specified key events and calls the provided function
// when they occur.  Can use text or key codes, passed in as a
// space-separated string.
import $ from 'jquery'

function isFirefox() {
  return /Firefox/i.test(window.navigator.userAgent)
}

$.fn.keycodes = function (options, fn) {
  /* Based loosely on Tzury Bar Yochay's js-hotkeys:
  (c) Copyrights 2007 - 2008

  Original idea by by Binny V A, http://www.openjs.com/scripts/events/keyboard_shortcuts/

  jQuery Plugin by Tzury Bar Yochay
  tzury.by@gmail.com
  http://evalinux.wordpress.com
  http://facebook.com/profile.php?id=513676303

  Project's sites:
  http://code.google.com/p/js-hotkeys/
  http://github.com/tzuryby/hotkeys/tree/master

  License: same as jQuery license. */
  let specialKeys = {
    27: 'esc',
    9: 'tab',
    32: 'space',
    13: 'return',
    8: 'backspace',
    145: 'scroll',
    20: 'capslock',
    144: 'numlock',
    19: 'pause',
    45: 'insert',
    36: 'home',
    46: 'del',
    35: 'end',
    33: 'pageup',
    34: 'pagedown',
    37: 'left',
    38: 'up',
    39: 'right',
    40: 'down',
    112: 'f1',
    113: 'f2',
    114: 'f3',
    115: 'f4',
    116: 'f5',
    117: 'f6',
    118: 'f7',
    119: 'f8',
    120: 'f9',
    121: 'f10',
    122: 'f11',
    123: 'f12',
    191: '/',
  }
  if (isFirefox()) {
    specialKeys = $.extend(specialKeys, {
      96: '0',
      97: '1',
      98: '2',
      99: '3',
      100: '4',
      101: '5',
      102: '6',
      103: '7',
      104: '8',
      105: '9',
      0: '191' /* with shift, 191 becomes 0 #5200 */,
    })
  }
  if (typeof options === 'string') {
    options = {keyCodes: options}
  }
  if (this.filter(':input,object,embed').length > 0) {
    options.ignore = ''
  }
  options = $.extend({}, $.fn.keycodes.defaults, options)

  const keyCodes = []
  const originalCodes = []
  const codes = options.keyCodes.split(' ')
  $.each(codes, (i, code) => {
    originalCodes.push(code)
    code = code.split('+').sort().join('+').toLowerCase()
    keyCodes.push(code)
  })
  this.bind('keydown', function (event, originalEvent) {
    event = originalEvent && originalEvent.keyCode ? originalEvent : event
    if (options.ignore && $(event.target).is(options.ignore)) {
      return
    }
    let code = []
    if (event.shiftKey) {
      code.push('Shift')
    }
    if (event.ctrlKey) {
      code.push('Ctrl')
    }
    if (event.metaKey) {
      code.push('Meta')
    }
    if (event.altKey) {
      code.push('Alt')
    }
    let key = specialKeys[event.keyCode]
    key = key || String.fromCharCode(event.keyCode)
    code.push(key)
    code = code.sort().join('+').toLowerCase()
    event.keyMatches = function (checkCode) {
      checkCode = checkCode.split('+').sort().join('+').toLowerCase()
      return checkCode === code
    }
    const idx = $.inArray(code, keyCodes)
    const picker = $(document).data('last_datepicker')
    if (picker && picker[0] === this && event.keyCode === 27) {
      event.preventDefault()
      return false
    }

    if (idx !== -1) {
      event.keyString = originalCodes[idx]
      fn.call(this, event)
    }
  })
  return this
}
$.fn.keycodes.defaults = {ignore: ':input,object,embed', keyCodes: ''}
