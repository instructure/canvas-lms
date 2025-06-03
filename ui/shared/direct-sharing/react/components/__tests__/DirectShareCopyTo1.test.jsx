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
import {render, fireEvent, waitFor} from '@testing-library/react'
import DirectShareCourseTray from '../DirectShareCourseTray'
import useManagedCourseSearchApi from '../../effects/useManagedCourseSearchApi'
import useModuleCourseSearchApi from '../../effects/useModuleCourseSearchApi'
import fakeENV from '@canvas/test-utils/fakeENV'

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
    fakeENV.setup({
      FEATURES: {
        validate_call_to_action: false,
      },
    })
    jest.clearAllMocks()
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  describe('tray controls', () => {
    it('closes the tray when X is clicked', async () => {
      // Setup mocks
      useManagedCourseSearchApi.mockImplementation(({success}) => {
        success(userManagedCoursesList)
        return () => {} // Cleanup function
      })

      const handleDismiss = jest.fn()
      const {getByText} = render(<DirectShareCourseTray open={true} onDismiss={handleDismiss} />)

      // Find and click the close button
      const closeButton = getByText('Close')
      fireEvent.click(closeButton)

      expect(handleDismiss).toHaveBeenCalled()
    })

    it('handles error when user managed course fetch fails', async () => {
      // Setup mocks
      useManagedCourseSearchApi.mockImplementation(({error}) => {
        setTimeout(() => error([{status: 400, body: 'Error fetching data'}]), 0)
        return () => {} // Cleanup function
      })

      const {findByRole} = render(<DirectShareCourseTray open={true} />)

      // Wait for error message
      await waitFor(async () => {
        await expect(findByRole('heading', {name: 'Sorry, Something Broke'})).resolves.toBeTruthy()
      })
    })
  })
})
