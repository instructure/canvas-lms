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
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {render, within, fireEvent} from '@testing-library/react'
import {setGradebookOptions, setupCanvasQueries} from './fixtures'
import {queryClient} from '@canvas/query'
import {BrowserRouter, Route, Routes} from 'react-router-dom'
import EnhancedIndividualGradebook from '../EnhancedIndividualGradebook'
import userSettings from '@canvas/user-settings'
import {GradebookSortOrder} from '../../../types/gradebook.d'
import * as ReactRouterDom from 'react-router-dom'
import {executeApiRequest} from '@canvas/do-fetch-api-effect/apiRequest'
import fakeENV from '@canvas/test-utils/fakeENV'

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

const CUSTOM_TIMEOUT_LIMIT = 1000

describe('Enhanced Individual Gradebook', () => {
  beforeEach(() => {
    const options = setGradebookOptions()
    fakeENV.setup({
      ...options,
      FEATURES: {
        instui_nav: true,
      },
    })
    mockedAxios.get.mockResolvedValue({
      data: [],
    })
    $.subscribe = jest.fn()

    setupCanvasQueries()
  })

  afterEach(() => {
    fakeENV.teardown()
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
              <MockedQueryProvider>
                <EnhancedIndividualGradebook />
              </MockedQueryProvider>
            }
          />
        </Routes>
      </BrowserRouter>,
    )
  }

  describe('render tests', () => {
    it('renders page with no preselected options', async () => {
      // Set up the test environment with empty data
      setupCanvasQueries()

      // Clear any existing query data to ensure empty state
      queryClient.setQueryData(['individual-gradebook-submissions', '1'], {
        pages: [
          {
            course: {
              submissionsConnection: {
                nodes: [],
                pageInfo: {
                  hasNextPage: false,
                  endCursor: null,
                },
              },
            },
          },
        ],
        pageParams: [''],
      })

      queryClient.setQueryData(['individual-gradebook-enrollments', '1'], {
        pages: [
          {
            course: {
              enrollmentsConnection: {
                nodes: [],
                pageInfo: {
                  hasNextPage: false,
                  endCursor: null,
                },
              },
              usersConnection: {
                nodes: [],
                pageInfo: {
                  hasNextPage: false,
                  endCursor: null,
                },
              },
            },
          },
        ],
        pageParams: [''],
      })

      queryClient.setQueryData(['individual-gradebook-assignments', '1'], {
        pages: [
          {
            course: {
              assignmentsConnection: {
                nodes: [],
                pageInfo: {
                  hasNextPage: false,
                  endCursor: null,
                },
              },
            },
          },
        ],
        pageParams: [''],
      })

      const {getByTestId, findByTestId} = renderEnhancedIndividualGradebook()
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

      // Use a longer timeout to ensure components have time to render
      await new Promise(resolve => setTimeout(resolve, CUSTOM_TIMEOUT_LIMIT))

      const contentSelectionStudent = getByTestId('content-selection-student')
      expect(within(contentSelectionStudent).getByText('No Student Selected')).toBeInTheDocument()
      const contentSelectionAssignment = getByTestId('content-selection-assignment')
      expect(
        within(contentSelectionAssignment).getByText('No Assignment Selected'),
      ).toBeInTheDocument()

      // Use findByTestId instead of getByTestId to allow for async rendering
      const gradingResults = await findByTestId('grading-results-empty')
      expect(
        within(gradingResults).getByText(
          'Select a student and an assignment to view and edit grades.',
        ),
      ).toBeInTheDocument()

      const studentInformation = getByTestId('student-information-empty')
      expect(
        within(studentInformation).getByText(
          'Select a student to view additional information here.',
        ),
      ).toBeInTheDocument()

      const assignmentInformation = getByTestId('assignment-information-empty')
      expect(
        within(assignmentInformation).getByText(
          'Select an assignment to view additional information here.',
        ),
      ).toBeInTheDocument()
    })

    it('renders page with preselected options', async () => {
      mockUserSettings()
      const options = setGradebookOptions({
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
      fakeENV.setup({
        ...options,
        FEATURES: {
          instui_nav: true,
        },
      })
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
        'https://www.testattachment.com/attachment',
      )
      expect(gradebookExportLink).toHaveTextContent('Download Scores Generated on')

      // content selection query params
      await new Promise(resolve => setTimeout(resolve, CUSTOM_TIMEOUT_LIMIT))
      const contentSelectionStudent = getByTestId('content-selection-student')
      expect(contentSelectionStudent).toBeInTheDocument()
      expect(within(contentSelectionStudent).getByText('Student 1')).toBeInTheDocument()

      const contentSelectionAssignment = getByTestId('content-selection-assignment')
      expect(contentSelectionAssignment).toBeInTheDocument()
      expect(
        within(contentSelectionAssignment).getByText('Missing Assignment 1'),
      ).toBeInTheDocument()

      // grading results
      await new Promise(resolve => setTimeout(resolve, 0))
      const gradingResults = getByTestId('grading-results')
      expect(gradingResults).toBeInTheDocument()
      expect(
        within(gradingResults).getByText('Grade for Student 1 - Missing Assignment 1'),
      ).toBeInTheDocument()

      // student information
      const studentInformationName = getByTestId('student-information-name')
      expect(studentInformationName).toBeInTheDocument()
      expect(within(studentInformationName).getByText('Student 1')).toBeInTheDocument()

      // assignment information
      const assignmentInformationName = getByTestId('assignment-information-name')
      expect(assignmentInformationName).toBeInTheDocument()
      expect(
        within(assignmentInformationName).getByText('Missing Assignment 1'),
      ).toBeInTheDocument()
    })
  })
})
