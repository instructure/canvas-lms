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
import WidgetCard from '../WidgetCard'

describe('WidgetCard', () => {
  const defaultProps = {
    type: 'course_work_summary',
    displayName: 'Course Work Summary',
    description: 'Shows summary of upcoming assignments and course work',
    onAdd: jest.fn(),
    disabled: false,
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders with correct display name and description', () => {
    render(<WidgetCard {...defaultProps} />)
    expect(screen.getByText('Course Work Summary')).toBeInTheDocument()
    expect(
      screen.getByText('Shows summary of upcoming assignments and course work'),
    ).toBeInTheDocument()
  })

  it('renders with correct data-testid', () => {
    render(<WidgetCard {...defaultProps} />)
    expect(screen.getByTestId('widget-card-course_work_summary')).toBeInTheDocument()
  })

  it('calls onAdd when Add button is clicked', async () => {
    const user = userEvent.setup()
    render(<WidgetCard {...defaultProps} />)

    const addButton = screen.getByRole('button', {name: 'Add'})
    await user.click(addButton)

    expect(defaultProps.onAdd).toHaveBeenCalledTimes(1)
  })

  it('displays "Add" text when not disabled', () => {
    render(<WidgetCard {...defaultProps} disabled={false} />)
    expect(screen.getByRole('button', {name: 'Add'})).toBeInTheDocument()
  })

  it('displays "Added" text when disabled', () => {
    render(<WidgetCard {...defaultProps} disabled={true} />)
    expect(screen.getByRole('button', {name: 'Added'})).toBeInTheDocument()
  })

  it('disables button when disabled prop is true', () => {
    render(<WidgetCard {...defaultProps} disabled={true} />)
    const button = screen.getByRole('button', {name: 'Added'})
    expect(button).toBeDisabled()
  })

  it('does not disable button when disabled prop is false', () => {
    render(<WidgetCard {...defaultProps} disabled={false} />)
    const button = screen.getByRole('button', {name: 'Add'})
    expect(button).not.toBeDisabled()
  })

  it('does not call onAdd when button is disabled', async () => {
    const user = userEvent.setup()
    render(<WidgetCard {...defaultProps} disabled={true} />)

    const addButton = screen.getByRole('button', {name: 'Added'})
    await user.click(addButton)

    expect(defaultProps.onAdd).not.toHaveBeenCalled()
  })

  it('renders icon when not disabled', () => {
    const {container} = render(<WidgetCard {...defaultProps} disabled={false} />)
    const icon = container.querySelector('svg')
    expect(icon).toBeInTheDocument()
  })

  it('does not render icon when disabled', () => {
    const {container} = render(<WidgetCard {...defaultProps} disabled={true} />)
    const icon = container.querySelector('svg')
    expect(icon).not.toBeInTheDocument()
  })
})
