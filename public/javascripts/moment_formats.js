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
import I18n from 'i18nObj'
import moment from 'moment'

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
    'time.formats.default',             // %a, %d %b %Y %H:%M:%S %z
    'date.formats.full_with_weekday',   // %a %b %-d, %Y %-l:%M%P
    'date.formats.full',                // %b %-d, %Y %-l:%M%P
    'date.formats.date_at_time',        // %b %-d at %l:%M%P
    'date.formats.long_with_weekday',   // %A, %B %-d
    'date.formats.medium_with_weekday', // %a %b %-d, %Y
    'date.formats.short_with_weekday',  // %a, %b %-d
    'time.formats.long',                // %B %d, %Y %H:%M
    'date.formats.long',                // %B %-d, %Y
    'date.formats.medium+_+time.formats.tiny',
    'date.formats.medium+_+time.formats.tiny_on_the_hour',
    'date.formats.medium',              // %b %-d, %Y
    'time.formats.short',               // %d %b %H:%M
    'date.formats.short+_+time.formats.tiny',
    'date.formats.short+_+time.formats.tiny_on_the_hour',
    'date.formats.short',               // %b %-d
    'date.formats.default',             // %Y-%m-%d
    'time.formats.tiny',                // %l:%M%P
    'time.formats.tiny_on_the_hour',    // %l%P
    'date.formats.weekday',             // %A
    'date.formats.short_weekday'        // %a
  ],

  formatsForLocale () {
    return _.compact(_.map(this.orderedFormats, key => key.split('+')
      .map(format => format !== '_' ? I18n.lookup(format) : ' ')
      .reduce((a, b) => a + b)
    ))
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
