/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render, fireEvent, act} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import DirectShareCourseTray from '../DirectShareCourseTray'
import useManagedCourseSearchApi from '../../effects/useManagedCourseSearchApi'
import useModuleCourseSearchApi from '../../effects/useModuleCourseSearchApi'

jest.mock('../../effects/useManagedCourseSearchApi')
jest.mock('../../effects/useModuleCourseSearchApi')

const userManagedCoursesList = [
  {
    name: 'Course Math 101',
    id: '234',
    term: 'Default Term',
    enrollment_start: null,
    account_name: 'QA-LOCAL-QA',
    account_id: '1',
    start_at: 'Aug 6, 2019 at 6:47pm',
    end_at: null,
  },
  {
    name: 'Course Advanced Math 200',
    id: '123',
    term: 'Default Term',
    enrollment_start: null,
    account_name: 'QA-LOCAL-QA',
    account_id: '1',
    start_at: 'Apr 27, 2019 at 2:19pm',
    end_at: 'Dec 31, 2019 at 3am',
  },
]

describe('DirectShareCopyToTray', () => {
  beforeEach(() => {
    jest.spyOn(console, 'error').mockImplementation(() => {})
  })
  afterEach(() => {
    console.error.mockRestore()
    fetchMock.restore()
  })

  describe('tray controls', () => {
    it('closes the tray when X is clicked', () => {
      const handleDismiss = jest.fn()
      const {getByText} = render(<DirectShareCourseTray open={true} onDismiss={handleDismiss} />)
      fireEvent.click(getByText(/close/i))

      expect(handleDismiss).toHaveBeenCalled()
    })

    it('handles error when user managed course fetch fails', async () => {
      useManagedCourseSearchApi.mockImplementationOnce(({error}) =>
        error([{status: 400, body: 'Error fetching data'}])
      )
      const {getByText} = render(<DirectShareCourseTray open={true} />)

      expect(getByText('Sorry, Something Broke')).toBeInTheDocument()
    })

    it('handles error when course module fetch fails', async () => {
      useManagedCourseSearchApi.mockImplementationOnce(({success}) => {
        success(userManagedCoursesList)
      })
      useModuleCourseSearchApi.mockImplementationOnce(({error}) =>
        error([{status: 400, body: 'Error fetching data'}])
      )
      const {getByText} = render(<DirectShareCourseTray open={true} />)
      fireEvent.click(getByText(/select a course/i))
      fireEvent.click(getByText('Course Math 101'))
      await act(() => fetchMock.flush(true))

      expect(getByText('Sorry, Something Broke')).toBeInTheDocument()
    })
  })

  describe('course dropdown', () => {
    it('populates the list of all managed courses', () => {
      useManagedCourseSearchApi.mockImplementationOnce(({success}) => {
        success(userManagedCoursesList)
      })
      const {getByText, getByLabelText} = render(<DirectShareCourseTray open={true} />)
      const courseDropdown = getByLabelText(/select a course/i)
      fireEvent.click(courseDropdown)

      expect(getByText('Course Advanced Math 200')).toBeInTheDocument()
      expect(getByText('Course Math 101')).toBeInTheDocument()
    })
  })

  describe('place dropdown', () => {
    it('user can select place to be at the top', () => {})
    it('user can select place to be at the bottom', () => {})
  })

  describe('copying', () => {
    it('clicking the copy button displays a loading state', async () => {})
  })
})
