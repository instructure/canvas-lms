/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import type {Course, CoursesResponse} from '../types/course'
import type {SortOrder} from '../react/components/SortableTableHeader'

const COURSES_PER_PAGE = 15
const TEACHER_LIMIT = 25

interface FetchCoursesParams {
  accountId: string
  sort: string
  order: SortOrder
}

export const fetchCourses = async (params: FetchCoursesParams): Promise<CoursesResponse> => {
  const {accountId, sort, order} = params

  const queryParams: Record<string, any> = {
    include: [
      'total_students',
      'active_teachers',
      'subaccount',
      'term',
      'accessibility_course_statistic',
    ],
    teacher_limit: TEACHER_LIMIT,
    per_page: COURSES_PER_PAGE,
    no_avatar_fallback: 1,
  }

  queryParams.sort = sort
  queryParams.order = order

  const response = await axios.get<Course[]>(`/api/v1/accounts/${accountId}/courses`, {
    params: queryParams,
  })

  return {
    courses: response.data,
  }
}
