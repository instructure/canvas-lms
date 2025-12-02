/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {compact, flatMap, groupBy, map} from 'es-toolkit/compat'

export const sortedRowKeys = rows => {
  const {datedKeys, numberedKeys} = groupBy(Object.keys(rows), key =>
    key.length > 11 ? 'datedKeys' : 'numberedKeys',
  )
  return compact([datedKeys, numberedKeys].flat())
}

export const datesFromOverride = override => ({
  due_at: override ? override.get('due_at') : null,
  lock_at: override ? override.get('lock_at') : null,
  unlock_at: override ? override.get('unlock_at') : null,
})

export const rowsFromOverrides = assignmentOverrides => {
  const overridesByKey = groupBy(assignmentOverrides, override => {
    override.set('rowKey', override.combinedDates())
    return override.get('rowKey')
  })

  return Object.fromEntries(
    Object.entries(overridesByKey).map(([key, overrides]) => {
      const datesForGroup = datesFromOverride(overrides[0])
      return [key, {overrides, dates: datesForGroup, persisted: true}]
    }),
  )
}

export const getAllOverrides = givenRows => {
  const rows = givenRows
  return compact(
    flatMap(Object.values(rows), row =>
      map(row.overrides, override => {
        override.attributes.persisted = row.persisted
        return override
      }),
    ),
  )
}
