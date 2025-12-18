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

import {Filters, AppliedFilter} from '../../../shared/react/types'
import * as tz from '@instructure/moment-utils/index'

export const getAppliedFilters = (filters: Filters): AppliedFilter[] => {
  if (filters === null || filters === undefined) return []
  const appliedFilters: AppliedFilter[] = []

  Object.entries(filters).forEach(([key, value]) => {
    if (Array.isArray(value)) {
      value.forEach(v => {
        if (v.value !== 'all') {
          appliedFilters.push({key: key as keyof Filters, option: v})
        }
      })
    } else if (value instanceof Date) {
      appliedFilters.push({
        key: key as keyof Filters,
        option: {label: formatDate(value) ?? '', value: value.toISOString()},
      })
    } else if (value !== undefined && value !== null) {
      appliedFilters.push({key: key as keyof Filters, option: value})
    }
  })

  return appliedFilters
}

export const getFilters = (appliedFilters: AppliedFilter[]): Filters => {
  const filters: Partial<Filters> = {}

  appliedFilters.forEach(({key, option}) => {
    if (key === 'fromDate' || key === 'toDate') {
      filters[key] = option
    } else {
      const existing = filters[key]

      if (Array.isArray(existing)) {
        filters[key] = [...existing, option]
      } else if (existing !== undefined) {
        filters[key] = [existing, option]
      } else {
        filters[key] = [option]
      }
    }
  })
  return filters as Filters
}

export const formatDate = (date: Date) => {
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore - tz.format's third argument (zone) is optional at runtime but required by tsgo
  return tz.format(date, 'date.formats.medium_with_weekday')
}
