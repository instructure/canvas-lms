#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

# requires $.sameDate, $.dateString, $.timeString, $.datetimeString
define ['i18n!dates', 'jquery', 'timezone', 'str/htmlEscape', 'jquery.instructure_date_and_time'], (I18n, $, tz, htmlEscape) ->
  semanticDateRange = (startISO, endISO) ->
    unless startISO
      return """
        <span class="date-range date-range-no-date">
          #{htmlEscape I18n.t 'no_date', 'No Date'}
        </span>
      """

    startAt = tz.parse(startISO)
    endAt = tz.parse(endISO)
    if +startAt != +endAt
      if !$.sameDate(startAt, endAt)
        """
        <span class="date-range">
          <time datetime='#{startAt.toISOString()}'>
            #{$.datetimeString(startAt)}
          </time> -
          <time datetime='#{endAt.toISOString()}'>
            #{$.datetimeString(endAt)}
          </time>
        </span>
        """
      else
        """
        <span class="date-range">
          <time datetime='#{startAt.toISOString()}'>
            #{$.dateString(startAt)}, #{$.timeString(startAt)}
          </time> -
          <time datetime='#{endAt.toISOString()}'>
            #{$.timeString(endAt)}
          </time>
        </span>
        """
    else
      """
      <span class="date-range">
        <time datetime='#{startAt.toISOString()}'>
          #{$.datetimeString(startAt)}
        </time>
      </span>
      """
