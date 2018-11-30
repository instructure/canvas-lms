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

import _ from 'underscore'
import I18n from 'i18n!instructure'
import moment from 'moment'

function eventTimes(dateFormats, timeFormats) {
  const formats = []
  dateFormats.forEach(df => {
    timeFormats.forEach(tf => {
      formats.push(() => I18n.t('#time.event', {
        date: I18n.lookup(`date.formats.${df}`),
        time: I18n.lookup(`time.formats.${tf}`)
      }))
    })
  })
  return formats
}

function dateFormat(key) {
  return () => I18n.lookup(`date.formats.${key}`)
}

function timeFormat(key) {
  return () => I18n.lookup(`time.formats.${key}`)
}

function joinFormats(separator, ...formats) {
  return () => formats.map(key => I18n.lookup(key)).join(separator)
}

export default {

  i18nToMomentHash: {
    '%A': 'dddd',
    '%B': 'MMMM',
    '%H': 'HH',
    '%M': 'mm',
    '%S': 'ss',
    '%P': 'a',
    '%Y': 'YYYY',
    '%a': 'ddd',
    '%b': 'MMM',
    '%m': 'M',
    '%d': 'D',
    '%k': 'H',
    '%l': 'h',
    '%z': 'Z',

    '%-H': 'H',
    '%-M': 'm',
    '%-S': 's',
    '%-m': 'M',
    '%-d': 'D',
    '%-k': 'H',
    '%-l': 'h'
  },

  basicMomentFormats: [
    moment.ISO_8601,
    'YYYY',
    'LT', 'LTS', 'L', 'l', 'LL', 'll', 'LLL', 'lll', 'LLLL', 'llll',
    'D MMM YYYY',
    'H:mm'
  ],

  getFormats () {
    let formatsToTransform = this.formatsForLocale()
    formatsToTransform = this.formatsIncludingImplicitMinutes(formatsToTransform)
    return this.transformFormats(formatsToTransform)
  },

  formatsIncludingImplicitMinutes (formats) {
    const arrayOfArrays = _.map(formats, format => format.match(/:%-?M/) ?
          [format, format.replace(/:%-?M/, '')] :
          [format])
    return _.flatten(arrayOfArrays)
  },

  transformFormats: _.memoize(function (formats) {
    const localeSpecificFormats = _.map(formats, this.i18nToMomentFormat, this)
    return _.union(this.basicMomentFormats, localeSpecificFormats)
  }),

    // examples are from en_US. order is significant since if an input matches
    // multiple formats, the format earlier in the list will be preferred
  orderedFormats: [
    timeFormat('default'),             // %a, %d %b %Y %H:%M:%S %z
    dateFormat('full_with_weekday'),   // %a %b %-d, %Y %-l:%M%P
    dateFormat('full'),                // %b %-d, %Y %-l:%M%P
    dateFormat('date_at_time'),        // %b %-d at %l:%M%P
    dateFormat('long_with_weekday'),   // %A, %B %-d
    dateFormat('medium_with_weekday'), // %a %b %-d, %Y
    dateFormat('short_with_weekday'),  // %a, %b %-d
    timeFormat('long'),                // %B %d, %Y %H:%M
    dateFormat('long'),                // %B %-d, %Y
    ...eventTimes(['medium', 'short'], ['tiny', 'tiny_on_the_hour']),
    joinFormats(' ', 'date.formats.medium', 'time.formats.tiny'),
    joinFormats(' ', 'date.formats.medium', 'time.formats.tiny_on_the_hour'),
    dateFormat('medium'),              // %b %-d, %Y
    timeFormat('short'),               // %d %b %H:%M
    joinFormats(' ', 'date.formats.short', 'time.formats.tiny'),
    joinFormats(' ', 'date.formats.short', 'time.formats.tiny_on_the_hour'),
    dateFormat('short'),               // %b %-d
    dateFormat('default'),             // %Y-%m-%d
    timeFormat('tiny'),                // %l:%M%P
    timeFormat('tiny_on_the_hour'),    // %l%P
    dateFormat('weekday'),             // %A
    dateFormat('short_weekday')        // %a
  ],

  formatsForLocale () {
    return _.compact(this.orderedFormats.map(fn => fn()))
  },

  i18nToMomentFormat (fullString) {
    const withEscapes = this.escapeSubStrings(fullString)
    return this.replaceDateKeys(withEscapes)
  },

  escapeSubStrings (formatString) {
    const substrings = formatString.split(' ')
    const escapedSubs = _.map(substrings, this.escapedUnlessi18nKey, this)
    return escapedSubs.join(' ')
  },

  escapedUnlessi18nKey (string) {
    const isKey = _.detect(_.keys(this.i18nToMomentHash), k => string.indexOf(k) > -1)

    return isKey ? string : `[${string}]`
  },

  replaceDateKeys (formatString) {
    return _.reduce(this.i18nToMomentHash, (string, forMoment, forBase) => string.replace(forBase, forMoment), formatString)
  }
}
