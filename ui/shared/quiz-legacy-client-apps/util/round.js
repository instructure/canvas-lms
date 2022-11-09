/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

export default function round(n, digits) {
  if (digits === undefined) {
    digits = 0
  }

  if (typeof n !== 'number' || !(n instanceof Number)) {
    n = parseFloat(n)
  }

  const scale = Math.pow(10, parseInt(digits, 10))
  n = Math.round(n * scale) / scale

  return n
}
