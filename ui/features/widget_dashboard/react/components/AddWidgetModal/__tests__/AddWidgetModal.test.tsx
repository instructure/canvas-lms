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
import AddWidgetModal from '../AddWidgetModal'

describe('AddWidgetModal', () => {
  const defaultProps = {
    open: true,
    onClose: jest.fn(),
    targetColumn: 1,
    targetRow: 2,
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders when open is true', () => {
    render(<AddWidgetModal {...defaultProps} />)
    expect(screen.getByTestId('add-widget-modal')).toBeInTheDocument()
  })

  it('does not render when open is false', () => {
    render(<AddWidgetModal {...defaultProps} open={false} />)
    expect(screen.queryByTestId('add-widget-modal')).not.toBeInTheDocument()
  })

  it('displays the correct heading', () => {
    render(<AddWidgetModal {...defaultProps} />)
    expect(screen.getByTestId('modal-heading')).toHaveTextContent('Add widget')
  })

  it('displays all available widgets from registry', () => {
    render(<AddWidgetModal {...defaultProps} />)

    expect(screen.getByTestId('widget-card-course_work_summary')).toBeInTheDocument()
    expect(screen.getByTestId('widget-card-course_work')).toBeInTheDocument()
    expect(screen.getByTestId('widget-card-course_work_combined')).toBeInTheDocument()
    expect(screen.getByTestId('widget-card-course_grades')).toBeInTheDocument()
    expect(screen.getByTestId('widget-card-announcements')).toBeInTheDocument()
    expect(screen.getByTestId('widget-card-people')).toBeInTheDocument()
    expect(screen.getByTestId('widget-card-todo_list')).toBeInTheDocument()
  })

  it('displays correct widget display names', () => {
    render(<AddWidgetModal {...defaultProps} />)

    expect(screen.getByText("Today's course work")).toBeInTheDocument()
    expect(screen.getByText('Course work')).toBeInTheDocument()
    expect(screen.getByText('Course grades')).toBeInTheDocument()
    expect(screen.getByText('Announcements')).toBeInTheDocument()
  })

  it('displays correct widget descriptions', () => {
    render(<AddWidgetModal {...defaultProps} />)

    expect(
      screen.getByText('Shows summary of upcoming assignments and course work'),
    ).toBeInTheDocument()
    expect(
      screen.getByText('Track your grades and academic progress across all courses'),
    ).toBeInTheDocument()
  })

  it('renders Add buttons for all widgets', () => {
    render(<AddWidgetModal {...defaultProps} />)

    const addButtons = screen.getAllByRole('button', {name: 'Add'})
    expect(addButtons).toHaveLength(7)
  })

  it('logs to console when Add button is clicked', async () => {
    const consoleSpy = jest.spyOn(console, 'log').mockImplementation()
    const user = userEvent.setup()
    render(<AddWidgetModal {...defaultProps} />)

    const addButtons = screen.getAllByRole('button', {name: 'Add'})
    await user.click(addButtons[0])

    expect(consoleSpy).toHaveBeenCalled()
    expect(consoleSpy.mock.calls[0][0]).toBe('Add widget:')

    consoleSpy.mockRestore()
  })

  it('calls onClose when close button is clicked', async () => {
    const user = userEvent.setup()
    render(<AddWidgetModal {...defaultProps} />)

    const closeButton = screen.getByTestId('close-button').querySelector('button')
    if (!closeButton) throw new Error('Close button not found')
    await user.click(closeButton)

    expect(defaultProps.onClose).toHaveBeenCalledTimes(1)
  })

  it('has correct accessibility attributes', () => {
    render(<AddWidgetModal {...defaultProps} />)
    const modal = screen.getByTestId('add-widget-modal')
    expect(modal).toHaveAttribute('aria-label', 'Add widget')
  })
})
