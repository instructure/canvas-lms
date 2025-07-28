/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import numberFormat from '@canvas/i18n/numberFormat'

const I18n = createI18nScope('files_v2')

export const getI18nPaginationInfo = (currentPage: number, totalItems: number, perPage: number) => {
  const formattedFrom = numberFormat._format((currentPage - 1) * perPage + 1, {})
  const formattedTo = numberFormat._format(Math.min(currentPage * perPage, totalItems), {})
  const formattedTotal = numberFormat._format(totalItems, {})

  return I18n.t('%{from}-%{to} of %{total}', {
    from: formattedFrom,
    to: formattedTo,
    total: formattedTotal,
  })
}
