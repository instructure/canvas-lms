/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

const I18n = useI18nScope('fuzzy-relative-time')

declare const ENV: {readonly LOCALES: string[]}

type UnitNames = 'millisecond' | 'second' | 'minute' | 'hour' | 'day' | 'week'

type Units = Record<UnitNames, number> & {negative: boolean}

const TIME_UNITS: Readonly<Omit<Units, 'negative'>> = Object.freeze({
  millisecond: 1000, // in a second
  second: 60, // in a minute
  minute: 60, // in an hour
  hour: 24, // in a day
  day: 7, // in a week
  week: 0, // last unit placeholder
})

function buildTime(msec: number): Units {
  const result: Units = {
    millisecond: 0,
    second: 0,
    minute: 0,
    hour: 0,
    day: 0,
    week: 0,
    negative: msec < 0,
  }
  const units = Object.keys(TIME_UNITS) as UnitNames[]
  let remainder = result.negative ? -msec : msec
  units.forEach((unit, i) => {
    const d = TIME_UNITS[unit]
    if (d === 0) {
      // if last unit, stop the divide chain here
      result[units[i]] = Math.floor(remainder)
      return
    }
    result[units[i]] = Math.floor(remainder % d)
    remainder /= d
  })
  return result
}

function timeDistance(
  times: Units,
  opts: {locale?: string | string[]; [k: string]: unknown}
): string {
  const {locale, ...intlOpts} = opts
  const neg = times.negative ? -1 : 1

  const rtf = new Intl.RelativeTimeFormat(locale ?? ENV.LOCALES ?? navigator.language, {
    style: 'long',
    numeric: 'auto',
    ...intlOpts,
  })

  const units = Object.keys(TIME_UNITS).reverse() as UnitNames[] // biggest unit first, now

  // find the largest non-zero unit by removing the leading zeroes
  while (units.length > 1 && times[units[0]] === 0) units.shift()

  // if only milliseconds are left, just call it "now"
  if (units[0] === 'millisecond') return rtf.format(0, 'second')

  // otherwise, if only seconds are left, return a friendly value
  if (units[0] === 'second') {
    if (times.second <= 20)
      return neg < 0 ? I18n.t('a few seconds ago') : I18n.t('in a few seconds')
    return neg < 0 ? I18n.t('less than a minute ago') : I18n.t('in less than a minute')
  }

  // othrewise, round up the biggest unit and use that
  const value = Math.round(times[units[0]] + times[units[1]] / TIME_UNITS[units[1]]) * neg
  return rtf.format(value, units[0])
}

export function fromNow(date: unknown, opts = {}) {
  const now = Date.now()
  let thence
  if (date instanceof Date) {
    thence = date.getTime()
    if (Number.isNaN(thence)) throw new RangeError('argument Date is invalid')
  } else if (typeof date === 'number') {
    thence = date
  } else {
    throw new RangeError('argument must be Date object or numeric msec')
  }
  return timeDistance(buildTime(thence - now), opts)
}
