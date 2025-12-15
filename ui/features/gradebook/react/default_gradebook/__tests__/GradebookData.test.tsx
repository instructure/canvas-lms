// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-nocheck
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

import React from 'react'
import {render, screen} from '@testing-library/react'
import GradebookData from '../GradebookData'
import {defaultGradebookEnv, defaultGradebookProps} from './GradebookSpecHelper'
import useStore from '../stores'

// Mock urlHelpers before importing
vi.mock('../utils/urlHelpers', () => ({
  addCorrelationIdToUrl: vi.fn(),
}))

// Import the mocked module to get reference to the mock
import * as urlHelpers from '../utils/urlHelpers'

const defaultProps = {
  ...defaultGradebookProps,
  gradebookEnv: {
    ...defaultGradebookEnv,
  },
  performance_controls: {
    students_chunk_size: 2, // students per page
  },
}

window.ENV.SETTINGS = {}

describe('GradebookData', () => {
  const mockAddCorrelationIdToUrl = urlHelpers.addCorrelationIdToUrl as any

  beforeEach(() => {
    mockAddCorrelationIdToUrl.mockClear()
  })

  it.skip('renders', () => {
    render(<GradebookData {...defaultProps} />)
    expect(screen.getByTitle(/Loading Gradebook/i)).toBeInTheDocument()
    expect(screen.getByText(/Student Names/i)).toBeInTheDocument()
    expect(screen.getByText(/Assignment Names/i)).toBeInTheDocument()
  })

  it.skip('adds correlationId to URL before loading data', () => {
    // Spy on store data loading methods to verify they're called after URL update
    const loadStudentDataSpy = vi.spyOn(useStore.getState(), 'loadStudentData')
    const loadAssignmentGroupsSpy = vi.spyOn(useStore.getState(), 'loadAssignmentGroups')

    render(<GradebookData {...defaultProps} />)

    // Verify addCorrelationIdToUrl was called with a UUID
    expect(mockAddCorrelationIdToUrl).toHaveBeenCalledTimes(1)
    expect(mockAddCorrelationIdToUrl).toHaveBeenCalledWith(expect.stringMatching(/^[0-9a-f-]{36}$/))

    // Verify data loading functions were called
    expect(loadStudentDataSpy).toHaveBeenCalled()
    expect(loadAssignmentGroupsSpy).toHaveBeenCalled()

    // Verify URL was updated before any data loading using Jest's invocation order tracking
    const urlUpdateCallOrder = mockAddCorrelationIdToUrl.mock.invocationCallOrder[0]
    const loadStudentDataCallOrder = loadStudentDataSpy.mock.invocationCallOrder[0]
    const loadAssignmentGroupsCallOrder = loadAssignmentGroupsSpy.mock.invocationCallOrder[0]

    expect(urlUpdateCallOrder).toBeLessThan(loadStudentDataCallOrder)
    expect(urlUpdateCallOrder).toBeLessThan(loadAssignmentGroupsCallOrder)

    // Cleanup
    loadStudentDataSpy.mockRestore()
    loadAssignmentGroupsSpy.mockRestore()
  })
})
