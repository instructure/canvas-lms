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

import moment from 'moment'
import getFormats from './formats'

const config = {customI18nFormats: []}

// Parse a DateTime string according to any of the pre-defined formats. The
// formats may come from Moment itself, or from the locale dictionary for
// date and time.
//
// See ./formats.js for the possible formats.
//
// @param  {Object.<{
//           t: (String) -> String,
//           lookup: (String) -> String
//         }>}
//         An object that can query the locale dictionary for datetime formats.
//
// @param  {String}
//         The string to parse.
//
// @return {Moment?}
//         A moment instance in case the string could be parsed.
export default function parseDateTime(input, locale) {
  const formats = getFormats(config)
  const momentInstance = createDateTimeMoment(input, formats, locale)

  return momentInstance.isValid() ? momentInstance : null
}

export function loadI18nFormats(customI18nFormats) {
  config.customI18nFormats = customI18nFormats
}

// Check a moment instance to see if its format (and input value) explicitly
// specify a timezone. This query is useful to know whether the date needs to
// be unfudged in case it does NOT specify a timezone (e.g. using tz-parse).
export function specifiesTimezone(m) {
  return !!(m._f.match(/Z/) && m._pf.unusedTokens.indexOf('Z') === -1)
}

export function toRFC3339WithoutTZ(m) {
  return moment(m).locale('en').format('YYYY-MM-DD[T]HH:mm:ss')
}

// wrap's moment() for parsing datetime strings. assumes the string to be
// parsed is in the profile timezone unless if contains an offset string
// *and* a format token to parse it, and unfudges the result.
export function createDateTimeMoment(input, format, locale) {
  // ensure first argument is a string and second is a format or an array
  // of formats
  if (typeof input !== 'string' || !(typeof format === 'string' || Array.isArray(format))) {
    throw new Error(
      'createDateTimeMoment only works on string+format(s). just use moment() directly for any other signature'
    )
  }

  const m = moment.apply(null, [input, format, locale])

  if (m._pf.unusedTokens.length > 0) {
    // we didn't use strict at first, because we want to accept when
    // there's unused input as long as we're using all tokens. but if the
    // best non-strict match has unused tokens, reparse with strict
    return moment.apply(null, [input, format, locale, true])
  } else {
    return m
  }
}
