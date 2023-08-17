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

// Return the first value which passes a truth test
$.detect = function (collection, callback) {
  let result
  $.each(collection, (index, value) => {
    if (callback.call(value, value, index, collection)) {
      result = value
      return false // we found it, break the $.each() loop iteration by returning false
    }
  })
  return result
}

$.encodeToHex = function (str) {
  let hex = ''
  for (let i = 0; i < str.length; i++) {
    let part = str.charCodeAt(i).toString(16)
    while (part.length < 2) {
      part = '0' + part
    }
    hex += part
  }
  return hex
}
$.decodeFromHex = function (str) {
  let r = ''
  let i = 0
  while (i < str.length) {
    r += unescape('%' + str.substring(i, i + 2))
    i += 2
  }
  return r
}

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

$.replaceOneTag = function (text, name, value) {
  if (!text) {
    return text
  }
  name = (name || '').toString()
  value = (value || '').toString().replace(/\s/g, '+')
  const itemExpression = new RegExp('(%7B|{){2}[\\s|%20|+]*' + name + '[\\s|%20|+]*(%7D|}){2}', 'g')
  return text.replace(itemExpression, value)
}
// backwards compatible with only one tag
$.replaceTags = function (text, mapping_or_name, maybe_value) {
  if (typeof mapping_or_name === 'object') {
    for (const name in mapping_or_name) {
      text = $.replaceOneTag(text, name, mapping_or_name[name])
    }
    return text
  } else {
    return $.replaceOneTag(text, mapping_or_name, maybe_value)
  }
}

$.titleize = function (string) {
  const res = (string || '')
    .replace(/([A-Z])/g, ' $1')
    .replace(/_/g, ' ')
    .replace(/\s+/, ' ')
    .replace(/^\s/, '')
  return $.map(res.split(/\s/), word => (word[0] || '').toUpperCase() + word.substring(1)).join(' ')
}

// return query string parameter
// $.queryParam("name") => qs value or null
$.queryParam = function (name) {
  name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]')
  const regex = new RegExp('[\\?&]' + name + '=([^&#]*)')
  const results = regex.exec(window.location.search)
  if (results == null) return results
  else return decodeURIComponent(results[1].replace(/\+/g, ' '))
}

$.capitalize = function (string) {
  return string.charAt(0).toUpperCase() + string.substring(1).toLowerCase()
}

INST.youTubeRegEx = /^https?:\/\/(www\.youtube\.com\/watch.*v(=|\/)|youtu\.be\/)([^&#]*)/
$.youTubeID = function (path) {
  const match = path.match(INST.youTubeRegEx)
  if (match && match[match.length - 1]) {
    return match[match.length - 1]
  }
  return null
}
