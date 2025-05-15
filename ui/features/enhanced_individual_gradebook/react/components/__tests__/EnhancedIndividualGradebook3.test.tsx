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

  describe('student dropdown handler tests', () => {
    it('should change student query param when student dropdown is changed to valid student', async () => {
      const {searchParamsMock, setSearchParamsMock} = mockSearchParams()
      const {getByTestId} = renderEnhancedIndividualGradebook()
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(searchParamsMock.get('student')).toBe(null)
      await new Promise(resolve => setTimeout(resolve, CUSTOM_TIMEOUT_LIMIT))
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
      await new Promise(resolve => setTimeout(resolve, CUSTOM_TIMEOUT_LIMIT))
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
      await new Promise(resolve => setTimeout(resolve, CUSTOM_TIMEOUT_LIMIT))
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
      await new Promise(resolve => setTimeout(resolve, CUSTOM_TIMEOUT_LIMIT))
      const contentSelectionAssignment = getByTestId('content-selection-assignment-select')
      expect(contentSelectionAssignment).toBeInTheDocument()
      fireEvent.change(contentSelectionAssignment, {target: {value: '-1'}})
      expect(searchParamsMock.get('assignment')).toBe(null)
      expect(setSearchParamsMock).toHaveBeenCalledWith(searchParamsMock)
    })
  })
})
