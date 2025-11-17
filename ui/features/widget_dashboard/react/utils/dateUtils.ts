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
    case 'next3days':
      return {
        startDate: now.toISOString(),
        endDate: addDays(today, 3).toISOString(),
        includeOverdue: false,
        includeNoDueDate: false,
        onlySubmitted: false,
      }
    case 'next7days':
      return {
        startDate: now.toISOString(),
        endDate: addDays(today, 7).toISOString(),
        includeOverdue: false,
        includeNoDueDate: false,
        onlySubmitted: false,
      }
    case 'next14days':
      return {
        startDate: now.toISOString(),
        endDate: addDays(today, 14).toISOString(),
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

  // Helper function to create end of day for N days from today
  const endOfDays = (days: number) => {
    const endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() + days + 1)
    endDate.setMilliseconds(-1) // Set to 23:59:59.999 of the last day
    return endDate
  }

  switch (filter) {
    case 'next3days':
      return {
        startDate: startOfToday,
        endDate: endOfDays(2), // Today + 2 more days = 3 days total
      }
    case 'next7days':
      return {
        startDate: startOfToday,
        endDate: endOfDays(6), // Today + 6 more days = 7 days total
      }
    case 'next14days':
      return {
        startDate: startOfToday,
        endDate: endOfDays(13), // Today + 13 more days = 14 days total
      }
    case 'missing':
    case 'submitted':
    case 'all':
    default:
      // For missing/submitted/all, show all-time statistics
      return {
        startDate: startOfToday,
        endDate: endOfDays(13), // Default to 14-day window for consistency
      }
  }
}
