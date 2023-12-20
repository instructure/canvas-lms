/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React from 'react'
import $ from 'jquery'
import axios from 'axios'
import {MockedProvider} from '@apollo/react-testing'
import {render, within, fireEvent} from '@testing-library/react'
import {setGradebookOptions, setupGraphqlMocks} from './fixtures'
import {BrowserRouter, Route, Routes} from 'react-router-dom'
import EnhancedIndividualGradebook from '../EnhancedIndividualGradebook'
import userSettings from '@canvas/user-settings'
import {GradebookSortOrder} from '../../../types/gradebook.d'
import * as ReactRouterDom from 'react-router-dom'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {executeApiRequest} from '@canvas/do-fetch-api-effect/apiRequest'

jest.mock('axios') // mock axios for final grade override helper API call
jest.mock('@canvas/do-fetch-api-effect', () => jest.fn()) // mock doFetchApi for final grade override helper API call
jest.mock('@canvas/do-fetch-api-effect/apiRequest', () => ({
  executeApiRequest: jest.fn(),
}))
const mockedAxios = axios as jest.Mocked<typeof axios>
const mockedExecuteApiRequest = executeApiRequest as jest.MockedFunction<typeof executeApiRequest>
const mockUserSettings = (mockGet = true) => {
  if (mockGet) {
    jest.spyOn(userSettings, 'contextGet').mockImplementation(input => {
      switch (input) {
        case 'sort_grade_columns_by':
          return {sortType: GradebookSortOrder.DueDate}
        case 'gradebook_current_grading_period':
          return '1'
        case 'hide_student_names':
          return true
      }
    })
  }
  const mockedContextSet = jest.spyOn(userSettings, 'contextSet')
  return {mockedContextSet}
}

const mockSearchParams = (defaultSearchParams = {}) => {
  const setSearchParamsMock = jest.fn()
  const searchParamsMock = new URLSearchParams(defaultSearchParams)
  jest
    .spyOn(ReactRouterDom, 'useSearchParams')
    .mockReturnValue([searchParamsMock, setSearchParamsMock])
  return {searchParamsMock, setSearchParamsMock}
}

describe('Enhanced Individual Gradebook', () => {
  beforeEach(() => {
    ;(window.ENV as any) = setGradebookOptions()
    window.ENV.FEATURES = {instui_nav: true}
    mockedAxios.get.mockResolvedValue({
      data: [],
    })
    $.subscribe = jest.fn()
  })
  afterEach(() => {
    jest.spyOn(ReactRouterDom, 'useSearchParams').mockClear()
    jest.resetAllMocks()
  })

  const renderEnhancedIndividualGradebook = (mockOverrides = []) => {
    return render(
      <BrowserRouter basename="">
        <Routes>
          <Route
            path="/"
            element={
              <MockedProvider mocks={setupGraphqlMocks(mockOverrides)} addTypename={false}>
                <EnhancedIndividualGradebook />
              </MockedProvider>
            }
          />
        </Routes>
      </BrowserRouter>
    )
  }

  describe('render tests', () => {
    it('renders page with no preselected options', async () => {
      const {getByTestId} = renderEnhancedIndividualGradebook()
      const sectionSelect = getByTestId('section-select')
      expect(sectionSelect).toBeInTheDocument()
      expect(sectionSelect).toHaveTextContent('All Sections')

      const sortSelect = getByTestId('sort-select')
      expect(sortSelect).toBeInTheDocument()
      expect(sortSelect).toHaveTextContent('Alphabetically')

      const includeUngradedCheckbox = getByTestId('include-ungraded-assignments-checkbox')
      expect(includeUngradedCheckbox).toBeInTheDocument()
      expect(includeUngradedCheckbox).not.toBeChecked()

      const hideStudentNamesCheckbox = getByTestId('hide-student-names-checkbox')
      expect(hideStudentNamesCheckbox).toBeInTheDocument()
      expect(hideStudentNamesCheckbox).not.toBeChecked()

      const showConcludedEnrollmentsCheckbox = getByTestId('show-concluded-enrollments-checkbox')
      expect(showConcludedEnrollmentsCheckbox).toBeInTheDocument()
      expect(showConcludedEnrollmentsCheckbox).not.toBeChecked()

      const showNotesColumnCheckbox = getByTestId('show-notes-column-checkbox')
      expect(showNotesColumnCheckbox).toBeInTheDocument()
      expect(showNotesColumnCheckbox).not.toBeChecked()

      const uploadButton = getByTestId('upload-button')
      expect(uploadButton).toBeInTheDocument()

      const gradebookExportButton = getByTestId('gradebook-export-button')
      expect(gradebookExportButton).toBeInTheDocument()

      const gradebookHistoryLink = getByTestId('gradebook-history-link')
      expect(gradebookHistoryLink).toBeInTheDocument()

      await new Promise(resolve => setTimeout(resolve, 0))

      const contentSelectionStudent = getByTestId('content-selection-student')
      expect(within(contentSelectionStudent).getByText('No Student Selected')).toBeInTheDocument()
      const contentSelectionAssignment = getByTestId('content-selection-assignment')
      expect(
        within(contentSelectionAssignment).getByText('No Assignment Selected')
      ).toBeInTheDocument()

      const gradingResults = getByTestId('grading-results-empty')
      expect(
        within(gradingResults).getByText(
          'Select a student and an assignment to view and edit grades.'
        )
      ).toBeInTheDocument()

      const studentInformation = getByTestId('student-information-empty')
      expect(
        within(studentInformation).getByText(
          'Select a student to view additional information here.'
        )
      ).toBeInTheDocument()

      const assignmentInformation = getByTestId('assignment-information-empty')
      expect(
        within(assignmentInformation).getByText(
          'Select an assignment to view additional information here.'
        )
      ).toBeInTheDocument()
    })

    it('renders page with preselected options', async () => {
      mockUserSettings()
      ;(window.ENV as any) = setGradebookOptions({
        grading_period_set: {
          grading_periods: [
            {
              id: '1',
              title: 'Grading Period 1',
            },
          ],
        },
        course_settings: {
          allow_final_grade_override: true,
        },
        save_view_ungraded_as_zero_to_server: true,
        settings: {
          view_ungraded_as_zero: 'true',
          show_concluded_enrollments: 'true',
        },
        teacher_notes: {
          hidden: false,
        },
        show_total_grade_as_points: true,
        grades_are_weighted: false,
        final_grade_override_enabled: true,
        gradebook_csv_progress: {
          progress: {
            updated_at: '2023-06-07T12:34:14-06:00',
          },
        },
        attachment_url: 'https://www.testattachment.com/attachment',
      })
      window.ENV.FEATURES = {instui_nav: true}
      mockSearchParams({student: '5', assignment: '1'})
      // dropdowns
      const {getByTestId} = renderEnhancedIndividualGradebook()
      const sortSelect = getByTestId('sort-select')
      expect(sortSelect).toBeInTheDocument()
      expect(sortSelect).toHaveTextContent('By Due Date')

      const gradingPeriodSelect = getByTestId('grading-period-select')
      expect(gradingPeriodSelect).toBeInTheDocument()
      expect(gradingPeriodSelect).toHaveTextContent('Grading Period 1')

      // checkboxes
      const includeUngradedCheckbox = getByTestId('include-ungraded-assignments-checkbox')
      expect(includeUngradedCheckbox).toBeInTheDocument()
      expect(includeUngradedCheckbox).toBeChecked()

      const hideStudentNamesCheckbox = getByTestId('hide-student-names-checkbox')
      expect(hideStudentNamesCheckbox).toBeInTheDocument()
      expect(hideStudentNamesCheckbox).toBeChecked()

      const showConcludedEnrollmentsCheckbox = getByTestId('show-concluded-enrollments-checkbox')
      expect(showConcludedEnrollmentsCheckbox).toBeInTheDocument()
      expect(showConcludedEnrollmentsCheckbox).toBeChecked()

      const showNotesColumnCheckbox = getByTestId('show-notes-column-checkbox')
      expect(showNotesColumnCheckbox).toBeInTheDocument()
      expect(showNotesColumnCheckbox).toBeChecked()

      const allowFinalGradeOverrideCheckbox = getByTestId('allow-final-grade-override-checkbox')
      expect(allowFinalGradeOverrideCheckbox).toBeInTheDocument()
      expect(allowFinalGradeOverrideCheckbox).toBeChecked()

      const showTotalGradeAsPointsCheckbox = getByTestId('show-total-grade-as-points-checkbox')
      expect(showTotalGradeAsPointsCheckbox).toBeInTheDocument()
      expect(showTotalGradeAsPointsCheckbox).toBeChecked()

      const gradebookExportLink = getByTestId('gradebook-export-link')
      expect(gradebookExportLink).toBeInTheDocument()
      expect(gradebookExportLink).toHaveAttribute(
        'href',
        'https://www.testattachment.com/attachment'
      )
      expect(gradebookExportLink).toHaveTextContent('Download Scores Generated on')

      // content selection query params
      await new Promise(resolve => setTimeout(resolve, 0))
      const contentSelectionStudent = getByTestId('content-selection-student')
      expect(contentSelectionStudent).toBeInTheDocument()
      expect(within(contentSelectionStudent).getByText('Student 1')).toBeInTheDocument()

      const contentSelectionAssignment = getByTestId('content-selection-assignment')
      expect(contentSelectionAssignment).toBeInTheDocument()
      expect(
        within(contentSelectionAssignment).getByText('Missing Assignment 1')
      ).toBeInTheDocument()

      // grading results
      await new Promise(resolve => setTimeout(resolve, 0))
      const gradingResults = getByTestId('grading-results')
      expect(gradingResults).toBeInTheDocument()
      expect(
        within(gradingResults).getByText('Grade for Student 1 - Missing Assignment 1')
      ).toBeInTheDocument()

      // student information
      const studentInformationName = getByTestId('student-information-name')
      expect(studentInformationName).toBeInTheDocument()
      expect(within(studentInformationName).getByText('Student 1')).toBeInTheDocument()

      // assignment information
      const assignmentInformationName = getByTestId('assignment-information-name')
      expect(assignmentInformationName).toBeInTheDocument()
      expect(
        within(assignmentInformationName).getByText('Missing Assignment 1')
      ).toBeInTheDocument()
    })

    it('renders a dropped message if the assignment is being dropped from grade calculation for the current student', async () => {
      mockUserSettings()
      const {getByTestId} = renderEnhancedIndividualGradebook()
      await new Promise(resolve => setTimeout(resolve, 0))
      fireEvent.change(getByTestId('content-selection-assignment-select'), {target: {value: '1'}})
      fireEvent.change(getByTestId('content-selection-student-select'), {target: {value: '5'}})
      await new Promise(resolve => setTimeout(resolve, 0))

      const gradingResults = getByTestId('grading-results')
      expect(
        within(gradingResults).getByText('Grade for Student 1 - Missing Assignment 1')
      ).toBeInTheDocument()
      expect(
        within(gradingResults).queryByText('This grade is currently dropped for this student.')
      ).not.toBeInTheDocument()

      fireEvent.change(getByTestId('content-selection-assignment-select'), {target: {value: '2'}})
      fireEvent.change(getByTestId('content-selection-student-select'), {target: {value: '5'}})
      await new Promise(resolve => setTimeout(resolve, 0))

      expect(
        within(gradingResults).getByText('Grade for Student 1 - Missing Assignment 2')
      ).toBeInTheDocument()
      expect(
        within(gradingResults).getByText('This grade is currently dropped for this student.')
      ).toBeInTheDocument()
    })

    it('does not render another flash message when switching students after setting default grades for the assignment', async () => {
      mockUserSettings()
      const {getByTestId, getByRole} = renderEnhancedIndividualGradebook()
      await new Promise(resolve => setTimeout(resolve, 0))
      mockedExecuteApiRequest.mockResolvedValue({
        data: [],
        status: 201,
      })
      fireEvent.change(getByTestId('content-selection-assignment-select'), {target: {value: '1'}})
      fireEvent.click(getByTestId('default-grade-button'))
      fireEvent.change(getByTestId('default-grade-input'), {target: {value: '10'}})
      fireEvent.click(getByTestId('default-grade-submit-button'))
      await new Promise(resolve => setTimeout(resolve, 0))
      fireEvent.change(getByTestId('content-selection-student-select'), {target: {value: '5'}})
      const parentElement = getByRole('alert')
      const childElements = parentElement?.children
      expect(childElements?.length).toBe(1)
    })
  })

  describe('student dropdown handler tests', () => {
    it('should change student query param when student dropdown is changed to valid student', async () => {
      const {searchParamsMock, setSearchParamsMock} = mockSearchParams()
      const {getByTestId} = renderEnhancedIndividualGradebook()
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(searchParamsMock.get('student')).toBe(null)
      await new Promise(resolve => setTimeout(resolve, 0))
      const contentSelectionStudent = getByTestId('content-selection-student-select')
      expect(contentSelectionStudent).toBeInTheDocument()
      fireEvent.change(contentSelectionStudent, {target: {value: '5'}})
      expect(searchParamsMock.get('student')).toBe('5')
      expect(setSearchParamsMock).toHaveBeenCalledWith(searchParamsMock)
    })
    it('should remove student query param when no student is selected', async () => {
      const {searchParamsMock, setSearchParamsMock} = mockSearchParams({student: '5'})
      await new Promise(resolve => setTimeout(resolve, 0))
      const {getByTestId} = renderEnhancedIndividualGradebook()
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(searchParamsMock.get('student')).toBe('5')
      const contentSelectionStudent = getByTestId('content-selection-student-select')
      fireEvent.change(contentSelectionStudent, {target: {value: '-1'}})
      expect(searchParamsMock.get('student')).toBe(null)
      expect(setSearchParamsMock).toHaveBeenCalledWith(searchParamsMock)
    })
    it('should change assignment query param when assignment dropdown is changed to valid assingment', async () => {
      const {searchParamsMock, setSearchParamsMock} = mockSearchParams()
      const {getByTestId} = renderEnhancedIndividualGradebook()
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(searchParamsMock.get('assignment')).toBe(null)
      await new Promise(resolve => setTimeout(resolve, 0))
      const contentSelectionAssignment = getByTestId('content-selection-assignment-select')
      expect(contentSelectionAssignment).toBeInTheDocument()
      fireEvent.change(contentSelectionAssignment, {target: {value: '1'}})
      expect(searchParamsMock.get('assignment')).toBe('1')
      expect(setSearchParamsMock).toHaveBeenCalledWith(searchParamsMock)
    })
    it('should remove assignment query param when no assignment is selected', async () => {
      const {searchParamsMock, setSearchParamsMock} = mockSearchParams({assignment: '1'})
      const {getByTestId} = renderEnhancedIndividualGradebook()
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(searchParamsMock.get('assignment')).toBe('1')
      await new Promise(resolve => setTimeout(resolve, 0))
      const contentSelectionAssignment = getByTestId('content-selection-assignment-select')
      expect(contentSelectionAssignment).toBeInTheDocument()
      fireEvent.change(contentSelectionAssignment, {target: {value: '-1'}})
      expect(searchParamsMock.get('assignment')).toBe(null)
      expect(setSearchParamsMock).toHaveBeenCalledWith(searchParamsMock)
    })
  })

  describe('global settings checkbox handler tests', () => {
    it('sets local storage when "View Ungraded as 0" checkbox is checked', async () => {
      const {mockedContextSet} = mockUserSettings(false)
      const {getByTestId} = renderEnhancedIndividualGradebook()
      await new Promise(resolve => setTimeout(resolve, 0))
      const viewUngradedAsZeroCheckbox = getByTestId('include-ungraded-assignments-checkbox')
      expect(viewUngradedAsZeroCheckbox).not.toBeChecked()
      expect(viewUngradedAsZeroCheckbox).toBeInTheDocument()
      fireEvent.click(viewUngradedAsZeroCheckbox)
      expect(mockedContextSet).toHaveBeenCalledWith('include_ungraded_assignments', true)
      expect(viewUngradedAsZeroCheckbox).toBeChecked()
    })

    it('makes api call when "View Ungraded as 0" checkbox is checked & save-view-ungraded-as-zero-to-server is true', async () => {
      ;(window.ENV as any) = setGradebookOptions({save_view_ungraded_as_zero_to_server: true})
      window.ENV.FEATURES = {instui_nav: true}
      mockUserSettings(false)
      const {getByTestId} = renderEnhancedIndividualGradebook()
      await new Promise(resolve => setTimeout(resolve, 0))
      const viewUngradedAsZeroCheckbox = getByTestId('include-ungraded-assignments-checkbox')
      expect(viewUngradedAsZeroCheckbox).not.toBeChecked()
      expect(viewUngradedAsZeroCheckbox).toBeInTheDocument()
      fireEvent.click(viewUngradedAsZeroCheckbox)
      expect(doFetchApi).toHaveBeenCalledWith({
        body: {
          gradebook_settings: {
            view_ungraded_as_zero: 'true',
          },
        },
        method: 'PUT',
        path: '/api/v1/courses/1/gradebook_settings',
      })
      expect(viewUngradedAsZeroCheckbox).toBeChecked()
    })

    it('sets local storage when "Hide Student Names" checkbox is checked', async () => {
      const {mockedContextSet} = mockUserSettings(false)
      const {getByTestId} = renderEnhancedIndividualGradebook()
      await new Promise(resolve => setTimeout(resolve, 0))
      const hideStudentNamesCheckbox = getByTestId('hide-student-names-checkbox')
      expect(hideStudentNamesCheckbox).not.toBeChecked()
      expect(hideStudentNamesCheckbox).toBeInTheDocument()
      fireEvent.click(hideStudentNamesCheckbox)
      expect(mockedContextSet).toHaveBeenCalledWith('hide_student_names', true)
      expect(hideStudentNamesCheckbox).toBeChecked()
    })

    it('makes api call when "Show Concluded Enrollments" checkbox is checked', async () => {
      ;(window.ENV as any) = setGradebookOptions({
        settings_update_url: 'http://canvas.docker/api/v1/courses/2/gradebook_settings',
      })
      window.ENV.FEATURES = {instui_nav: true}
      const {getByTestId} = renderEnhancedIndividualGradebook()
      await new Promise(resolve => setTimeout(resolve, 0))
      const showConcludedEnrollmentsCheckbox = getByTestId('show-concluded-enrollments-checkbox')
      expect(showConcludedEnrollmentsCheckbox).not.toBeChecked()
      expect(showConcludedEnrollmentsCheckbox).toBeInTheDocument()
      fireEvent.click(showConcludedEnrollmentsCheckbox)
      expect(doFetchApi).toHaveBeenCalledWith({
        body: {
          gradebook_settings: {
            show_concluded_enrollments: 'true',
          },
        },
        method: 'PUT',
        path: 'http://canvas.docker/api/v1/courses/2/gradebook_settings',
      })
      expect(showConcludedEnrollmentsCheckbox).toBeChecked()
    })

    it('makes api call when "Show Notes in Student Info" checkbox is checked', async () => {
      ;(window.ENV as any) = setGradebookOptions({
        custom_column_url: 'http://canvas.docker/api/v1/courses/2/custom_gradebook_columns/:id',
        custom_columns_url: 'http://canvas.docker/api/v1/courses/2/custom_gradebook_columns',
        reorder_custom_columns_url:
          'http://canvas.docker/api/v1/courses/2/custom_gradebook_columns/reorder',
        teacher_notes: {
          hidden: true,
          id: '1',
          position: 1,
          read_only: false,
          teacher_notes: true,
          title: 'Notes',
        },
      })
      window.ENV.FEATURES = {instui_nav: true}
      mockedExecuteApiRequest.mockResolvedValue({
        data: [
          {
            hidden: true,
            id: '1',
            position: 1,
            read_only: false,
            teacher_notes: true,
            title: 'Notes',
          },
        ],
        status: 200,
      })
      const {getByTestId} = renderEnhancedIndividualGradebook()
      await new Promise(resolve => setTimeout(resolve, 0))
      const showNotesInStudentInfoCheckbox = getByTestId('show-notes-column-checkbox')
      expect(showNotesInStudentInfoCheckbox).not.toBeChecked()
      expect(showNotesInStudentInfoCheckbox).toBeInTheDocument()
      fireEvent.click(showNotesInStudentInfoCheckbox)
      expect(executeApiRequest).toHaveBeenCalledWith({
        method: 'GET',
        path: 'http://canvas.docker/api/v1/courses/2/custom_gradebook_columns',
      })
      expect(executeApiRequest).toHaveBeenCalledWith({
        body: {
          column: {
            hidden: false,
          },
        },
        method: 'PUT',
        path: 'http://canvas.docker/api/v1/courses/2/custom_gradebook_columns/1',
      })
      expect(executeApiRequest).toHaveBeenCalledWith({
        body: {
          order: [1],
        },
        method: 'POST',
        path: 'http://canvas.docker/api/v1/courses/2/custom_gradebook_columns/reorder',
      })
    })

    it('makes api call when "Allow Final Grade Override" checkbox is checked', async () => {
      ;(window.ENV as any) = setGradebookOptions({
        final_grade_override_enabled: true,
      })
      window.ENV.FEATURES = {instui_nav: true}
      const {getByTestId} = renderEnhancedIndividualGradebook()
      await new Promise(resolve => setTimeout(resolve, 0))
      const allowFinalGradeOverrideCheckbox = getByTestId('allow-final-grade-override-checkbox')
      expect(allowFinalGradeOverrideCheckbox).not.toBeChecked()
      expect(allowFinalGradeOverrideCheckbox).toBeInTheDocument()
      fireEvent.click(allowFinalGradeOverrideCheckbox)
      expect(mockedExecuteApiRequest).toHaveBeenCalledWith({
        body: {
          allow_final_grade_override: true,
        },
        method: 'PUT',
        path: '/api/v1/courses/1/settings',
      })
      expect(allowFinalGradeOverrideCheckbox).toBeChecked()
    })
  })
})
