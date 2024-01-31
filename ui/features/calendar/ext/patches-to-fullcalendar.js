/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import fullCalendar from 'fullcalendar'
import htmlEscape from '@instructure/html-escape'

// set up a custom view for the agendaWeek day/date header row
const _originalHeadCellHtml = fullCalendar.Grid.prototype.headCellHtml

// duplicate var from vender fullcalendar.js so can access here
const dayIDs = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat']

fullCalendar.Grid.prototype.headCellHtml = function (cell) {
  if (this.view.name === 'agendaWeek') {
    const date = cell.start
    return `
  			<th class="fc-day-header ${htmlEscape(this.view.widgetHeaderClass)} fc-${htmlEscape(
      dayIDs[date.day()]
    )}">
        	<div class="fc-day-header__week-number">${htmlEscape(date.format('D'))}</div>
        	<div class="fc-day-header__week-day">${htmlEscape(date.format('ddd'))}</div>
        </th>`
  } else {
    return _originalHeadCellHtml.apply(this, arguments)
  }
}
