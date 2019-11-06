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
import getCookie from '../../app/jsx/shared/helpers/getCookie'

// monkey patch jquery's JSON parsing so we can have all of our ajax responses return with
// 'while(1);' prepended to them to protect against a CSRF attack vector.
const _parseJSON = $.parseJSON
$.parseJSON = function() {
  if (arguments[0]) {
    try {
      const newData = arguments[0].replace(/^while\(1\);/, '')
      arguments[0] = newData
    } catch (err) {
      // data was not a string or something, just pass along to the real parseJSON
      // and let it handle errors.
    }
  }
  return _parseJSON.apply($, arguments)
}
$.ajaxSettings.converters['text json'] = $.parseJSON

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
  }
})

$.fn.originalScrollTop = $.fn.scrollTop
$.fn.scrollTop = function() {
  if (this.selector == 'html,body' && arguments.length === 0) {
    console.error(
      "$('html,body').scrollTop() is not cross-browser compatible... use $.windowScrollTop() instead"
    )
  }
  return $.fn.originalScrollTop.apply(this, arguments)
}
$.windowScrollTop = function() {
  // $.browser.safari is true for chrome.
  // with chrome 61, we want the documentElement.scrollTop, so the
  // original code (now the else block) always returns 0.
  // if chrome > 60, force it to return documentElement.scrollTop
  const chromeVer = window.navigator.userAgent.match(/Chrome\/(\d+)/)
  // edge 42+ also reports as chrome 64+, so exclude it explicitly. yay user agent sniffing.
  const edgeVer = window.navigator.userAgent.match(/Edge\/(\d+)/)
  if (!edgeVer && chromeVer && parseInt(chromeVer[1], 10) > 60) {
    return $('html').scrollTop()
  } else {
    return ($.browser.safari ? $('body') : $('html')).scrollTop()
  }
}

// indicate we want stringified IDs for JSON responses
$.ajaxPrefilter('json', (options, originalOptions, jqXHR) => {
  if (options.accepts.json)
    options.accepts.json = options.accepts.json + ', application/json+canvas-string-ids'
  else options.accepts.json = 'application/json+canvas-string-ids'
})

// see: https://github.com/rails/jquery-ujs/blob/master/src/rails.js#L80
const CSRFProtection = function(xhr) {
  const csrfToken = getCookie('_csrf_token')
  if (csrfToken) xhr.setRequestHeader('X-CSRF-Token', csrfToken)
}

$.ajaxPrefilter((options, originalOptions, jqXHR) => {
  if (!options.crossDomain) CSRFProtection(jqXHR)
})

export default $
