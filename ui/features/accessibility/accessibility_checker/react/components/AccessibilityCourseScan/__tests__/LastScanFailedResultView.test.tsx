/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import {LastScanFailedResultView} from '../components/LastScanFailedResultView'

describe('LastScanFailedResultView', () => {
  it('renders error page', () => {
    render(<LastScanFailedResultView />)

    expect(screen.getByText('Sorry, Something Broke')).toBeInTheDocument()
  })

  it('renders scan button', () => {
    render(<LastScanFailedResultView />)

    expect(screen.getByRole('button', {name: /scan course/i})).toBeInTheDocument()
  })

  it('calls handleCourseScan when button is clicked', async () => {
    const user = userEvent.setup()
    const handleCourseScan = vi.fn()

    render(<LastScanFailedResultView handleCourseScan={handleCourseScan} />)

    const button = screen.getByRole('button', {name: /scan course/i})
    await user.click(button)

    expect(handleCourseScan).toHaveBeenCalledTimes(1)
  })

  it('disables button when request is loading', () => {
    render(<LastScanFailedResultView isRequestLoading={true} />)

    const button = screen.getByRole('button', {name: /scan course/i})
    expect(button).toBeDisabled()
  })

  it('enables button when request is not loading', () => {
    render(<LastScanFailedResultView isRequestLoading={false} />)

    const button = screen.getByRole('button', {name: /scan course/i})
    expect(button).not.toBeDisabled()
  })
})
