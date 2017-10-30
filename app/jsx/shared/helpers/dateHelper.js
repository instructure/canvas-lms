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

import _ from 'underscore';
import $ from 'jquery';
import tz from 'timezone';
import 'jquery.instructure_date_and_time';

const DateHelper = {
  parseDates (object, datesToParse) {
    _.each(datesToParse, (dateString) => {
      const propertyExists = !_.isUndefined(object[dateString]);
      if (propertyExists) object[dateString] = tz.parse(object[dateString]);
    });
    return object;
  },

  formatDatetimeForDisplay (date, format = 'medium') {
    return $.datetimeString(date, { format, timezone: ENV.CONTEXT_TIMEZONE });
  },

  formatDateForDisplay (date) {
    return $.dateString(date, { format: 'medium', timezone: ENV.CONTEXT_TIMEZONE });
  },

  isMidnight (date) {
    return tz.isMidnight(date);
  }
};

export default DateHelper;
