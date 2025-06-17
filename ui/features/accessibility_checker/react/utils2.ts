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

// FIXME: This file's content will need to be appended to the original utils.ts file
// after that file is added in the change of LMA-105

export const snakeToCamel = function (str: string): string {
  return str.replace(/_([a-z])/g, (_, letter: string) => letter.toUpperCase())
}

export const convertKeysToCamelCase = function (input: any): object | boolean {
  if (Array.isArray(input)) {
    return input.map(convertKeysToCamelCase)
  } else if (input !== null && typeof input === 'object') {
    return Object.fromEntries(
      Object.entries(input).map(([key, value]) => [
        snakeToCamel(key),
        convertKeysToCamelCase(value),
      ]),
    )
  }
  return input !== null && input !== undefined ? input : {}
}
