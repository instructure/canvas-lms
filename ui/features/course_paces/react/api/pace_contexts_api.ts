/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {APIPaceContextTypes} from '../types'
import doFetchApi from '@canvas/do-fetch-api-effect'

export const getPaceContexts = (
  courseId: string,
  contextType: APIPaceContextTypes,
  page: number,
  entriesPerRequest: number,
  searchTerm: string
) => {
  const apiParams: Record<string, string | number> = {
    type: contextType.toLocaleLowerCase(),
    page,
    per_page: entriesPerRequest,
  }
  if (searchTerm && searchTerm.length) {
    apiParams.search_term = searchTerm
  }
  return doFetchApi({
    path: `/api/v1/courses/${courseId}/pace_contexts`,
    params: apiParams,
  }).then(({json}) => json)
}

export const getDefaultPaceContext = (courseId: string) => {
  return doFetchApi({
    path: `/api/v1/courses/${courseId}/pace_contexts?type=course`,
  }).then(({json}) => json?.pace_contexts?.[0])
}
