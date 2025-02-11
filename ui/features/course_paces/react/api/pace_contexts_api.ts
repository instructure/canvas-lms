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

import type {BulkStudentsApiResponse, PaceContextsApiResponse} from '../types'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {CommonFilterParams, FetchContextsActionParams} from '../actions/pace_contexts'

export interface FetchContextsAPIParams extends FetchContextsActionParams {
  courseId: string
  entriesPerRequest?: number
}

export interface FetchBulkStudentViewsAPIParams extends CommonFilterParams {
  courseId: string
  filterSection?: string
  filterPaceStatus?: string
  entriesPerRequest?: number
}

export const getPaceContexts = ({
  courseId,
  contextType,
  page,
  entriesPerRequest,
  searchTerm,
  sortBy,
  orderType = 'asc',
  contextIds,
}: FetchContextsAPIParams): PaceContextsApiResponse => {
  const apiParams: Record<string, string | number> = {
    type: contextType.toLocaleLowerCase(),
  }
  if (page && entriesPerRequest) {
    apiParams.page = page
    apiParams.per_page = entriesPerRequest
  }
  if (searchTerm && searchTerm.length) {
    apiParams.search_term = searchTerm
  }
  if (sortBy) {
    apiParams.sort = sortBy
    apiParams.order = orderType
  }
  if (contextIds) {
    apiParams.contexts = JSON.stringify(contextIds)
  }
  // @ts-expect-error
  return doFetchApi({
    path: `/api/v1/courses/${courseId}/pace_contexts`,
    params: apiParams,
  }).then(({json}) => json)
}

export const getDefaultPaceContext = (courseId: string) => {
  return doFetchApi({
    path: `/api/v1/courses/${courseId}/pace_contexts?type=course`,
    // @ts-expect-error
  }).then(({json}) => json?.pace_contexts?.[0])
}

export const getStudentBulkPaceEditView = ({
  courseId,
  page,
  entriesPerRequest,
  searchTerm,
  sortBy,
  orderType = 'asc',
  filterPaceStatus,
  filterSection
}: FetchBulkStudentViewsAPIParams): BulkStudentsApiResponse => {
  const apiParams: Record<string, string | number> = {}
  if (page && entriesPerRequest) {
    apiParams.page = page
    apiParams.per_page = entriesPerRequest
  }
  if (searchTerm && searchTerm.length) {
    apiParams.search_term = searchTerm
  }
  if (sortBy) {
    apiParams.sort = sortBy
    apiParams.order = orderType
  }

  if(filterPaceStatus !== 'all') {
    // @ts-expect-error
    apiParams.filter_pace_status = filterPaceStatus
  }

  if(filterSection !== 'all') {
    // @ts-expect-error
    apiParams.filter_section = filterSection
  }

  // @ts-expect-error
  return doFetchApi({
    path: `/api/v1/courses/${courseId}/bulk_student_enrollments/student_bulk_pace_edit_view`,
    params: apiParams,
  }).then(({json}) => json)
}