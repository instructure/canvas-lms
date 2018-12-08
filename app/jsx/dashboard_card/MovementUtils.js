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

import axios from 'axios'
// Updates the positions of a given group of contexts asynchronously
const updatePositions = (newPositions, userId, ajaxLib = axios) => {
  const request = {}
  request.dashboard_positions = {}
  newPositions.forEach((c, i) => {
    request.dashboard_positions[c.assetString] = i
  })
  return ajaxLib.put(`/api/v1/users/${userId}/dashboard_positions`, request)
}

export default {
  updatePositions
}
