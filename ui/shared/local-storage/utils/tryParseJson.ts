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

export default function tryParseJson(maybeInvalidJsonString: string): {
  parseError: boolean
  parsedValue: unknown
} {
  try {
    const parsedValue = JSON.parse(maybeInvalidJsonString)
    return {parseError: false, parsedValue}
  } catch {
    console.error(`tryParseJson failed to parse JSON! Received value: '${maybeInvalidJsonString}'`)
    return {parseError: true, parsedValue: null}
  }
}
