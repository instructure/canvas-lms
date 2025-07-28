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
    it('renders a dropped message if the assignment is being dropped from grade calculation for the current student', async () => {
      mockUserSettings()
      const {getByTestId} = renderEnhancedIndividualGradebook()
      await new Promise(resolve => setTimeout(resolve, CUSTOM_TIMEOUT_LIMIT))
      fireEvent.change(getByTestId('content-selection-assignment-select'), {target: {value: '1'}})
      fireEvent.change(getByTestId('content-selection-student-select'), {target: {value: '5'}})
      await new Promise(resolve => setTimeout(resolve, 0))

      const gradingResults = getByTestId('grading-results')
      expect(
        within(gradingResults).getByText('Grade for Student 1 - Missing Assignment 1'),
      ).toBeInTheDocument()
      expect(
        within(gradingResults).queryByText('This grade is currently dropped for this student.'),
      ).not.toBeInTheDocument()

      fireEvent.change(getByTestId('content-selection-assignment-select'), {target: {value: '2'}})
      fireEvent.change(getByTestId('content-selection-student-select'), {target: {value: '5'}})
      await new Promise(resolve => setTimeout(resolve, 0))

      expect(
        within(gradingResults).getByText('Grade for Student 1 - Missing Assignment 2'),
      ).toBeInTheDocument()
      expect(
        within(gradingResults).getByText('This grade is currently dropped for this student.'),
      ).toBeInTheDocument()
    })

    it('does not render another flash message when switching students after setting default grades for the assignment', async () => {
      mockUserSettings()
      const {getByTestId, getByRole} = renderEnhancedIndividualGradebook()
      await new Promise(resolve => setTimeout(resolve, CUSTOM_TIMEOUT_LIMIT))
      mockedExecuteApiRequest.mockResolvedValue({
        data: [],
        status: 201,
      })
      fireEvent.change(getByTestId('content-selection-assignment-select'), {target: {value: '1'}})
      fireEvent.click(getByTestId('default-grade-button'))
      fireEvent.change(getByTestId('default-grade-input'), {target: {value: '10'}})
      fireEvent.blur(getByTestId('default-grade-input'))
      fireEvent.click(getByTestId('default-grade-submit-button'))
      await new Promise(resolve => setTimeout(resolve, 0))
      fireEvent.change(getByTestId('content-selection-student-select'), {target: {value: '5'}})
      const parentElement = getByRole('alert')
      const childElements = parentElement?.children
      expect(childElements?.length).toBe(1)
    })
  })
})
