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
import {render, fireEvent, waitFor} from '@testing-library/react'
import {setGradebookOptions, setupCanvasQueries} from './fixtures'
import {BrowserRouter, Route, Routes} from 'react-router-dom'
import EnhancedIndividualGradebook from '../EnhancedIndividualGradebook'
import userSettings from '@canvas/user-settings'
import {GradebookSortOrder} from '../../../types/gradebook.d'
import * as ReactRouterDom from 'react-router-dom'
import {executeApiRequest} from '@canvas/do-fetch-api-effect/apiRequest'
import fakeENV from '@canvas/test-utils/fakeENV'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {type Mocked} from 'vitest'

const server = setupServer()

vi.mock('axios')
vi.mock('@canvas/do-fetch-api-effect/apiRequest', () => ({
  executeApiRequest: vi.fn(),
}))
const mockedAxios = axios as Mocked<typeof axios>

const mockUserSettings = (mockGet = true) => {
  if (mockGet) {
    vi.spyOn(userSettings, 'contextGet').mockImplementation(input => {
      switch (input) {
        case 'sort_grade_columns_by':
          return {sortType: GradebookSortOrder.DueDate}
        case 'gradebook_current_grading_period':
          return '1'
        case 'hide_student_names':
          return true
        case 'include_ungraded_assignments':
          return true
      }
    })
  }
  const mockedContextSet = vi.spyOn(userSettings, 'contextSet')
  return {mockedContextSet}
}

describe('Enhanced Individual Gradebook - Server Settings', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    const options = setGradebookOptions({save_view_ungraded_as_zero_to_server: true})
    fakeENV.setup({
      ...options,
      FEATURES: {
        instui_nav: true,
      },
    })
    mockedAxios.get.mockResolvedValue({
      data: [],
    })
    $.subscribe = vi.fn()

    setupCanvasQueries()
  })

  afterEach(() => {
    server.resetHandlers()
    fakeENV.teardown()
    vi.spyOn(ReactRouterDom, 'useSearchParams').mockClear()
    vi.resetAllMocks()
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

  it('makes api call when "View Ungraded as 0" checkbox is checked & save-view-ungraded-as-zero-to-server is true', async () => {
    mockUserSettings(true)

    let apiCallMade = false
    server.use(
      http.put('/api/v1/courses/1/gradebook_settings', () => {
        apiCallMade = true
        return HttpResponse.json({})
      }),
    )

    const {getByTestId} = renderEnhancedIndividualGradebook()

    await waitFor(() => {
      expect(getByTestId('include-ungraded-assignments-checkbox')).toBeInTheDocument()
    })

    const viewUngradedAsZeroCheckbox = getByTestId('include-ungraded-assignments-checkbox')
    expect(viewUngradedAsZeroCheckbox).toBeChecked()

    fireEvent.click(viewUngradedAsZeroCheckbox)

    await waitFor(
      () => {
        expect(apiCallMade).toBe(true)
      },
      {timeout: 1000},
    )
  })
})
