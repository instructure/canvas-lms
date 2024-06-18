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

import {useScope as useI18nScope} from '@canvas/i18n'
import * as tz from '@instructure/moment-utils'
import {sameDate, timeString, dateString, datetimeString} from './date-functions'
import htmlEscape from '@instructure/html-escape'

const I18n = useI18nScope('dates')

export default function semanticDateRange(startISO, endISO) {
  const container = document.createElement('span')
  container.className = 'date-range'

  if (!startISO) {
    container.classList.add('date-range-no-date')
    container.textContent = htmlEscape(I18n.t('no_date', 'No Date'))
    return container.outerHTML
  }

  const startAt = tz.parse(startISO)
  const endAt = tz.parse(endISO)

  if (+startAt !== +endAt) {
    if (!sameDate(startAt, endAt)) {
      const time1 = document.createElement('time')
      time1.setAttribute('datetime', startAt.toISOString())
      time1.textContent = datetimeString(startAt)
      container.appendChild(time1)

      const dash = document.createTextNode(' - ')
      container.appendChild(dash)

      const time2 = document.createElement('time')
      time2.setAttribute('datetime', endAt.toISOString())
      time2.textContent = datetimeString(endAt)
      container.appendChild(time2)
    } else {
      const time1 = document.createElement('time')
      time1.setAttribute('datetime', startAt.toISOString())
      time1.textContent = `${dateString(startAt)}, ${timeString(startAt)}`
      container.appendChild(time1)

      const dash = document.createTextNode(' - ')
      container.appendChild(dash)

      const time2 = document.createElement('time')
      time2.setAttribute('datetime', endAt.toISOString())
      time2.textContent = timeString(endAt)
      container.appendChild(time2)
    }
  } else {
    const time = document.createElement('time')
    time.setAttribute('datetime', startAt.toISOString())
    time.textContent = datetimeString(startAt)
    container.appendChild(time)
  }

  return container.outerHTML
}
