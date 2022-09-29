/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import axios from '@canvas/axios'

const CyoeClient = {
  call({apiUrl, jwt}, path) {
    return axios({
      url: apiUrl + path,
      dataType: 'json',
      headers: {
        Authorization: 'Bearer ' + jwt,
      },
    }).then(res => res.data)
  },

  loadInitialData(state) {
    const path = `/students_per_range?trigger_assignment=${state.assignment.id}`
    return CyoeClient.call(state, path)
  },

  loadStudent(state, studentId) {
    const path = `/student_details?trigger_assignment=${state.assignment.id}&student_id=${studentId}`
    return CyoeClient.call(state, path)
  },
}

export default CyoeClient
