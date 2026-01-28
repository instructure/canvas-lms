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
import CreateTodoModal from '../CreateTodoModal'

describe('CreateTodoModal', () => {
  const defaultProps = {
    open: true,
    onDismiss: vi.fn(),
    onSubmit: vi.fn(),
    isCreating: false,
    courses: [
      {id: '1', longName: 'Test Course 1', enrollmentType: 'StudentEnrollment'},
      {id: '2', longName: 'Test Course 2', is_student: true},
    ],
    locale: 'en',
    timeZone: 'America/Denver',
  }

  afterEach(() => {
    cleanup()
  })

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders modal when open is true', () => {
    render(<CreateTodoModal {...defaultProps} />)
    expect(screen.getByText('Add To Do')).toBeInTheDocument()
  })

  it('does not render modal when open is false', () => {
    render(<CreateTodoModal {...defaultProps} open={false} />)
    expect(screen.queryByText('Add To Do')).not.toBeInTheDocument()
  })

  it('renders all form fields', () => {
    render(<CreateTodoModal {...defaultProps} />)
    expect(screen.getByTestId('create-todo-title-input')).toBeInTheDocument()
    expect(screen.getByTestId('create-todo-date-input')).toBeInTheDocument()
    expect(screen.getByTestId('create-todo-course-select')).toBeInTheDocument()
    expect(screen.getByTestId('create-todo-details-input')).toBeInTheDocument()
  })

  it('disables submit button when form is empty', () => {
    render(<CreateTodoModal {...defaultProps} />)
    const submitButton = screen.getByTestId('create-todo-submit-button')
    expect(submitButton).toHaveAttribute('disabled')
  })

  it('renders cancel button', () => {
    render(<CreateTodoModal {...defaultProps} />)
    expect(screen.getByTestId('create-todo-cancel-button')).toBeInTheDocument()
  })

  it('renders close button', () => {
    render(<CreateTodoModal {...defaultProps} />)
    expect(screen.getByTestId('create-todo-close-button')).toBeInTheDocument()
  })

  it('calls onDismiss when cancel button is clicked', async () => {
    const user = userEvent.setup()
    render(<CreateTodoModal {...defaultProps} />)

    const cancelButton = screen.getByTestId('create-todo-cancel-button')
    await user.click(cancelButton)

    expect(defaultProps.onDismiss).toHaveBeenCalled()
  })

  it('shows "Creating..." text on submit button when isCreating is true', () => {
    render(<CreateTodoModal {...defaultProps} isCreating={true} />)
    expect(screen.getByTestId('create-todo-submit-button')).toHaveTextContent('Creating...')
  })

  it('disables submit button when isCreating is true', () => {
    render(<CreateTodoModal {...defaultProps} isCreating={true} />)
    const submitButton = screen.getByTestId('create-todo-submit-button')
    expect(submitButton).toHaveAttribute('disabled')
  })

  it('disables cancel button when isCreating is true', () => {
    render(<CreateTodoModal {...defaultProps} isCreating={true} />)
    const cancelButton = screen.getByTestId('create-todo-cancel-button')
    expect(cancelButton).toHaveAttribute('disabled')
  })

  it('renders course selector with courses', () => {
    render(<CreateTodoModal {...defaultProps} />)
    expect(screen.getByTestId('create-todo-course-select')).toBeInTheDocument()
  })

  it('resets form after successful submission', async () => {
    const user = userEvent.setup()
    render(<CreateTodoModal {...defaultProps} />)

    const titleInput = screen.getByLabelText('Title') as HTMLInputElement
    const detailsInput = screen.getByLabelText('Details') as HTMLTextAreaElement

    await user.clear(titleInput)
    await user.type(titleInput, 'Test Todo')
    await user.clear(detailsInput)
    await user.type(detailsInput, 'Test Details')

    const submitButton = screen.getByTestId('create-todo-submit-button')
    await user.click(submitButton)

    expect(defaultProps.onSubmit).toHaveBeenCalledWith({
      title: 'Test Todo',
      todo_date: expect.any(String),
      details: 'Test Details',
      course_id: undefined,
    })
  })

  it('enforces maximum length on title input', async () => {
    const user = userEvent.setup()
    render(<CreateTodoModal {...defaultProps} />)

    const titleInput = screen.getByLabelText('Title') as HTMLInputElement

    expect(titleInput).toHaveAttribute('maxlength', '255')
  })
})
