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
import {FocusableCell} from '../FocusableCell'

describe('FocusableCell', () => {
  it('renders children', () => {
    render(
      <FocusableCell>
        <div>Test Content</div>
      </FocusableCell>,
    )
    expect(screen.getByText('Test Content')).toBeInTheDocument()
  })

  it('renders with render prop pattern', () => {
    render(
      <FocusableCell>{focused => <div>{focused ? 'Focused' : 'Not Focused'}</div>}</FocusableCell>,
    )
    expect(screen.getByText('Not Focused')).toBeInTheDocument()
  })

  it('passes focused state to render prop when focused', async () => {
    const user = userEvent.setup()
    render(
      <FocusableCell>{focused => <div>{focused ? 'Focused' : 'Not Focused'}</div>}</FocusableCell>,
    )

    const cell = screen.getByRole('gridcell')
    await user.click(cell)

    expect(screen.getByText('Focused')).toBeInTheDocument()
  })

  it('is keyboard focusable with tabIndex 0', () => {
    render(
      <FocusableCell>
        <div>Test Content</div>
      </FocusableCell>,
    )
    const cell = screen.getByRole('gridcell')
    expect(cell).toHaveAttribute('tabIndex', '0')
  })

  it('can be focused programmatically', async () => {
    const user = userEvent.setup()
    render(
      <FocusableCell>
        <div>Test Content</div>
      </FocusableCell>,
    )
    const cell = screen.getByRole('gridcell')
    await user.click(cell)
    expect(cell).toHaveFocus()
  })

  it('passes props through to underlying Cell', () => {
    render(
      <FocusableCell background="secondary" data-testid="custom-cell">
        <div>Test Content</div>
      </FocusableCell>,
    )
    const cell = screen.getByTestId('custom-cell')
    expect(cell).toBeInTheDocument()
  })
})
