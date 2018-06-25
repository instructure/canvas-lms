/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import axios from 'axios'

export function publishGrades(courseId, assignmentId) {
  const url = `/api/v1/courses/${courseId}/assignments/${assignmentId}/provisional_grades/publish`

  return axios.post(url)
}

export function unmuteAssignment(courseId, assignmentId) {
  const url = `/courses/${courseId}/assignments/${assignmentId}/mute?status=false`

  return axios.put(url)
}
