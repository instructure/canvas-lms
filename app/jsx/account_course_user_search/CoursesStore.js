/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import createStore from './createStore'

const CoursesStore = createStore({
  getUrl () {
    return `/api/v1/accounts/${this.context.accountId}/courses`;
  },

  normalizeParams (params) {
    const payload = {}
    if (params.enrollment_term_id) payload.enrollment_term_id = params.enrollment_term_id
    if (params.search_term) payload.search_term = params.search_term
    if (params.with_students) payload.enrollment_type = ['student']
    if (params.sort) payload.sort = params.sort
    if (params.order) payload.order = params.order
    if (params.search_by) payload.search_by = params.search_by
    payload.include = ['total_students', 'teachers', 'subaccount', 'term']

    return payload
  }
})

export default CoursesStore
