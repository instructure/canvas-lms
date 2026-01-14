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
import {CellWithAction} from '../CellWithAction'

describe('CellWithAction', () => {
  const defaultProps = {
    actionLabel: 'View Details',
    children: <div>Cell Content</div>,
  }

  it('renders children', () => {
    render(<CellWithAction {...defaultProps} />)
    expect(screen.getByText('Cell Content')).toBeInTheDocument()
  })

  it('does not show action button when not focused', () => {
    render(<CellWithAction {...defaultProps} />)
    expect(screen.queryByRole('button')).not.toBeInTheDocument()
  })

  it('shows action button when cell is focused', async () => {
    const user = userEvent.setup()
    render(<CellWithAction {...defaultProps} />)

    const cell = screen.getByRole('gridcell')
    await user.click(cell)

    expect(screen.getByRole('button', {name: 'View Details'})).toBeInTheDocument()
  })

  it('calls onAction when action button is clicked', async () => {
    const user = userEvent.setup()
    const onAction = jest.fn()
    render(<CellWithAction {...defaultProps} onAction={onAction} />)

    const cell = screen.getByRole('gridcell')
    await user.click(cell)

    const button = screen.getByRole('button', {name: 'View Details'})
    await user.click(button)

    expect(onAction).toHaveBeenCalledTimes(1)
  })

  it('does not call onAction when onAction is undefined', async () => {
    const user = userEvent.setup()
    render(<CellWithAction {...defaultProps} />)

    const cell = screen.getByRole('gridcell')
    await user.click(cell)

    const button = screen.getByRole('button', {name: 'View Details'})
    await user.click(button)
  })

  it('renders with custom actionLabel', async () => {
    const user = userEvent.setup()
    render(<CellWithAction {...defaultProps} actionLabel="Open Tray" />)

    const cell = screen.getByRole('gridcell')
    await user.click(cell)

    expect(screen.getByRole('button', {name: 'Open Tray'})).toBeInTheDocument()
  })

  it('passes props through to FocusableCell', () => {
    render(<CellWithAction {...defaultProps} background="secondary" data-testid="custom-cell" />)
    expect(screen.getByTestId('custom-cell')).toBeInTheDocument()
  })

  it('renders IconExpandStartLine icon', async () => {
    const user = userEvent.setup()
    render(<CellWithAction {...defaultProps} />)

    const cell = screen.getByRole('gridcell')
    await user.click(cell)

    const button = screen.getByRole('button', {name: 'View Details'})
    const svg = button.querySelector('svg')
    expect(svg).toBeInTheDocument()
  })
})
