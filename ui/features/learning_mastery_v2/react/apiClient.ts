/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

/**
 * Parameters for outcome rollups API
 */
interface RollupParams {
  rating_percents: boolean
  per_page: number
  exclude: string[]
  include: string[]
  sort_by: string
  page: number
  add_defaults?: boolean
}

/**
 * Load outcome rollups for a course
 * @param courseId - The ID of the course
 * @param gradebookFilters - Filters to exclude from the results
 * @param needDefaults - Whether to include default outcomes
 * @param page - The page number to retrieve
 * @returns A promise that resolves to the API response
 */
export const loadRollups = (
  courseId: string | number,
  gradebookFilters: string[],
  needDefaults: boolean = false,
  page: number = 1,
): Promise<AxiosResponse> => {
  const params: {params: RollupParams} = {
    params: {
      rating_percents: true,
      per_page: 20,
      exclude: gradebookFilters,
      include: ['outcomes', 'users', 'outcome_paths', 'alignments'],
      sort_by: 'student',
      page,
      ...(needDefaults && {add_defaults: true}),
    },
  }

  return axios.get(`/api/v1/courses/${courseId}/outcome_rollups`, params)
}

/**
 * Parameters for CSV export
 */
interface ExportCSVParams {
  exclude: string[]
}

/**
 * Export outcome rollups as CSV
 * @param courseId - The ID of the course
 * @param gradebookFilters - Filters to exclude from the results
 * @returns A promise that resolves to the API response
 */
export const exportCSV = (
  courseId: string | number,
  gradebookFilters: string[],
): Promise<AxiosResponse> => {
  const params: {params: ExportCSVParams} = {
    params: {
      exclude: gradebookFilters,
    },
  }

  return axios.get(`/courses/${courseId}/outcome_rollups.csv`, params)
}
