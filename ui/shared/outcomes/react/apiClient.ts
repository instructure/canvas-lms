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

import axios from '@canvas/axios'
import {AxiosResponse} from 'axios'
import {DEFAULT_STUDENTS_PER_PAGE, SortOrder, SortBy} from './utils/constants'

export function createImport(contextRoot: string, file: File, learningOutcomeGroupId?: string) {
  const data = new FormData()
  const groupParam = learningOutcomeGroupId ? `group/${learningOutcomeGroupId}` : ''
  // xsslint safeString.identifier file
  data.append('attachment', file)
  const url = `/api/v1${contextRoot}/outcome_imports/${groupParam}?import_type=instructure_csv`
  return axios.post(url, data)
}

export function queryImportStatus(contextRoot: string, outcomeImportId: string) {
  return axios.get(`/api/v1${contextRoot}/outcome_imports/${outcomeImportId}`)
}

export function queryImportCreatedGroupIds(contextRoot: string, outcomeImportId: string) {
  return axios.get(`/api/v1${contextRoot}/outcome_imports/${outcomeImportId}/created_group_ids`)
}

/**
 * Parameters for outcome rollups API
 */
interface RollupParams {
  rating_percents: boolean
  per_page: number
  exclude: string[]
  include: string[]
  sort_by: string
  sort_order: string
  page: number
  add_defaults?: boolean
  sort_outcome_id?: string
  sort_alignment_id?: string
  user_ids?: number[]
  outcome_ids?: string[]
}

/**
 * Load outcome rollups for a course
 * @param courseId - The ID of the course
 * @param gradebookFilters - Filters to exclude from the results
 * @param needDefaults - Whether to include default outcomes
 * @param page - The page number to retrieve
 * @param perPage - The number of results per page
 * @param sortOrder - The order to sort the results by
 * @param sortBy - The field to sort the results by
 * @param sortOutcomeId - The ID of the outcome to sort by (when sortBy is 'outcome')
 * @param selectedUserIds - Array of user IDs to filter by (optional)
 * @param selectedOutcomeIds - Array of outcome IDs to filter by (optional)
 * @param sortAlignmentId - The ID of the alignment to sort by (when sortBy is 'contributing_score')
 * @returns A promise that resolves to the API response
 */
export const loadRollups = (
  courseId: string | number,
  gradebookFilters: string[],
  needDefaults: boolean = false,
  page: number = 1,
  perPage: number = DEFAULT_STUDENTS_PER_PAGE,
  sortOrder: SortOrder = SortOrder.ASC,
  sortBy: string = SortBy.SortableName,
  sortOutcomeId?: string,
  selectedUserIds?: number[],
  selectedOutcomeIds?: string[],
  sortAlignmentId?: string,
): Promise<AxiosResponse> => {
  const params: {params: RollupParams} = {
    params: {
      rating_percents: true,
      per_page: perPage,
      exclude: gradebookFilters,
      include: ['outcomes', 'users', 'outcome_paths', 'alignments'],
      sort_by: sortBy,
      sort_order: sortOrder,
      page,
      ...(needDefaults && {add_defaults: true}),
      ...(sortOutcomeId && {sort_outcome_id: sortOutcomeId}),
      ...(sortAlignmentId && {sort_alignment_id: sortAlignmentId}),
      ...(selectedUserIds && selectedUserIds.length > 0 && {user_ids: selectedUserIds}),
      ...(selectedOutcomeIds && selectedOutcomeIds.length > 0 && {outcome_ids: selectedOutcomeIds}),
    },
  }

  return axios.get(`/api/v1/courses/${courseId}/outcome_rollups`, params)
}
