/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import makePromisePool from '@canvas/make-promise-pool'

const MAX_CONCURRENT_REQS = 5

export function deletePages(contextName, contextId, pageUrls) {
  return makePromisePool(
    pageUrls,
    pageUrl => {
      const url = `/api/v1/${contextName}/${contextId}/pages/${pageUrl}`
      return axios.delete(url)
    },
    {
      poolSize: MAX_CONCURRENT_REQS,
    }
  )
}
