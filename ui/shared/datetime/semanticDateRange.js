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

// requires $.sameDate, $.dateString, $.timeString, $.datetimeString
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import * as tz from './index'
import htmlEscape from '@instructure/html-escape'
import './jquery/index'

const I18n = useI18nScope('dates')

export default function semanticDateRange(startISO, endISO) {
  if (!startISO) {
    return `<span class="date-range date-range-no-date">
  ${htmlEscape(I18n.t('no_date', 'No Date'))}
</span>`
  }

  const startAt = tz.parse(startISO)
  const endAt = tz.parse(endISO)
  if (+startAt !== +endAt) {
    if (!$.sameDate(startAt, endAt)) {
      return `<span class="date-range">
  <time datetime='${startAt.toISOString()}'>
    ${$.datetimeString(startAt)}
  </time> -
  <time datetime='${endAt.toISOString()}'>
    ${$.datetimeString(endAt)}
  </time>
</span>`
    } else {
      return `<span class="date-range">
  <time datetime='${startAt.toISOString()}'>
    ${$.dateString(startAt)}, ${$.timeString(startAt)}
  </time> -
  <time datetime='${endAt.toISOString()}'>
    ${$.timeString(endAt)}
  </time>
</span>`
    }
  } else {
    return `<span class="date-range">
  <time datetime='${startAt.toISOString()}'>
    ${$.datetimeString(startAt)}
  </time>
</span>`
  }
}
