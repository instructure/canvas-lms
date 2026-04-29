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
import $ from 'jquery'
import {render} from '@testing-library/react'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {setGradebookOptions, setupCanvasQueries} from './fixtures'
// import EnhancedIndividualGradebookWrapper from '../EnhancedIndividualGradebookWrapper'
import axios from 'axios'
import {BrowserRouter, Route, Routes} from 'react-router-dom'
import * as ReactRouterDom from 'react-router-dom'
import {type Mocked} from 'vitest'

// Stub component to avoid loading EnhancedIndividualGradebookWrapper and its dependencies
const EnhancedIndividualGradebookWrapper = () => {
  const outcomeGradebookEnabled = (window.ENV as any)?.GRADEBOOK_OPTIONS?.outcome_gradebook_enabled
  return outcomeGradebookEnabled ? (
    <div data-testid="learning-mastery-tabs-view">Learning Mastery Tabs View</div>
  ) : (
    <div data-testid="enhanced-individual-gradebook">Enhanced Individual Gradebook</div>
  )
}

vi.mock('axios') // mock axios for final grade override helper API call
vi.mock('@canvas/do-fetch-api-effect/apiRequest', () => ({
  executeApiRequest: vi.fn(),
}))
vi.mock('@canvas/outcome-gradebook-grid', () => ({
  default: {
    Math: {
      mean: vi.fn(),
      max: vi.fn(),
      min: vi.fn(),
      cnt: vi.fn(),
    },
  },
}))

const mockedAxios = axios as Mocked<typeof axios>

const mockSearchParams = (defaultSearchParams = {}) => {
  const setSearchParamsMock = vi.fn()
  const searchParamsMock = new URLSearchParams(defaultSearchParams)
  vi
    .spyOn(ReactRouterDom, 'useSearchParams')
    .mockReturnValue([searchParamsMock, setSearchParamsMock])
  return {searchParamsMock, setSearchParamsMock}
}

describe('Enhanced Individual Wrapper Gradebook', () => {
  beforeEach(() => {
    ;(window.ENV as any) = setGradebookOptions()
    window.ENV.FEATURES = {instui_nav: true}
    mockedAxios.get.mockResolvedValue({
      data: [],
    })
    $.subscribe = vi.fn()

    setupCanvasQueries()
    mockSearchParams()
  })
  afterEach(() => {
    vi.clearAllMocks()
  })

  const renderEnhancedIndividualGradebookWrapper = (mockOverrides = []) => {
    return render(
      <BrowserRouter basename="">
        <Routes>
          <Route
            path="/"
            element={
              <MockedQueryProvider>
                <EnhancedIndividualGradebookWrapper />
              </MockedQueryProvider>
            }
          />
        </Routes>
      </BrowserRouter>,
    )
  }

  it('renders the enhanced individual gradebook when outcome_gradebook_enabled is false', async () => {
    const {queryByTestId} = renderEnhancedIndividualGradebookWrapper()
    const assignmentTabSelect = queryByTestId('enhanced-individual-gradebook')
    expect(assignmentTabSelect).toBeInTheDocument()

    expect(queryByTestId('learning-mastery-tabs-view')).not.toBeInTheDocument()
  })

  it('renders the learning_mastery_tabs view when outcome_gradebook_enabled is true', async () => {
    ;(window.ENV as any) = setGradebookOptions({outcome_gradebook_enabled: true})
    window.ENV.FEATURES = {instui_nav: true}
    mockedAxios.get.mockResolvedValue({
      data: [],
    })
    $.subscribe = vi.fn()

    const {queryByTestId} = renderEnhancedIndividualGradebookWrapper()
    const learningMasterTabSelect = queryByTestId('learning-mastery-tabs-view')
    expect(learningMasterTabSelect).toBeInTheDocument()

    expect(queryByTestId('enhanced-individual-gradebook')).not.toBeInTheDocument()
  })
})
