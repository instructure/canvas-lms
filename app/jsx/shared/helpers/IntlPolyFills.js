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

// Node versions < 13 do not come with implementations of ICU, so window.Intl
// is just an empty object. Since we are making some use of it, we need to add
// some limited-function polyfills so that Jest tests can run. This file can be
// added to as needed, and (hopefully) someday removed entirely when the native
// functions become available to Jest.

// All of these only implement the en-US locale, as do most of our tests anyway.

//
// RelativeTimeFormat converts a relative time offset in milliseconds, and a
// time unit (second, minute, etc) into a text string.
//
// This implements numeric: 'auto' but not style: 'short'
//
class RelativeTimeFormat {
  constructor(locale, opts = {}) {
    this.locale = locale
    this.numeric = opts.numeric || 'always'
    this.style = opts.style || 'long'
    this.units = {
      second: [null, 'now', null],
      minute: [null, 'this minute', null],
      hour: [null, 'this hour', null],
      day: ['yesterday', 'today', 'tomorrow'],
      week: ['last week', 'this week', 'next week'],
      month: ['last month', 'this month', 'next month'],
      year: ['last year', 'this year', 'next year']
    }
  }

  format(num, units) {
    if (!Object.keys(this.units).includes(units))
      throw new RangeError(`Invalid unit argument ${units}'`)
    const roundNum = Math.round(num * 1000) / 1000
    if (this.numeric === 'auto' && [-1, 0, 1].includes(roundNum)) {
      const result = this.units[units][roundNum + 1]
      if (result) return result
    }
    if (roundNum === 1) return `in ${roundNum} ${units}`
    if (roundNum === -1) return `${-roundNum} ${units} ago`
    if (num >= 0) return `in ${roundNum} ${units}s`
    return `${-roundNum} ${units}s ago`
  }
}

export function installIntlPolyfills() {
  if (typeof window.Intl === 'undefined') window.Intl = {}

  if (typeof window.Intl.RelativeTimeFormat === 'undefined')
    window.Intl.RelativeTimeFormat = RelativeTimeFormat
}
