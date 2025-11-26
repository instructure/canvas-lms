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
import {
  DEFAULT_STUDENTS_PER_PAGE,
  SortOrder,
  SortBy,
  GradebookSettings,
  DisplayFilter,
} from './utils/constants'
import {Student} from './types/rollup'

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
  user_ids?: number[]
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
      ...(selectedUserIds && selectedUserIds.length > 0 && {user_ids: selectedUserIds}),
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

/**
 * Load learning mastery gradebook settings
 * @param courseId - The ID of the course
 * @returns A promise that resolves to the API response
 */
export const loadLearningMasteryGradebookSettings = (
  courseId: string | number,
): Promise<AxiosResponse> => {
  return axios.get(`/api/v1/courses/${courseId}/learning_mastery_gradebook_settings`)
}

/**
 * Save learning mastery gradebook settings
 * @param courseId - The ID of the course
 * @param settings - The gradebook settings to save
 * @returns A promise that resolves to the API response
 */
export const saveLearningMasteryGradebookSettings = (
  courseId: string | number,
  settings: GradebookSettings,
): Promise<AxiosResponse> => {
  const body = {
    learning_mastery_gradebook_settings: {
      secondary_info_display: settings.secondaryInfoDisplay,
      show_student_avatars: settings.displayFilters.includes(DisplayFilter.SHOW_STUDENT_AVATARS),
      show_students_with_no_results: settings.displayFilters.includes(
        DisplayFilter.SHOW_STUDENTS_WITH_NO_RESULTS,
      ),
      show_outcomes_with_no_results: settings.displayFilters.includes(
        DisplayFilter.SHOW_OUTCOMES_WITH_NO_RESULTS,
      ),
      name_display_format: settings.nameDisplayFormat,
      students_per_page: settings.studentsPerPage,
      score_display_format: settings.scoreDisplayFormat,
    },
  }

  return axios.put(`/api/v1/courses/${courseId}/learning_mastery_gradebook_settings`, body)
}

/**
 * Parameters for course users API
 */
interface CourseUsersParams {
  enrollment_type?: string[]
  per_page?: number
  search_term?: string
}

/**
 * Load users enrolled in a course
 * @param courseId - The ID of the course
 * @returns A promise that resolves to the API response with Student array
 */
export const loadCourseUsers = (
  courseId: string | number,
  searchTerm?: string,
): Promise<AxiosResponse<Student[]>> => {
  const params: {params: CourseUsersParams} = {
    params: {
      enrollment_type: ['student', 'student_view'],
      per_page: 100,
      ...(searchTerm ? {search_term: searchTerm} : {}),
    },
  }

  return axios.get(`/api/v1/courses/${courseId}/users`, params)
}
