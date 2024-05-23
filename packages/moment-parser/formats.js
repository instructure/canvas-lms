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

export default function getFormats({customI18nFormats}) {
  const i18nFormatsForCurrentLocale = customI18nFormats.map(x => x()).filter(x => !!x)
  const momentCompatibleI18nFormats = specifyMinutesImplicitly(i18nFormatsForCurrentLocale).map(
    convertI18nFormatToMomentFormat
  )

  return union(momentStockFormats, momentCompatibleI18nFormats)
}

const union = (a, b) =>
  b.reduce((acc, x) => {
    if (!acc.includes(x)) {
      acc.push(x)
    }

    return acc
  }, [].concat(a))

const i18nToMomentTokenMapping = {
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
  '%-l': 'h',
}

const momentStockFormats = [
  moment.ISO_8601,
  'YYYY',
  'LT',
  'LTS',
  'L',
  'l',
  'LL',
  'll',
  'LLL',
  'lll',
  'LLLL',
  'llll',
  'D MMM YYYY',
  'H:mm',
]

// expand every i18n format that specifies minutes (%M or %-M) into two: one
// that specifies the minutes and another that doesn't
//
// why? don't ask me
const specifyMinutesImplicitly = formats =>
  formats
    .map(format => (format.match(/:%-?M/) ? [format, format.replace(/:%-?M/, '')] : [format]))
    .flat(1)

const convertI18nFormatToMomentFormat = i18nFormat => {
  const escapeNonI18nTokens = string => string.split(' ').map(escapeUnlessIsI18nToken).join(' ')

  const escapeUnlessIsI18nToken = string => {
    const isKey = Object.keys(i18nToMomentTokenMapping).find(k => string.indexOf(k) > -1)

    return isKey ? string : `[${string}]`
  }

  const escapedI18nFormat = escapeNonI18nTokens(i18nFormat)

  return Object.keys(i18nToMomentTokenMapping).reduce(
    (acc, i18nToken) => acc.replace(i18nToken, i18nToMomentTokenMapping[i18nToken]),
    escapedI18nFormat
  )
}
