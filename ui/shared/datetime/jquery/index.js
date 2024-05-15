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
import DatetimeField from './DatetimeField'
import '@canvas/jquery-keycodes'
import 'jqueryui/datepicker'
import './datepicker'

$.fn.date_field = function (options) {
  options = {...options}
  options.dateOnly = true
  this.datetime_field(options)
  return this
}

$.fn.time_field = function (options) {
  options = {...options}
  options.timeOnly = true
  this.datetime_field(options)
  return this
}

$.fn.datetime_field = function (options) {
  options = {...options}
  this.each(function () {
    const $field = $(this)
    if (!$field.hasClass('datetime_field_enabled')) {
      $field.addClass('datetime_field_enabled')
      new DatetimeField($field, options)
    }
  })
  return this
}

export default $
