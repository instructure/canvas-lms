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
import { encodeQueryString } from '../shared/queryString'

// not using default because we will add more api calls in near future
// eslint-disable-next-line
export function getDiscussions ({ contextType, contextId, discussions }, { page }) {
  const params = [
    { per_page: 40 },
    { plain_messages: true },
    { exclude_assignment_descriptions: true },
    { exclude_context_module_locked_topics: true },
    { page: page || discussions.currentPage },
  ]

  if (contextType === 'course') {
    params.push({ 'include[]': 'sections_user_count' })
    params.push({ 'include[]': 'sections' })
  }

  const queryString = encodeQueryString(params)
  return axios.get(`/api/v1/${contextType}s/${contextId}/discussion_topics?${queryString}`)
}
