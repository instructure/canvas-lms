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
import htmlEscape from 'html-escape'

if (!('INST' in window)) window.INST = {}

// useful for i18n, e.g. t('key', 'pick one: %{select}', {select: $.raw('<select><option>...')})
// note that raw returns a SafeString object, so you may want to call toString
// if you're using it elsewhere
$.raw = function (str) {
  return new htmlEscape.SafeString(str)
}
// ensure the jquery html setters don't puke if given a SafeString
$.each(['html', 'append', 'prepend'], function (idx, method) {
  const orig = $.fn[method]
  $.fn[method] = function () {
    const args = [].slice.call(arguments)
    for (let i = 0, len = args.length; i < len; i++) {
      if (args[i] instanceof htmlEscape.SafeString) args[i] = args[i].toString()
    }
    return orig.apply(this, args)
  }
})