//
// Copyright (C) 2012 - present Instructure, Inc.
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
import {send} from '@canvas/rce/RceCommandShim'

const rselectTextarea = /^(?:select|textarea)/i
const rCRLF = /\r?\n/g
const rinput = /^(?:color|date|datetime|datetime-local|email|hidden|month|number|password|range|search|tel|text|time|url|week|file)$/i
// radio / checkbox are not included, since they are handled by the @checked check

function elements() {
  if (this.elements) {
    return $.makeArray(this.elements)
  } else {
    const els = $(this).find(':input')
    if (els.length) {
      return els
    } else {
      return this
    }
  }
}

function isSerializable() {
  return (
    this.name &&
    !this.disabled &&
    (this.checked || rselectTextarea.test(this.nodeName) || rinput.test(this.type))
  )
}

function resultFor(name, value) {
  if (typeof value === 'string') value = value.replace(rCRLF, '\r\n')
  return {name, value}
}

function getValue() {
  const $input = $(this)
  const value = (() => {
    if (this.type === 'file') {
      if ($input.val()) return this
    } else if ($input.hasClass('datetime_field_enabled')) {
      // datepicker doesn't clear the data date attribute when a date is deleted
      if ($input.val() === '') {
        return null
      } else {
        return $input.data('date') || null
      }
    } else if ($input.data('rich_text')) {
      return send($input, 'get_code', false)
    } else {
      return $input.val()
    }
  })()

  if ($.isArray(value)) {
    return value.map(val => resultFor(this.name, val))
  } else {
    return resultFor(this.name, value)
  }
}

// #
// identical to $.fn.serializeArray, except:
// 1. it works on non-forms (see elements)
// 2. it handles file, date picker and tinymce inputs (see getValue)
export default $.fn.serializeForm = function() {
  return this.map(elements)
    .filter(isSerializable)
    .map(getValue)
    .get()
}
