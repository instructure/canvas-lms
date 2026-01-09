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
import {GradebookSettings, DisplayFilter} from '@canvas/outcomes/react/utils/constants'
import {Student, Outcome} from '@canvas/outcomes/react/types/rollup'

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
      show_unpublished_assignments: settings.displayFilters.includes(
        DisplayFilter.SHOW_UNPUBLISHED_ASSIGNMENTS,
      ),
      name_display_format: settings.nameDisplayFormat,
      students_per_page: settings.studentsPerPage,
      score_display_format: settings.scoreDisplayFormat,
      outcome_arrangement: settings.outcomeArrangement,
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

/**
 * Save learning mastery gradebook outcome order
 * @param courseId - The ID of the course
 * @param outcomes - Array of outcomes in the desired order
 * @returns A promise that resolves to the API response
 */
export const saveOutcomeOrder = (
  courseId: string | number,
  outcomes: Outcome[],
): Promise<AxiosResponse> => {
  const outcomeOrder = outcomes.map((outcome, index) => ({
    outcome_id: Number(outcome.id),
    position: index,
  }))

  return axios.post(`/api/v1/courses/${courseId}/assign_outcome_order`, outcomeOrder)
}
