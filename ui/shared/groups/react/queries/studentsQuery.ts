/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import type {QueryFunctionContext} from '@tanstack/react-query'
import doFetchApi from '@canvas/do-fetch-api-effect'

export type Student = {
  id: string
  name: string
}

export const studentsQuery = async ({
  signal,
  queryKey,
}: QueryFunctionContext<[string, {courseId: string; searchText: string}]>): Promise<
  Student[] | undefined
> => {
  const [, payload] = queryKey
  const fetchOpts = {signal}
  const path = `/api/v1/courses/${payload.courseId}/users`
  const params = {
    search_term: payload.searchText,
    enrollment_type: 'student',
    per_page: 100,
    sort: 'username',
  }

  const {json} = await doFetchApi<Student[]>({path, fetchOpts, params})

  return json
}
