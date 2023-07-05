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
import axios from 'axios'
import {MockedProvider} from '@apollo/react-testing'
import {render, within} from '@testing-library/react'
import {DEFAULT_ENV, setupGraphqlMocks} from './fixtures'
import {BrowserRouter, Route, Routes} from 'react-router-dom'
import EnhancedIndividualGradebook from '../EnhancedIndividualGradebook'

jest.mock('axios') // mock axios for final grade override helper API call
const mockedAxios = axios as jest.Mocked<typeof axios>

describe('Enhanced Individual Gradebook', () => {
  beforeEach(() => {
    ;(window.ENV as any) = DEFAULT_ENV
    mockedAxios.get.mockResolvedValue({
      data: [],
    })
  })

  afterEach(() => {
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

    it('renders page with preselected options', () => {
      /**
       * Global Settings
       * preselected section dropdown value from local storage
       * preseleected grading period dropdown value from local storage
       * preselcted sort assignments value from local storage
       * checkboxes are shown with default values
       *
       * Content Selection
       * preselected student dropdwon from query param
       * preselected assignment dropdown from query param
       *
       * Grading
       * check for text `Grade for {studentName}`
       *
       * Student Information
       * check for Student Name in link text (data-testid)
       *
       * Assignment Information
       * check for Assignment Name in link text (data-testid)
       */
    })
  })

  describe('student dropdown handler tests', () => {
    it('should change student query param when student dropdown is changed to valid student', () => {})

    it('should remove student query param when no student is selected', () => {})

    it('should change assignment query param when student dropdown is changed to valid assingment', () => {})

    it('should remove assignment query param when no assignment is selected', () => {})
  })

  describe('global settings checkbox handler tests', () => {
    it('sets local storage when "View Ungraded as 0" checkbox is checked', () => {})

    it('makes api call when "View Ungraded as 0" checkbox is checked & save-view-ungraded-as-zero-to-server is true', () => {})

    it('sets local storage when "Hide Student Names" checkbox is checked', () => {})

    it('makes api call when "Show Concluded Enrollments" checkbox is checked', () => {})

    it('makes api call when "Show Notes in Student Info" checkbox is checked', () => {})

    it('makes api call when "Allow Final Grade Override" checkbox is checked', () => {})
  })
})
