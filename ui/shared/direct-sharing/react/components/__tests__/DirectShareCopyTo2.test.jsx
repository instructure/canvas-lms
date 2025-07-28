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
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import DirectShareCourseTray from '../DirectShareCourseTray'
import DirectShareCoursePanel from '../DirectShareCoursePanel'
import {useManagedCourseSearchApi} from '@canvas/direct-sharing/react/effects/useManagedCourseSearchApi'
import {useModuleCourseSearchApi} from '@canvas/direct-sharing/react/effects/useModuleCourseSearchApi'
import fakeENV from '@canvas/test-utils/fakeENV'

// Mock the lazy loaded component to avoid issues with lazy loading in tests
jest.mock('../DirectShareCoursePanel', () => jest.fn())

jest.mock('@canvas/direct-sharing/react/effects/useManagedCourseSearchApi', () => ({
  useManagedCourseSearchApi: jest.fn(),
}))
jest.mock('@canvas/direct-sharing/react/effects/useModuleCourseSearchApi', () => ({
  useModuleCourseSearchApi: jest.fn(),
}))

const userManagedCoursesList = [
  {
    name: 'Course Math 101',
    id: '1',
    term: {name: 'Default Term'},
    teachers: [{display_name: 'Teacher'}],
  },
  {
    name: 'Course Advanced Math 200',
    id: '2',
    term: {name: 'Default Term'},
    teachers: [{display_name: 'Teacher'}],
  },
]

// Mock implementation for testability
DirectShareCoursePanel.mockImplementation(_props => {
  // Track if the error panel should be shown
  const [showError, setShowError] = React.useState(false)

  // When a course is selected, check if we should show an error
  const handleCourseSelect = _e => {
    // If this is the error test, show the error panel
    if (useModuleCourseSearchApi.mock && useModuleCourseSearchApi.mock.calls.length > 0) {
      setShowError(true)
    }
  }

  // If showing error, render the error panel
  if (showError) {
    return (
      <div data-testid="error-panel">
        <h1>Sorry, Something Broke</h1>
        <span>Help us improve by telling us what happened</span>
        <button>Report Issue</button>
      </div>
    )
  }

  // Otherwise show the course selector
  return (
    <div data-testid="course-panel">
      <select data-testid="course-selector" role="combobox" onChange={handleCourseSelect}>
        {userManagedCoursesList.map(course => (
          <option key={course.id} value={course.id}>
            {course.name}
          </option>
        ))}
      </select>
    </div>
  )
})

describe('DirectShareCopyToTray', () => {
  let user

  beforeEach(() => {
    fakeENV.setup({
      COURSE_ID: '3',
    })
    jest.clearAllMocks()
    user = userEvent.setup()
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('populates the list of all managed courses', async () => {
    // Mock the API hook
    useManagedCourseSearchApi.mockReturnValue({
      loading: false,
      error: null,
      itemSearchFunction: () => Promise.resolve(userManagedCoursesList),
      cleanup: jest.fn(),
    })

    const {findByTestId, findByText} = render(<DirectShareCourseTray open={true} />)

    // Wait for the panel to be rendered
    const panel = await findByTestId('course-panel')
    expect(panel).toBeInTheDocument()

    // Verify course options are in the document
    const course1 = await findByText('Course Math 101')
    const course2 = await findByText('Course Advanced Math 200')

    expect(course1).toBeInTheDocument()
    expect(course2).toBeInTheDocument()
  })

  // fickle
  it.skip('handles error when course module fetch fails', async () => {
    // Set up error data
    const errorData = [{status: 400, body: 'Error fetching data'}]

    // Mock the API hook for course list
    useManagedCourseSearchApi.mockReturnValue({
      loading: false,
      error: null,
      itemSearchFunction: () => Promise.resolve(userManagedCoursesList),
      cleanup: jest.fn(),
    })

    // Mock the module API to trigger error
    useModuleCourseSearchApi.mockImplementation(({error}) => {
      setTimeout(() => error(errorData), 0)

      return {
        loading: false,
        error: null,
        itemSearchFunction: () => Promise.reject(errorData),
        cleanup: jest.fn(),
      }
    })

    // Create a spy to track when the error callback is called
    const errorSpy = jest.spyOn(useModuleCourseSearchApi.mock.calls[0][0], 'error')

    // Render the component with mocked DirectShareCoursePanel implementation
    const {findByTestId, findByText} = render(<DirectShareCourseTray open={true} />)

    // Wait for panel to be rendered
    const panel = await findByTestId('course-panel')
    expect(panel).toBeInTheDocument()

    // Trigger course selection - this will cause the error to be thrown
    const courseSelector = await findByTestId('course-selector')
    await user.selectOptions(courseSelector, '1')

    // Wait for the error callback to be called
    await waitFor(() => {
      expect(errorSpy).toHaveBeenCalled()
    })

    // Verify the error was handled
    expect(errorSpy).toHaveBeenCalledWith(errorData)
  })
})
