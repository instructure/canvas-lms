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
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import * as useManagedCourseSearchApi from '../../effects/useManagedCourseSearchApi'
import DirectShareCourseTray from '../DirectShareCourseTray'
import fakeENV from '@canvas/test-utils/fakeENV'

vi.mock('../../effects/useManagedCourseSearchApi')

// Mock the lazy-loaded component to avoid dynamic import issues in tests
vi.mock('../DirectShareCoursePanel', () => ({
  default: function MockDirectShareCoursePanel({onCancel}: {onCancel: () => void}) {
    return (
      <div>
        <span>Select a Course</span>
        <button data-testid="confirm-action-secondary-button" onClick={onCancel}>
          Cancel
        </button>
      </div>
    )
  },
}))

describe('DirectShareCourseTray', () => {
  let ariaLive: HTMLElement

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
    fakeENV.setup()
    // Reset the mock implementation
    vi.spyOn(useManagedCourseSearchApi, 'default').mockImplementation(() => undefined)
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('displays interface for selecting a course', async () => {
    const {findByText} = render(
      <DirectShareCourseTray
        open={true}
        sourceCourseId=""
        contentSelection={{}}
        onDismiss={() => {}}
      />,
    )
    // loads the panel asynchronously via React.lazy, so we have to wait for Suspense to resolve
    expect(await findByText(/select a course/i)).toBeInTheDocument()
  })

  it('calls onDismiss when cancel is clicked', async () => {
    const handleDismiss = vi.fn()
    const user = userEvent.setup()
    const {findByTestId} = render(
      <DirectShareCourseTray
        open={true}
        onDismiss={handleDismiss}
        sourceCourseId=""
        contentSelection={{}}
      />,
    )

    // Wait for the lazy-loaded panel to render with the cancel button
    const cancelButton = await findByTestId('confirm-action-secondary-button')
    await user.click(cancelButton)
    expect(handleDismiss).toHaveBeenCalled()
  })
})
