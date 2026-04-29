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

/** Input types that can be parsed as a date */
type DateInput = Date | string | number | null | undefined

/** Options for date/time formatting */
interface DateTimeOptions {
  timezone?: string
  format?: string
  [key: string]: unknown
}

/**
 * Formats a datetime into a localized string with both date and time
 * @param datetime - The date/time to format
 * @param options - Formatting options
 * @returns Formatted string like "Jan 15, 2025 at 3:30pm"
 */
export function datetimeString(datetime: DateInput, options?: DateTimeOptions): string

/**
 * Formats a datetime for discussions display
 * @param datetime - The date/time to format
 * @param options - Formatting options
 * @returns Formatted string for discussions
 */
export function discussionsDatetimeString(datetime: DateInput, options?: DateTimeOptions): string

/**
 * Formats a date (without time) into a localized string
 * @param date - The date to format
 * @param options - Formatting options
 * @returns Formatted date string
 */
export function dateString(date: DateInput, options?: DateTimeOptions): string

/**
 * Formats a time (without date) into a localized string
 * @param date - The date/time to extract time from
 * @param options - Formatting options
 * @returns Formatted time string
 */
export function timeString(date: DateInput, options?: DateTimeOptions): string

/**
 * Adjusts a date for the user's profile timezone
 * @param date - The date to adjust
 * @returns Adjusted date or null
 */
export function fudgeDateForProfileTimezone(date: DateInput): Date | null

/**
 * Formats a datetime in a friendly, relative format (e.g., "Today", "Yesterday")
 * @param datetime - The date/time to format
 * @param opts - Options including perspective ('past' or 'future')
 * @returns Friendly formatted string
 */
export function friendlyDatetime(
  datetime: DateInput,
  opts?: DateTimeOptions & {perspective?: 'past' | 'future'},
): string
