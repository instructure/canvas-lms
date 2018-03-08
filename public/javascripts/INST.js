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

/* global ScriptEngineMajorVersion: false, escape: false */
import $ from 'jquery'

let addClasses = true

function classifyIE(version) {
  version = parseInt(version, 10)
  INST.browser[`ie${version}`] = INST.browser.ie = true
  INST.browser.version = version
}

// for backwards compat, this might be defined already but we expose
// it as a module here
if (!('INST' in window)) window.INST = {}

// ============================================================================================
// = Try to figure out what browser they are using and set INST.broswer.theirbrowser to true  =
// = and add a css class to the body for that browser                                       =
// ============================================================================================
INST.browser = {}

// Conditional comments were dropped as of IE10, so we need to sniff.
//
// See: http://msdn.microsoft.com/en-us/library/ie/hh801214(v=vs.85).aspx
if (!INST.browser.ie) {
  const userAgent = navigator.userAgent
  const isIEGreaterThan10 = /\([^\)]*Trident[^\)]*rv:([\d\.]+)/.exec(userAgent)
  if (isIEGreaterThan10) {
    if ('ScriptEngineMajorVersion' in window && typeof ScriptEngineMajorVersion === 'function') {
      classifyIE(ScriptEngineMajorVersion())
    } else {
      classifyIE(isIEGreaterThan10[1])
    }

    // don't add the special "ie" class for IE10+ because their renderer is
    // not far behind Gecko and Webkit
    addClasses = false
  } else if (eval('/*@cc_on!@*/0')) {
    // need to eval here because the optimizer will strip any comments, so using
    // /*@cc_on@*/ will not make it through:
    classifyIE(10)
    addClasses = false
  }
}

// Test for WebKit.
//
// The IE test is needed because IE11+ defines this property too.
if (window.devicePixelRatio && !INST.browser.ie) {
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
if (addClasses) {
  const classesToAdd = $.map(INST.browser, (v, k) => (v === true ? k : undefined)).join(' ')
  $(function() {
    $('body').addClass(classesToAdd)
  })
}

export default INST
