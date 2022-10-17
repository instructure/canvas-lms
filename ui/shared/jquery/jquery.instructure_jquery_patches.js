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
import getCookie from '@instructure/get-cookie'

// this is a patch so you can set the "method" atribute on rails' REST-ful forms.
$.attrHooks.method = $.extend($.attrHooks.method, {
  set(elem, value) {
    const orginalVal = value
    value = value.toUpperCase() === 'GET' ? 'GET' : 'POST'
    if (value === 'POST') {
      let $input = $(elem).find("input[name='_method']")
      if (!$input.length) {
        $input = $("<input type='hidden' name='_method'/>").prependTo(elem)
      }
      $input.val(orginalVal)
    }
    elem.setAttribute('method', value)
    return value
  },
})

$.fn.originalScrollTop = $.fn.scrollTop
$.fn.scrollTop = function () {
  if (this.selector == 'html,body' && arguments.length === 0) {
    console.error(
      "$('html,body').scrollTop() is not cross-browser compatible... use $.windowScrollTop() instead"
    )
  }
  return $.fn.originalScrollTop.apply(this, arguments)
}
// Different browsers (and even different versions of the same browser) differ
// on whether <body> or <html> is the scrolling element for a window. This is a
// utility that returns the correct scroll y-position of the window in every
// browser and version.
//
// see https://drafts.csswg.org/cssom-view/#dom-element-scrolltop for morbid
// details of how the scrollTop attribute is calculated.
$.windowScrollTop = function () {
  // $.browser.safari is true for chrome.
  // with chrome 61, we want the documentElement.scrollTop, so the
  // original code (now the else block) always returns 0.
  // if chrome > 60, force it to return documentElement.scrollTop
  const chromeVer = window.navigator.userAgent.match(/Chrome\/(\d+)/)
  // edge 42+ also reports as chrome 64+, so exclude it explicitly. yay user agent sniffing.
  const edgeVer = window.navigator.userAgent.match(/Edge\/(\d+)/)
  if (!edgeVer && chromeVer && parseInt(chromeVer[1], 10) > 60) {
    return $('html').scrollTop()
  } else if ($.browser.safari) {
    // Safari 13 has changed document.scrollingElement from <body> => <html>.
    // As a result, it is now reporting $('body').scrollTop() == 0 as the <body>
    // element no longer has a scrolling area.
    // $('html').scrollTop() is now returning the scroll position like other
    // browsers that use <html> as the scrolling element.
    const safariVer = window.navigator.userAgent.match(/Version\/(\d+).*Safari/)
    return (safariVer && parseInt(safariVer[1], 10) < 13 ? $('body') : $('html')).scrollTop()
  } else {
    return $('html').scrollTop()
  }
}

// indicate we want stringified IDs for JSON responses
$.ajaxPrefilter('json', (options, _originalOptions, _jqXHR) => {
  if (options.accepts.json) {
    options.accepts.json += ', application/json+canvas-string-ids'
  } else {
    options.accepts.json = 'application/json+canvas-string-ids'
  }
})

// see: https://github.com/rails/jquery-ujs/blob/master/src/rails.js#L80
const CSRFProtection = function (xhr) {
  const csrfToken = getCookie('_csrf_token')
  if (csrfToken) xhr.setRequestHeader('X-CSRF-Token', csrfToken)
}

$.ajaxPrefilter((options, originalOptions, jqXHR) => {
  if (!options.crossDomain) CSRFProtection(jqXHR)
})

export default $
