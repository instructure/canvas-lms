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

const COURSES_TO_FETCH_PER_PAGE = 15

export default createStore({
  getUrl() {
    return `/api/v1/accounts/${this.context.accountId}/courses`
  },

  normalizeParams(originalParams) {
    const params = {
      ...originalParams,
      include: ['total_students', 'teachers', 'subaccount', 'term'],
      per_page: COURSES_TO_FETCH_PER_PAGE
    }
    const propsToCleanUp = [
      'enrollment_term_id',
      'search_term',
      'sort',
      'order',
      'search_by',
      'page',
      'blueprint'
    ]
    propsToCleanUp.forEach(p => {
      if (!originalParams[p]) delete params[p]
    })
    return params
  }
})
