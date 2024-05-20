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

import {useScope as useI18nScope} from '@canvas/i18n'
import h, {raw} from '@instructure/html-escape'
import listFormatterPolyfill from '@canvas/util/listFormatter'
import '@canvas/jquery/jquery.instructure_misc_helpers'

const I18n = useI18nScope('listWithOthers')

const listFormatter = Intl.ListFormat
  ? new Intl.ListFormat(ENV.LOCALE || navigator.language)
  : listFormatterPolyfill

export default function listWithOthers(strings, cutoff = 2) {
  if (strings.length > cutoff) {
    strings = strings.slice(0, cutoff).concat([strings.slice(cutoff, strings.length)])
  }
  // this is a strange use of list formatting, since the items can
  // themselves be lists
  return listFormatter.format(
    strings.map(strOrArray =>
      typeof strOrArray === 'string' || strOrArray instanceof h.SafeString
        ? `<span>${h(strOrArray)}</span>`
        : `
        <span class='others'>
          ${h(I18n.t('other', 'other', {count: strOrArray.length}))}
          <span>
            <ul>
              ${raw(strOrArray.map(str => `<li>${h(str)}</li>`).join(''))}
            </ul>
          </span>
        </span>`
    )
  )
}
