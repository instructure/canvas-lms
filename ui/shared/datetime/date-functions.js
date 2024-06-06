/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import {dateString, timeString, parse} from '@instructure/moment-utils'

const I18n = useI18nScope('instructure_date_and_time')

export function datetimeString(datetime, options) {
  datetime = parse(datetime)
  if (datetime == null) return ''
  const dateValue = dateString(datetime, options)
  const timeValue = timeString(datetime, options)
  return I18n.t('#time.event', '%{date} at %{time}', {date: dateValue, time: timeValue})
}
// end batch

export function discussionsDatetimeString(datetime, options) {
  datetime = parse(datetime)
  if (datetime == null) return ''
  const dateValue = dateString(datetime, options)
  const timeValue = timeString(datetime, options)
  return I18n.t('#timeValue.event', '%{dateValue} %{timeValue}', {dateValue, timeValue})
}

export function friendlyDate(datetime, perspective) {
  if (perspective == null) {
    perspective = 'past'
  }
  const today = Date.today()
  const date = datetime.clone().clearTime()
  if (Date.equals(date, today)) {
    return I18n.t('#date.days.today', 'Today')
  } else if (Date.equals(date, today.add(-1).days())) {
    return I18n.t('#date.days.yesterday', 'Yesterday')
  } else if (Date.equals(date, today.add(1).days())) {
    return I18n.t('#date.days.tomorrow', 'Tomorrow')
  } else if (perspective === 'past' && date < today && date >= today.add(-6).days()) {
    return I18n.l('#date.formats.weekday', date)
  } else if (perspective === 'future' && date < today.add(7).days() && date >= today) {
    return I18n.l('#date.formats.weekday', date)
  }
  return I18n.l('#date.formats.medium', date)
}

export function friendlyDatetime(datetime, perspective) {
  const today = Date.today()
  if (Date.equals(datetime.clone().clearTime(), today)) {
    return I18n.l('#time.formats.tiny', datetime)
  } else {
    return friendlyDate(datetime, perspective)
  }
}

// temporary until imports are cleaned up
export {
  dateString,
  fudgeDateForProfileTimezone,
  sameDate,
  sameYear,
  timeString,
  unfudgeDateForProfileTimezone,
} from '@instructure/moment-utils'
