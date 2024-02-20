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

import React from 'react'
import {MockedProvider} from '@apollo/react-testing'
import {QueryProvider, queryClient} from '@canvas/query'
import userSettings from '@canvas/user-settings'
import {fireEvent, render, within} from '@testing-library/react'
import axios from 'axios'
import $ from 'jquery'
import * as ReactRouterDom from 'react-router-dom'
import {BrowserRouter, Route, Routes} from 'react-router-dom'
import {GradebookSortOrder} from '../../../types/gradebook.d'
import LearningMasteryTabsView from '../LearningMasteryTabsView'
import {OUTCOME_ROLLUP_QUERY_RESPONSE, setGradebookOptions, setupGraphqlMocks} from './fixtures'

jest.mock('axios') // mock axios for final grade override helper API call
jest.mock('@canvas/do-fetch-api-effect', () => jest.fn()) // mock doFetchApi for final grade override helper API call
jest.mock('@canvas/do-fetch-api-effect/apiRequest', () => ({
  executeApiRequest: jest.fn(),
}))

const mockedAxios = axios as jest.Mocked<typeof axios>
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

describe('Enhanced Individual Wrapper Gradebook', () => {
  beforeEach(() => {
    ;(window.ENV as any) = setGradebookOptions({outcome_gradebook_enabled: true})
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

  const renderLearningMasteryGradebookWrapper = (mockOverrides = []) => {
    return render(
      <QueryProvider>
        <BrowserRouter basename="">
          <Routes>
            <Route
              path="/"
              element={
                <MockedProvider mocks={setupGraphqlMocks(mockOverrides)} addTypename={false}>
                  <LearningMasteryTabsView />
                </MockedProvider>
              }
            />
          </Routes>
        </BrowserRouter>
      </QueryProvider>
    )
  }

  describe('with presets on learning mastery and rollup', () => {
    it('renders the outcome calculations correctly', async () => {
      queryClient.setQueryData(['fetch-outcome-result-1'], OUTCOME_ROLLUP_QUERY_RESPONSE)
      mockUserSettings()
      ;(window.ENV as any) = setGradebookOptions({
        gradebook_csv_progress: {
          progress: {
            updated_at: '2023-06-07T12:34:14-06:00',
          },
        },
        attachment_url: 'https://www.testattachment.com/attachment',
      })
      window.ENV.FEATURES = {instui_nav: true}
      mockSearchParams({student: '5', outcome: '1'})

      const {getByTestId, getByText, queryByTestId} = renderLearningMasteryGradebookWrapper()

      const learningMasteryTab = getByText('Learning Mastery')
      expect(learningMasteryTab).toBeInTheDocument()

      fireEvent.click(learningMasteryTab)

      const hideStudentNamesCheckbox = getByTestId('hide-student-names-checkbox')
      expect(hideStudentNamesCheckbox).toBeInTheDocument()
      expect(hideStudentNamesCheckbox).toBeChecked()

      const gradebookExportLink = getByTestId('gradebook-export-link')
      expect(gradebookExportLink).toBeInTheDocument()
      expect(gradebookExportLink).toHaveAttribute(
        'href',
        'https://www.testattachment.com/attachment'
      )
      expect(gradebookExportLink).toHaveTextContent('Download Scores Generated on')

      // content selection query params
      await new Promise(resolve => setTimeout(resolve, 0))

      const contentSelectionStudent = getByTestId('learning-mastery-content-selection-student')
      expect(contentSelectionStudent).toBeInTheDocument()
      expect(within(contentSelectionStudent).getByText('Student 1')).toBeInTheDocument()

      const contentSelectionOutcome = getByTestId('learning-mastery-content-selection-outcome')
      expect(contentSelectionOutcome).toBeInTheDocument()
      expect(within(contentSelectionOutcome).getByText('JPLO')).toBeInTheDocument()

      // Outcome Result
      const outcomeResult = getByTestId('student-outcome-results')
      expect(outcomeResult).toBeInTheDocument()
      expect(queryByTestId('student-outcome-results-empty')).not.toBeInTheDocument()

      const studentOutcomeResult = getByTestId('student-outcome-rollup-results')
      expect(studentOutcomeResult).toBeInTheDocument()

      const stuentOutcomeRollupScore = getByTestId('student-outcome-rollup-1-data')
      expect(stuentOutcomeRollupScore).toBeInTheDocument()

      expect(getByTestId('student-outcome-rollup-1-data-average')).toHaveTextContent('3.33')
      expect(getByTestId('student-outcome-rollup-1-data-max')).toHaveTextContent('5')
      expect(getByTestId('student-outcome-rollup-1-data-min')).toHaveTextContent('0')
    })
  })

  describe('with presets on learning mastery', () => {
    it('renders on user changes tab', async () => {
      mockUserSettings()
      ;(window.ENV as any) = setGradebookOptions({
        gradebook_csv_progress: {
          progress: {
            updated_at: '2023-06-07T12:34:14-06:00',
          },
        },
        attachment_url: 'https://www.testattachment.com/attachment',
      })
      window.ENV.FEATURES = {instui_nav: true}
      mockSearchParams({student: '5', outcome: '1'})
      const {getByTestId, getByText} = renderLearningMasteryGradebookWrapper()

      const learningMasteryTab = getByText('Learning Mastery')
      expect(learningMasteryTab).toBeInTheDocument()

      fireEvent.click(learningMasteryTab)

      const hideStudentNamesCheckbox = getByTestId('hide-student-names-checkbox')
      expect(hideStudentNamesCheckbox).toBeInTheDocument()
      expect(hideStudentNamesCheckbox).toBeChecked()

      const gradebookExportLink = getByTestId('gradebook-export-link')
      expect(gradebookExportLink).toBeInTheDocument()
      expect(gradebookExportLink).toHaveAttribute(
        'href',
        'https://www.testattachment.com/attachment'
      )
      expect(gradebookExportLink).toHaveTextContent('Download Scores Generated on')

      // content selection query params
      await new Promise(resolve => setTimeout(resolve, 0))

      const contentSelectionStudent = getByTestId('learning-mastery-content-selection-student')
      expect(contentSelectionStudent).toBeInTheDocument()
      expect(within(contentSelectionStudent).getByText('Student 1')).toBeInTheDocument()

      const contentSelectionOutcome = getByTestId('learning-mastery-content-selection-outcome')
      expect(contentSelectionOutcome).toBeInTheDocument()
      expect(within(contentSelectionOutcome).getByText('JPLO')).toBeInTheDocument()

      // Outcome Result
      const outcomeResult = getByTestId('student-outcome-results')
      expect(outcomeResult).toBeInTheDocument()

      const outcomeResultTitle = getByTestId('student-outcome-title')
      expect(outcomeResultTitle).toBeInTheDocument()
      expect(outcomeResultTitle.textContent).toEqual('Results for: JPLO')

      // Student Information
      const studentInformationName = getByTestId('student-information-name')
      expect(studentInformationName).toBeInTheDocument()
      expect(within(studentInformationName).getByText('Student 1')).toBeInTheDocument()

      // Outcome Information
      const outcomeInformationResult = getByTestId('outcome-information-result')
      expect(outcomeInformationResult).toBeInTheDocument()
      expect(within(outcomeInformationResult).getByText('JPLO')).toBeInTheDocument()
      const outcomeInformationTitle = getByTestId('outcome-information-calculation-method')
      expect(outcomeInformationTitle).toBeInTheDocument()
      expect(
        within(outcomeInformationTitle).getByText('Calculation Method: Decaying Average - 65%/35%')
      ).toBeInTheDocument()

      const outcomeInformationExample = getByTestId('outcome-information-example')
      expect(outcomeInformationExample).toBeInTheDocument()
      expect(
        within(outcomeInformationExample).getByText(
          'Example: Most recent result counts as 65% of mastery weight, average of all other results count as 35% of weight. If there is only one result, the single score will be returned.'
        )
      ).toBeInTheDocument()
      // outcome-information-total-result
    })
  })

  describe('with no presets on learning mastery', () => {
    it('renders on user changes the tab', async () => {
      const {getByText, queryByTestId, getByTestId} = renderLearningMasteryGradebookWrapper()

      const assignmentTabData = queryByTestId('assignment-data')
      expect(assignmentTabData).toBeInTheDocument()
      expect(queryByTestId('learning-mastery-data')).not.toBeInTheDocument()

      const learningMasteryTab = getByText('Learning Mastery')
      expect(learningMasteryTab).toBeInTheDocument()

      fireEvent.click(learningMasteryTab)

      const learningMasteryData = getByTestId('learning-mastery-data')
      expect(learningMasteryData).toBeInTheDocument()
      expect(assignmentTabData).not.toBeInTheDocument()

      const hideStudentNamesCheckbox = getByTestId('hide-student-names-checkbox')
      expect(hideStudentNamesCheckbox).toBeInTheDocument()
      expect(hideStudentNamesCheckbox).not.toBeChecked()

      await new Promise(resolve => setTimeout(resolve, 0))

      // Content selection
      const contentSelectionStudent = getByTestId('learning-mastery-content-selection-student')
      expect(within(contentSelectionStudent).getByText('No Student Selected')).toBeInTheDocument()

      const contentSelectionOutcome = getByTestId('learning-mastery-content-selection-outcome')
      expect(within(contentSelectionOutcome).getByText('No Outcome Selected')).toBeInTheDocument()

      // Outcome Result
      const outcomeResult = getByTestId('student-outcome-results-empty')
      expect(
        within(outcomeResult).getByText('Select a student and an outcome to view results.')
      ).toBeInTheDocument()

      // Student Information
      const studentInformation = getByTestId('student-information-empty')
      expect(
        within(studentInformation).getByText(
          'Select a student to view additional information here.'
        )
      ).toBeInTheDocument()

      // Outcome Information
      const outcomeInformation = getByTestId('outcome-information-empty')
      expect(
        within(outcomeInformation).getByText('Select a outcome to view additional information')
      ).toBeInTheDocument()
    })
  })

  describe('without presets on induvidual gradebook', () => {
    it('renders without error', async () => {
      const {queryByTestId, getByTestId} = renderLearningMasteryGradebookWrapper()

      const assignmentTabData = queryByTestId('assignment-data')
      expect(assignmentTabData).toBeInTheDocument()
      expect(queryByTestId('learning-mastery-data')).not.toBeInTheDocument()

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
  })
})
