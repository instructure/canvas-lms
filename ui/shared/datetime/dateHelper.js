/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import {isUndefined, each} from 'lodash'
import $ from 'jquery'
import * as tz from './index'
import './jquery/index'

const DateHelper = {
  parseDates(object, datesToParse) {
    each(datesToParse, dateString => {
      const propertyExists = !isUndefined(object[dateString])
      if (propertyExists) object[dateString] = tz.parse(object[dateString])
    })
    return object
  },

  formatDatetimeForDisplay(date, format = 'medium') {
    return $.datetimeString(date, {format, timezone: ENV.CONTEXT_TIMEZONE})
  },

  formatDatetimeForDiscussions(datetime, format = '', timezone = ENV.TIMEZONE) {
    return $.discussionsDatetimeString(datetime, {format, timezone})
  },

  formatDateForDisplay(date, format = 'medium', timezone = ENV.CONTEXT_TIMEZONE) {
    return $.dateString(date, {format, timezone})
  },

  isMidnight(date) {
    return tz.isMidnight(date)
  },
}

export default DateHelper
