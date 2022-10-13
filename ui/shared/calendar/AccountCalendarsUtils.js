/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('account_calendars')

export const alertForMatchingAccounts = (results, showDefault) => {
  const polite = true
  if (showDefault) {
    const msg = I18n.t(
      {
        one: 'Showing 1 account calendar',
        other: 'Showing %{count} account calendars.',
      },
      {count: results}
    )
    return $.screenReaderFlashMessageExclusive(msg, polite)
  }
  const msg = I18n.t(
    {
      one: '1 account calendar found.',
      other: '%{count} account calendars found.',
      zero: 'No matching account calendars found.',
    },
    {count: results}
  )
  $.screenReaderFlashMessageExclusive(msg, polite)
}
