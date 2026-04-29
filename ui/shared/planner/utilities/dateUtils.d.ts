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

import type {Moment} from 'moment-timezone'

/** Input types that can be parsed as a date/moment */
type MomentInput = Date | string | number | Moment | null | undefined

/**
 * Formats a time string for display
 * @param date - The date/time to format
 * @param timeZone - Optional timezone string (e.g., 'America/Denver')
 * @returns Formatted time string
 */
export function timeString(date: MomentInput, timeZone?: string): string

/**
 * Formats a date string for display
 * @param date - The date to format
 * @param userTZ - Optional user timezone string
 * @returns Formatted date string
 */
export function dateString(date: MomentInput, userTZ?: string): string

/**
 * Formats a date range as a string
 * @param start - Start date of the range
 * @param end - End date of the range
 * @param userTZ - Optional user timezone string
 * @returns Formatted date range string
 */
export function dateRangeString(start: MomentInput, end: MomentInput, userTZ?: string): string

/**
 * Formats a datetime string for display
 * @param date - The date/time to format
 * @param timeZone - Optional timezone string
 * @returns Formatted datetime string
 */
export function dateTimeString(date: MomentInput, timeZone?: string): string

/**
 * Checks if a date is today
 * @param date - The date to check
 * @param today - Optional reference date for "today"
 * @returns True if the date is today
 */
export function isToday(date: MomentInput, today?: Moment): boolean

/**
 * Checks if a date is in the future
 * @param date - The date to check
 * @param today - Optional reference date
 * @returns True if the date is in the future
 */
export function isInFuture(date: MomentInput, today?: Moment): boolean

/**
 * Checks if a date is today or before
 * @param date - The date to check
 * @param today - Optional reference date
 * @returns True if the date is today or earlier
 */
export function isTodayOrBefore(date: MomentInput, today?: Moment): boolean

/**
 * Gets a friendly date string (Today, Tomorrow, Yesterday, or day name)
 * @param date - The date to format
 * @param today - Optional reference date
 * @returns Friendly date string
 */
export function getFriendlyDate(date: MomentInput, today?: Moment): string
