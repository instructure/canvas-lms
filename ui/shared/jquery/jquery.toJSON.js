/*
 * Copyright (C) 2012 - present Instructure, Inc.
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
import '@canvas/serialize-form'

const patterns = {
  validate: /^[a-zA-Z][a-zA-Z0-9_-]*(?:\[(?:\d*|[a-zA-Z0-9_-]+)\])*$/,
  key: /[a-zA-Z0-9_-]+|(?=\[\])/g,
  push: /^$/,
  fixed: /^\d+$/,
  named: /^[a-zA-Z0-9_-]+$/,
}

const build = function (base, key, value) {
  base[key] = value
  return base
}

$.fn.toJSON = function () {
  let json = {}
  const push_counters = {}

  const push_counter = function (key, i) {
    if (push_counters[key] === undefined) {
      push_counters[key] = 0
    }
    if (i === undefined) {
      return push_counters[key]++
    } else if (i !== undefined && i > push_counters[key]) {
      return (push_counters[key] = ++i)
    }
  }

  $.each($(this).serializeForm(), function () {
    // skip invalid keys
    if (!patterns.validate.test(this.name)) {
      return
    }

    let k,
      merge = this.value,
      reverse_key = this.name
    const keys = this.name.match(patterns.key)

    while ((k = keys.pop()) !== undefined) {
      // adjust reverse_key
      reverse_key = reverse_key.replace(new RegExp('\\[' + k + '\\]$'), '')

      // push
      if (k.match(patterns.push)) {
        merge = build([], push_counter(reverse_key), merge)
      }

      // fixed
      else if (k.match(patterns.fixed)) {
        push_counter(reverse_key, k)
        merge = build([], k, merge)
      }

      // named
      else if (k.match(patterns.named)) {
        merge = build({}, k, merge)
      }
    }

    json = $.extend(true, json, merge)
  })

  return json
}
