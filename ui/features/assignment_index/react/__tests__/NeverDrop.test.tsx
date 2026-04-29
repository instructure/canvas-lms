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
import NeverDrop from '../NeverDrop'

describe('NeverDrop', () => {
  afterEach(() => {
    cleanup()
  })

  const mockAssignments = [
    {id: '1', name: 'Assignment 1'},
    {id: '2', name: 'Assignment 2'},
    {id: '3', name: 'Assignment 3'},
  ]

  const defaultProps = {
    canChangeDropRules: true,
    assignments: mockAssignments,
    label_id: 'test-label',
    onRemove: vi.fn(),
    onChange: vi.fn(),
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  test('renders remove button with correct title', () => {
    render(<NeverDrop {...defaultProps} />)

    const button = screen.getByTestId('remove-never-drop-button')
    expect(button).toBeInTheDocument()
    expect(button).toHaveAttribute('title', 'Remove unsaved never drop rule')
  })

  test('renders select dropdown when not chosen', () => {
    render(<NeverDrop {...defaultProps} />)

    const select = screen.getByTestId('never-drop-select')
    expect(select).toBeInTheDocument()
    expect(select).toHaveAttribute('aria-labelledby', 'ag_test-label_never_drop')
  })

  test('renders all assignment options in select', () => {
    render(<NeverDrop {...defaultProps} />)

    mockAssignments.forEach(assignment => {
      expect(screen.getByText(assignment.name)).toBeInTheDocument()
    })
  })

  test('renders chosen assignment when provided', () => {
    render(<NeverDrop {...defaultProps} chosen="Assignment 1" chosen_id="1" />)

    expect(screen.getByTestId('chosen-assignment')).toHaveTextContent('Assignment 1')
    expect(screen.queryByTestId('never-drop-select')).not.toBeInTheDocument()
  })

  test('renders hidden input with chosen_id when chosen', () => {
    const {container} = render(<NeverDrop {...defaultProps} chosen="Assignment 1" chosen_id="1" />)

    const hiddenInput = container.querySelector('input[type="hidden"]')
    expect(hiddenInput).toBeInTheDocument()
    expect(hiddenInput).toHaveAttribute('value', '1')
  })

  test('calls onChange when select value changes', async () => {
    const user = userEvent.setup()
    render(<NeverDrop {...defaultProps} />)

    const select = screen.getByTestId('never-drop-select')
    await user.selectOptions(select, '2')

    expect(defaultProps.onChange).toHaveBeenCalledWith('2')
  })

  test('calls onRemove when remove button is clicked', async () => {
    const user = userEvent.setup()
    render(<NeverDrop {...defaultProps} />)

    const button = screen.getByTestId('remove-never-drop-button')
    await user.click(button)

    expect(defaultProps.onRemove).toHaveBeenCalled()
  })

  test('disables remove button when canChangeDropRules is false', () => {
    render(<NeverDrop {...defaultProps} canChangeDropRules={false} />)

    const button = screen.getByTestId('remove-never-drop-button')
    expect(button).toHaveClass('disabled')
    expect(button).toHaveAttribute('aria-disabled', 'true')
  })

  test('does not call onRemove when disabled button is clicked', async () => {
    const user = userEvent.setup()
    render(<NeverDrop {...defaultProps} canChangeDropRules={false} />)

    const button = screen.getByTestId('remove-never-drop-button')
    await user.click(button)

    expect(defaultProps.onRemove).not.toHaveBeenCalled()
  })

  test('sets select as disabled when canChangeDropRules is false', () => {
    render(<NeverDrop {...defaultProps} canChangeDropRules={false} />)

    const select = screen.getByTestId('never-drop-select')
    expect(select).toHaveAttribute('disabled')
  })

  test('does not call onChange when disabled select is changed', async () => {
    const user = userEvent.setup()
    render(<NeverDrop {...defaultProps} canChangeDropRules={false} />)

    const select = screen.getByTestId('never-drop-select')
    await user.selectOptions(select, '2')

    expect(defaultProps.onChange).not.toHaveBeenCalled()
  })

  test('updates button title with chosen assignment name', () => {
    render(<NeverDrop {...defaultProps} chosen="Assignment 2" />)

    const button = screen.getByTestId('remove-never-drop-button')
    expect(button).toHaveAttribute('title', 'Remove never drop rule Assignment 2')
  })
})
