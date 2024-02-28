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
import 'jquery-migrate'
import getCookie from '@instructure/get-cookie'

$.migrateMute = true

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
