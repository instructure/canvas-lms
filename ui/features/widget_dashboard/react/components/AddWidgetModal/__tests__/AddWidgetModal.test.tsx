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
import {type MockedFunction} from 'vitest'
import AddWidgetModal from '../AddWidgetModal'
import {useWidgetLayout} from '../../../hooks/useWidgetLayout'

vi.mock('../../../hooks/useWidgetLayout')

const mockUseWidgetLayout = useWidgetLayout as MockedFunction<typeof useWidgetLayout>

describe('AddWidgetModal', () => {
  const mockAddWidget = vi.fn()
  const defaultProps = {
    open: true,
    onClose: vi.fn(),
    targetColumn: 1,
    targetRow: 2,
  }

  afterEach(() => {
    cleanup()
  })

  beforeEach(() => {
    vi.clearAllMocks()
    mockUseWidgetLayout.mockReturnValue({
      config: {widgets: []},
      addWidget: mockAddWidget,
      moveWidget: vi.fn(),
      moveWidgetToPosition: vi.fn(),
      removeWidget: vi.fn(),
      resetConfig: vi.fn(),
    } as any)
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

    expect(screen.getByTestId('widget-card-course_work_combined')).toBeInTheDocument()
    expect(screen.getByTestId('widget-card-course_grades')).toBeInTheDocument()
    expect(screen.getByTestId('widget-card-announcements')).toBeInTheDocument()
    expect(screen.getByTestId('widget-card-people')).toBeInTheDocument()
    expect(screen.getByTestId('widget-card-todo_list')).toBeInTheDocument()
    expect(screen.getByTestId('widget-card-recent_grades')).toBeInTheDocument()
    expect(screen.getByTestId('widget-card-progress_overview')).toBeInTheDocument()
    expect(screen.getByTestId('widget-card-inbox')).toBeInTheDocument()
  })

  it('displays correct widget display names', () => {
    render(<AddWidgetModal {...defaultProps} />)

    expect(screen.getByText('Course grades')).toBeInTheDocument()
    expect(screen.getByText('Announcements')).toBeInTheDocument()
    expect(screen.getByText('People')).toBeInTheDocument()
    expect(screen.getByText('To-do list')).toBeInTheDocument()
  })

  it('displays correct widget descriptions', () => {
    render(<AddWidgetModal {...defaultProps} />)

    expect(
      screen.getByText('View course work statistics and assignments in one comprehensive view'),
    ).toBeInTheDocument()
    expect(
      screen.getByText('Track your grades and academic progress across all courses'),
    ).toBeInTheDocument()
  })

  it('renders Add buttons for all widgets', () => {
    render(<AddWidgetModal {...defaultProps} />)

    const addButtons = screen.getAllByRole('button', {name: 'Add'})
    expect(addButtons).toHaveLength(8)
  })

  it('calls addWidget with correct parameters when Add button is clicked', async () => {
    const user = userEvent.setup()
    render(<AddWidgetModal {...defaultProps} />)

    const addButtons = screen.getAllByRole('button', {name: 'Add'})
    await user.click(addButtons[0])

    expect(mockAddWidget).toHaveBeenCalledWith(
      expect.any(String),
      expect.any(String),
      defaultProps.targetColumn,
      defaultProps.targetRow,
    )
  })

  it('closes modal after adding widget', async () => {
    const user = userEvent.setup()
    render(<AddWidgetModal {...defaultProps} />)

    const addButtons = screen.getAllByRole('button', {name: 'Add'})
    await user.click(addButtons[0])

    expect(defaultProps.onClose).toHaveBeenCalledTimes(1)
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

  it('disables Add button for widgets already on dashboard', () => {
    mockUseWidgetLayout.mockReturnValue({
      config: {
        widgets: [
          {
            id: 'course_work_combined-widget-1',
            type: 'course_work_combined',
            position: {col: 1, row: 1, relative: 1},
            title: 'Course work combined',
          },
        ],
      },
      addWidget: mockAddWidget,
      moveWidget: vi.fn(),
      moveWidgetToPosition: vi.fn(),
      removeWidget: vi.fn(),
      resetConfig: vi.fn(),
    } as any)

    render(<AddWidgetModal {...defaultProps} />)

    const addedButton = screen.getByRole('button', {name: 'Added'})
    expect(addedButton).toBeDisabled()
  })

  it('enables Add button for widgets not on dashboard', () => {
    mockUseWidgetLayout.mockReturnValue({
      config: {
        widgets: [
          {
            id: 'course_work_combined-widget-1',
            type: 'course_work_combined',
            position: {col: 1, row: 1, relative: 1},
            title: 'Course work combined',
          },
        ],
      },
      addWidget: mockAddWidget,
      moveWidget: vi.fn(),
      moveWidgetToPosition: vi.fn(),
      removeWidget: vi.fn(),
      resetConfig: vi.fn(),
    } as any)

    render(<AddWidgetModal {...defaultProps} />)

    const addButtons = screen.getAllByRole('button', {name: 'Add'})
    addButtons.forEach(button => {
      expect(button).not.toBeDisabled()
    })
  })

  it('does not call addWidget when clicking disabled button', async () => {
    mockUseWidgetLayout.mockReturnValue({
      config: {
        widgets: [
          {
            id: 'course_work_combined-widget-1',
            type: 'course_work_combined',
            position: {col: 1, row: 1, relative: 1},
            title: 'Course work combined',
          },
        ],
      },
      addWidget: mockAddWidget,
      moveWidget: vi.fn(),
      moveWidgetToPosition: vi.fn(),
      removeWidget: vi.fn(),
      resetConfig: vi.fn(),
    } as any)

    const user = userEvent.setup()
    render(<AddWidgetModal {...defaultProps} />)

    const addedButton = screen.getByRole('button', {name: 'Added'})
    await user.click(addedButton)

    expect(mockAddWidget).not.toHaveBeenCalled()
    expect(defaultProps.onClose).not.toHaveBeenCalled()
  })
})
