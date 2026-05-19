/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import AnonymousSpeedGraderAlert from '../AnonymousSpeedGraderAlert'

describe('AnonymousSpeedGraderAlert', () => {
  const defaultProps = {
    speedGraderUrl: 'http://test.url:3000/speed_grader',
    onClose: vi.fn(),
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  const renderComponent = (props = {}) => {
    render(<AnonymousSpeedGraderAlert {...defaultProps} {...props} />)
  }

  it('shows the alert content when initiallyOpen is true', async () => {
    renderComponent({initiallyOpen: true})
    await waitFor(() => {
      expect(screen.getByText('Anonymous Mode On:')).toBeInTheDocument()
    })
    expect(
      screen.getByText('Unable to access specific student. Go to assignment in SpeedGrader?'),
    ).toBeInTheDocument()
  })

  it('renders the Open SpeedGrader link with the correct href', async () => {
    renderComponent({speedGraderUrl: 'http://custom.url/speed_grader', initiallyOpen: true})
    const openButton = await screen.findByRole('link', {name: /Open SpeedGrader/i})
    expect(openButton).toHaveAttribute('href', 'http://custom.url/speed_grader')
  })

  it('renders a Cancel button', async () => {
    renderComponent({initiallyOpen: true})
    const cancelButton = await screen.findByRole('button', {name: /Cancel/i})
    expect(cancelButton).toBeInTheDocument()
  })

  it('calls onClose when Cancel is clicked', async () => {
    const onClose = vi.fn()
    renderComponent({onClose, initiallyOpen: true})
    const cancelButton = await screen.findByRole('button', {name: /Cancel/i})
    await userEvent.click(cancelButton)
    await waitFor(() => {
      expect(onClose).toHaveBeenCalled()
    })
  })

  it('closes the alert when Cancel is clicked', async () => {
    renderComponent({initiallyOpen: true})
    await waitFor(() => {
      expect(screen.getByText('Anonymous Mode On:')).toBeInTheDocument()
    })
    const cancelButton = screen.getByRole('button', {name: /Cancel/i})
    await userEvent.click(cancelButton)
    await waitFor(() => {
      expect(screen.queryByText('Anonymous Mode On:')).not.toBeInTheDocument()
    })
  })
})
