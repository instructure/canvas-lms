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
import {cleanup, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {assignLocation} from '@canvas/util/globalUtils'
import SignInPrompt from '../SignInPrompt'

vi.mock('@canvas/util/globalUtils', () => ({
  assignLocation: vi.fn(),
}))

afterEach(() => {
  cleanup()
  vi.clearAllMocks()
})

describe('<SignInPrompt />', () => {
  it('renders prompt text and login link', () => {
    render(<SignInPrompt />)
    expect(screen.getByText('Already have an account?')).toBeInTheDocument()
    const link = screen.getByTestId('log-in-link')
    expect(link).toBeInTheDocument()
    expect(link).toHaveAttribute('href', '/login')
  })

  it('calls assignLocation on click', async () => {
    render(<SignInPrompt />)
    const link = screen.getByTestId('log-in-link')
    await userEvent.click(link)
    expect(assignLocation).toHaveBeenCalledWith('/login')
  })
})
