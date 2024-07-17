/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {QueryFunctionContext} from '@tanstack/react-query'

type FetchSectionsOptions = {
  exclude: string[]
  searchTerm?: string
  courseId: number
}

export type ResponseSection = {
  id: string
  name: string
  avatar_url: string
  user_count: number
}

export async function fetchSections({
  queryKey,
}: QueryFunctionContext<[string, FetchSectionsOptions]>): Promise<ResponseSection[]> {
  const [, {exclude, searchTerm, courseId}] = queryKey
  const response = await axios.get(`/courses/${courseId}/sections/user_count`, {
    params: {
      exclude,
      search: searchTerm,
    },
  })

  return response.data.sections
}
