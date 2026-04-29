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
import {cleanup, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {Navigator, NavigatorComponentProps} from '../Navigator'

describe('Navigator', () => {
  afterEach(() => {
    cleanup()
  })

  const defaultProps: NavigatorComponentProps = {
    hasPrevious: true,
    hasNext: true,
    previousLabel: 'Previous item',
    nextLabel: 'Next item',
    onPrevious: vi.fn(),
    onNext: vi.fn(),
    children: <div>Current Item</div>,
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders children content', () => {
    render(<Navigator {...defaultProps} />)
    expect(screen.getByText('Current Item')).toBeInTheDocument()
  })

  it('renders previous and next buttons', () => {
    render(<Navigator {...defaultProps} />)
    expect(screen.getByTestId('previous-button')).toBeInTheDocument()
    expect(screen.getByTestId('next-button')).toBeInTheDocument()
  })

  it('calls onPrevious when previous button is clicked', async () => {
    const user = userEvent.setup()
    const onPrevious = vi.fn()
    render(<Navigator {...defaultProps} onPrevious={onPrevious} />)

    await user.click(screen.getByTestId('previous-button'))
    expect(onPrevious).toHaveBeenCalledTimes(1)
  })

  it('calls onNext when next button is clicked', async () => {
    const user = userEvent.setup()
    const onNext = vi.fn()
    render(<Navigator {...defaultProps} onNext={onNext} />)

    await user.click(screen.getByTestId('next-button'))
    expect(onNext).toHaveBeenCalledTimes(1)
  })

  it('disables previous button when hasPrevious is false', () => {
    render(<Navigator {...defaultProps} hasPrevious={false} />)
    const previousButton = screen.getByTestId('previous-button')
    expect(previousButton).toBeDisabled()
  })

  it('disables next button when hasNext is false', () => {
    render(<Navigator {...defaultProps} hasNext={false} />)
    const nextButton = screen.getByTestId('next-button')
    expect(nextButton).toBeDisabled()
  })

  it('disables both buttons when disabled prop is true', () => {
    render(<Navigator {...defaultProps} disabled={true} />)
    expect(screen.getByTestId('previous-button')).toBeDisabled()
    expect(screen.getByTestId('next-button')).toBeDisabled()
  })

  it('uses custom labels for buttons', () => {
    render(<Navigator {...defaultProps} previousLabel="Go Back" nextLabel="Go Forward" />)
    expect(screen.getByText('Go Back')).toBeInTheDocument()
    expect(screen.getByText('Go Forward')).toBeInTheDocument()
  })

  it('focuses next button when reaching first item', async () => {
    const {rerender} = render(<Navigator {...defaultProps} hasPrevious={true} />)

    rerender(<Navigator {...defaultProps} hasPrevious={false} />)

    await waitFor(() => {
      expect(screen.getByTestId('next-button')).toHaveFocus()
    })
  })

  it('focuses previous button when reaching last item', async () => {
    const {rerender} = render(<Navigator {...defaultProps} hasNext={true} />)

    rerender(<Navigator {...defaultProps} hasNext={false} />)

    await waitFor(() => {
      expect(screen.getByTestId('previous-button')).toHaveFocus()
    })
  })

  it('maintains focus on previous button after clicking it', async () => {
    const user = userEvent.setup()
    render(<Navigator {...defaultProps} />)

    const previousButton = screen.getByTestId('previous-button')
    await user.click(previousButton)

    await waitFor(() => {
      expect(previousButton).toHaveFocus()
    })
  })

  it('maintains focus on next button after clicking it', async () => {
    const user = userEvent.setup()
    render(<Navigator {...defaultProps} />)

    const nextButton = screen.getByTestId('next-button')
    await user.click(nextButton)

    await waitFor(() => {
      expect(nextButton).toHaveFocus()
    })
  })

  it('renders with custom data-testid', () => {
    render(<Navigator {...defaultProps} data-testid="custom-navigator" />)
    expect(screen.getByTestId('custom-navigator')).toBeInTheDocument()
  })
})
