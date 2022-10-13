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

import useFetchApi from '@canvas/use-fetch-api-hook'

export default function useContentShareUserSearchApi(opts) {
  const {courseId, ...fetchApiOpts} = opts
  if (!courseId) throw new Error('courseId parameter is required for useContentShareUserSearchApi')

  // need at least 3 characters for the search_term.
  const searchTerm = fetchApiOpts.params.search_term || ''
  let forceResult
  if (searchTerm.length < 3) forceResult = null

  useFetchApi({
    path: `/api/v1/courses/${courseId}/content_share_users`,
    forceResult,
    ...fetchApiOpts,
  })
}
