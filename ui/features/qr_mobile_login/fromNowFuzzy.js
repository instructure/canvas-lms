/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

const I18n = useI18nScope('fromNowFuzzy')

const TIME_UNITS = Object.freeze([
  1000, // msec in a second
  60, // seconds in a minute
  60, // minutes in an hour
  24, // hours in a day
  7 // days in a week
])

const UNIT_NAMES = Object.freeze([
  'millisecond', // not used, Intl does not understand it
  'second',
  'minute',
  'hour',
  'day',
  'week'
])

function buildTime(msec) {
  const negative = msec < 0
  // Just because it's never reassigned doesn't mean it's not mutated a lot
  // eslint-disable-next-line prefer-const
  let result = [negative]
  let remainder = negative ? -msec : msec
  TIME_UNITS.forEach(d => {
    result.push(Math.floor(remainder % d))
    remainder /= d
  })
  result.push(Math.floor(remainder))
  return result
}

function timeDistance(times, opts) {
  const {locale, ...intlOpts} = opts

  if (times.length !== TIME_UNITS.length + 2) {
    throw new Error('argument must be buildTime array')
  }
  // Just because it's never reassigned doesn't mean it's not mutated a lot
  /* eslint-disable prefer-const */
  let units = TIME_UNITS.slice().reverse()
  let unitArray = times.slice().reverse()
  let unitNames = UNIT_NAMES.slice().reverse()
  /* eslint-enable prefer-const */
  const negative = unitArray.pop()
  const rtf = new Intl.RelativeTimeFormat(locale || ENV.LOCALE || navigator.language, {
    style: 'long',
    numeric: 'auto',
    ...intlOpts
  })
  while (unitArray.length > 1 && unitArray[0] === 0) {
    unitArray.shift()
    unitNames.shift()
    units.shift()
  }

  // if only milliseconds are left, just call it "now"
  if (unitArray.length < 2) return rtf.format(0, 'second')

  // otherwise, if only seconds are left, return a friendly value
  if (unitArray.length === 2) {
    if (unitArray[0] <= 20)
      return negative ? I18n.t('a few seconds ago') : I18n.t('in a few seconds')
    return negative ? I18n.t('less than a minute ago') : I18n.t('in less than a minute')
  }

  // otherwise round up the biggest unit and use that
  const value = Math.round(unitArray[0] + unitArray[1] / units[0]) * (negative ? -1 : 1)
  return rtf.format(value, unitNames[0])
}

export function fromNow(date, opts = {}) {
  const now = Date.now()
  let thence
  if (date instanceof Date) {
    thence = date.getTime()
    if (Number.isNaN(thence)) throw new Error('argument Date is invalid')
  } else if (typeof date === 'number') {
    thence = date
  } else {
    throw new Error('argument must be Date object or numeric msec')
  }
  return timeDistance(buildTime(thence - now), opts)
}
