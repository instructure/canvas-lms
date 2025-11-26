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

import type {DateFilterOption} from '../components/shared/CourseWorkFilters'

export const startOfToday = () => {
  const now = new Date()
  return new Date(now.getFullYear(), now.getMonth(), now.getDate())
}

export const endOfDay = (d: Date) =>
  new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59, 59, 999)

export const addDays = (d: Date, n: number) => {
  const copy = new Date(d)
  copy.setDate(copy.getDate() + n)
  return copy
}

export const getTomorrow = () => {
  const today = startOfToday()
  return addDays(today, 1)
}

export function convertDateFilterToParams(filter: DateFilterOption) {
  const today = startOfToday()
  const now = new Date()

  switch (filter) {
    case 'not_submitted':
      return {
        startDate: now.toISOString(),
        endDate: undefined,
        includeOverdue: false,
        includeNoDueDate: false,
        onlySubmitted: false,
      }
    case 'missing':
      return {
        startDate: undefined,
        endDate: undefined,
        includeOverdue: true,
        includeNoDueDate: false,
        onlySubmitted: false,
      }
    case 'submitted':
      return {
        startDate: undefined,
        endDate: undefined,
        includeOverdue: false,
        includeNoDueDate: false,
        onlySubmitted: true,
      }
    default:
      return {
        startDate: undefined,
        endDate: undefined,
        includeOverdue: false,
        includeNoDueDate: false,
        onlySubmitted: false,
      }
  }
}

export function convertDateFilterToStatisticsRange(filter: DateFilterOption) {
  const now = new Date()
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate())

  const endOfDays = (days: number) => {
    const endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() + days + 1)
    endDate.setMilliseconds(-1)
    return endDate
  }

  switch (filter) {
    case 'not_submitted':
    case 'missing':
    case 'submitted':
    default:
      return {
        startDate: startOfToday,
        endDate: addDays(startOfToday, 90),
      }
  }
}
