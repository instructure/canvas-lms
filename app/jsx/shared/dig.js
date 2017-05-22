/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

// dig multiple layers deep inside an object with a single string path
// inspired by ruby's dig method
// example: dig(assignment, 'teacher.name') would return the value of assignment.teacher.name
// useful for deep dynamic extraction of data from objects
export default function dig (obj, path) {
  try {
    return path.split('.').reduce((subObj, key) => subObj[key], obj)
  } catch (e) {
    return undefined
  }
}
