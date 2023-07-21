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
import {render, fireEvent, waitFor} from '@testing-library/react'
import useManagedCourseSearchApi from '../../effects/useManagedCourseSearchApi'
import DirectShareCourseTray from '../DirectShareCourseTray'

jest.mock('../../effects/useManagedCourseSearchApi')

describe('DirectShareCourseTray', () => {
  let ariaLive

  beforeAll(() => {
    ariaLive = document.createElement('div')
    ariaLive.id = 'flash_screenreader_holder'
    ariaLive.setAttribute('role', 'alert')
    document.body.appendChild(ariaLive)
  })

  afterAll(() => {
    if (ariaLive) ariaLive.remove()
  })

  beforeEach(() => {
    useManagedCourseSearchApi.mockImplementation(() => {})
  })

  it('displays interface for selecting a course', async () => {
    const {getByText} = render(<DirectShareCourseTray open={true} />)
    // loads the panel asynchronously, so we have to wait for it
    expect(await waitFor(() => getByText(/select a course/i))).toBeInTheDocument()
  })

  it('calls onDismiss when cancel is clicked', async () => {
    const handleDismiss = jest.fn()
    const {getByText} = render(<DirectShareCourseTray open={true} onDismiss={handleDismiss} />)
    fireEvent.click(await waitFor(() => getByText(/cancel/i)))
    expect(handleDismiss).toHaveBeenCalled()
  })
})
