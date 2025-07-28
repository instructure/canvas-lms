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
import {render, fireEvent} from '@testing-library/react'
import {setGradebookOptions, setupCanvasQueries} from './fixtures'
import {BrowserRouter, Route, Routes} from 'react-router-dom'
import EnhancedIndividualGradebook from '../EnhancedIndividualGradebook'
import userSettings from '@canvas/user-settings'
import {GradebookSortOrder} from '../../../types/gradebook.d'
import * as ReactRouterDom from 'react-router-dom'
import doFetchApi from '@canvas/do-fetch-api-effect'
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

  const renderEnhancedIndividualGradebook = () => {
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
      const options = setGradebookOptions({save_view_ungraded_as_zero_to_server: true})
      fakeENV.setup({
        ...options,
        FEATURES: {
          instui_nav: true,
        },
      })
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
      const options = setGradebookOptions({
        settings_update_url: 'http://canvas.docker/api/v1/courses/2/gradebook_settings',
      })
      fakeENV.setup({
        ...options,
        FEATURES: {
          instui_nav: true,
        },
      })
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
      const options = setGradebookOptions({
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
      fakeENV.setup({
        ...options,
        FEATURES: {
          instui_nav: true,
        },
      })
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
      const options = setGradebookOptions({
        final_grade_override_enabled: true,
      })
      fakeENV.setup({
        ...options,
        FEATURES: {
          instui_nav: true,
        },
      })
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
