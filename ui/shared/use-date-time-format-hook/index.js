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

import {useCallback, useMemo} from 'react'

const DEFAULT_FORMAT = 'time.formats.default'

const optionsList = {
  'time.formats.default': {
    // ddd, D MMM YYYY HH:mm:ss Z
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: 'numeric',
    second: 'numeric',
    timeZoneName: 'short'
  },
  'date.formats.date_at_time': {
    // MMM D [at] h:mma
    name: 'date.formats.date_at_time',
    dateStyle: 'long',
    timeStyle: 'short'
  },
  'date.formats.long_with_weekday': {
    // dddd, MMMM D
    weekday: 'long',
    month: 'long',
    day: 'numeric'
  },
  'date.formats.medium_with_weekday': {
    // ddd MMM D, YYYY
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  },
  'date.formats.short_with_weekday': {
    // ddd, MMM D
    weekday: 'short',
    month: 'short',
    day: 'numeric'
  },
  'date.formats.short': {
    // MMM D
    month: 'short',
    day: 'numeric'
  }
}

Object.keys(optionsList).forEach(x => Object.freeze(optionsList[x]))
Object.freeze(optionsList)

export default function useDateTimeFormat(formatName, timeZone, locale) {
  locale = locale || ENV?.LOCALE || navigator.language
  timeZone = timeZone || ENV?.TIMEZONE || Intl.DateTimeFormat().resolvedOptions().timeZone

  const formatter = useMemo(() => {
    const options = {...(optionsList[formatName] || optionsList[DEFAULT_FORMAT])}
    return new Intl.DateTimeFormat(locale, {...options, timeZone})
  }, [formatName, locale, timeZone])

  return useCallback(
    date => formatter.format(date instanceof Date ? date : new Date(date)),
    [formatter]
  )
}
