/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

/**
 * Returns null if the string is null, undefined, or has length === 0
 *
 * @param str
 */
export function emptyAsNull(str: string | null | undefined): string | null {
  if (str == null) return null
  if (str.length === 0) return null

  return str
}

/**
 * Returns null if the string is null, undefined, is empty, or contains only whitespace.
 *
 * Otherwise returns the string with leading and trailing whitespace removed.
 *
 * Useful for providing a default value for a string input:
 *
 * ```
 * label.innerText = trimmedOrNull(input.value) ?? 'Default value'
 * ```
 *
 * @param str
 */
export function trimmedOrNull(str: string | null | undefined): string | null {
  if (str == null) return null

  str = str.trim()

  if (str.length === 0) return null

  return str
}
