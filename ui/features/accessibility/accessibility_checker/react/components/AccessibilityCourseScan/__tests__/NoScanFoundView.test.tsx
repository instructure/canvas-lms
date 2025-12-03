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
import {NoScanFoundView} from '../components/NoScanFoundView'

describe('NoScanFoundView', () => {
  it('renders empty state with message', () => {
    render(<NoScanFoundView />)

    expect(screen.getByText("You haven't scanned your course yet")).toBeInTheDocument()
  })

  it('renders scan button in center', () => {
    render(<NoScanFoundView />)

    const centerButtons = screen.getAllByRole('button', {name: /scan course/i})
    expect(centerButtons).toHaveLength(2) // One in header, one in center
  })

  it('calls handleCourseScan when button is clicked', async () => {
    const user = userEvent.setup()
    const handleCourseScan = jest.fn()

    render(<NoScanFoundView handleCourseScan={handleCourseScan} />)

    const centerButton = screen.getAllByRole('button', {name: /scan course/i})[1]
    await user.click(centerButton)

    expect(handleCourseScan).toHaveBeenCalledTimes(1)
  })

  it('disables button when request is loading', () => {
    render(<NoScanFoundView isRequestLoading={true} />)

    const buttons = screen.getAllByRole('button', {name: /scan course/i})
    buttons.forEach(button => {
      expect(button).toBeDisabled()
    })
  })

  it('enables button when request is not loading', () => {
    render(<NoScanFoundView isRequestLoading={false} />)

    const buttons = screen.getAllByRole('button', {name: /scan course/i})
    buttons.forEach(button => {
      expect(button).not.toBeDisabled()
    })
  })
})
