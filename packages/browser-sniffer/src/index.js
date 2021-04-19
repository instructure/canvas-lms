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

import $ from 'jquery'

// for backwards compat, this might be defined already but we expose
// it as a module here
if (!('INST' in window)) window.INST = {}

// ============================================================================================
// = Try to figure out what browser they are using and set INST.broswer.theirbrowser to true  =
// = and add a css class to the body for that browser                                       =
// ============================================================================================
INST.browser = {}

// Test for WebKit.
if (window.devicePixelRatio) {
  INST.browser.webkit = true

  // from: http://www.byond.com/members/?command=view_post&post=53727
  INST.browser[
    escape(navigator.javaEnabled.toString()) ==
    'function%20javaEnabled%28%29%20%7B%20%5Bnative%20code%5D%20%7D'
      ? 'chrome'
      : 'safari'
  ] = true
}

// this is just using jquery's browser sniffing result of if its firefox, it
// should probably use feature detection
INST.browser.ff = $.browser.mozilla

INST.browser.touch = 'ontouchstart' in document
INST.browser['no-touch'] = !INST.browser.touch

// now we have some degree of knowing which of the common browsers it is,
// on dom ready, give the body those classes
// so for example, if you were on IE6 the body would have the classes "ie" AND "ie6"
const classesToAdd = $.map(INST.browser, (v, k) => (v === true ? k : undefined)).join(' ')
$(() => {
  $('body').addClass(classesToAdd)
})

export default INST
