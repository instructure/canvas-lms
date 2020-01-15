/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

export function isValid(return_to) {
  if (!return_to) {
    return false
  }
  if (/^\s*javascript:/i.test(return_to) || /^\s*data:/i.test(return_to)) {
    return false
  }
  const url = new URL(return_to, window.location.origin)
  if (url.origin != window.location.origin) {
    return false
  }
  return true
}
