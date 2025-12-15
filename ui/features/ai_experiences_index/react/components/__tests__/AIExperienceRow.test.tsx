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
import AIExperienceRow from '../AIExperienceRow'

const defaultProps = {
  id: 1,
  title: 'Customer Service Training',
  workflowState: 'published' as const,
  createdAt: '2025-01-15T10:30:00Z',
  onEdit: vi.fn(),
  onTestConversation: vi.fn(),
  onPublishToggle: vi.fn(),
  onDelete: vi.fn(),
}

describe('AIExperienceRow', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders title and formatted creation date', () => {
    render(<AIExperienceRow {...defaultProps} />)

    expect(screen.getByText('Customer Service Training')).toBeInTheDocument()
    expect(screen.getByText(/Created on January 15, 2025/)).toBeInTheDocument()
  })

  it('shows correct publish status', () => {
    const {rerender} = render(<AIExperienceRow {...defaultProps} />)
    expect(screen.getByText('Published')).toBeInTheDocument()

    rerender(<AIExperienceRow {...defaultProps} workflowState="unpublished" />)
    expect(screen.getByText('Not published')).toBeInTheDocument()
  })

  it('calls onPublishToggle with correct state when publish button clicked', async () => {
    const user = userEvent.setup()
    render(<AIExperienceRow {...defaultProps} workflowState="unpublished" />)

    const publishButton = screen.getByTestId('ai-experience-publish-toggle')
    await user.click(publishButton)

    expect(defaultProps.onPublishToggle).toHaveBeenCalledWith(1, 'published')
  })

  it('calls onEdit when edit menu item is clicked', async () => {
    const user = userEvent.setup()
    render(<AIExperienceRow {...defaultProps} />)

    const menuButton = screen.getByTestId('ai-experience-menu')
    await user.click(menuButton)

    const editButton = screen.getByText('Edit')
    await user.click(editButton)
    expect(defaultProps.onEdit).toHaveBeenCalledWith(1)
  })

  it('calls onTestConversation when test conversation menu item is clicked', async () => {
    const user = userEvent.setup()
    render(<AIExperienceRow {...defaultProps} />)

    const menuButton = screen.getByTestId('ai-experience-menu')
    await user.click(menuButton)

    const testButton = screen.getByText('Test Conversation')
    await user.click(testButton)
    expect(defaultProps.onTestConversation).toHaveBeenCalledWith(1)
  })

  it('calls onDelete when delete menu item is clicked', async () => {
    const user = userEvent.setup()
    render(<AIExperienceRow {...defaultProps} />)

    const menuButton = screen.getByTestId('ai-experience-menu')
    await user.click(menuButton)

    const deleteButton = screen.getByText('Delete')
    await user.click(deleteButton)
    expect(defaultProps.onDelete).toHaveBeenCalledWith(1)
  })

  it('title is rendered as a clickable link', () => {
    // Mock ENV.COURSE_ID
    ;(global as any).ENV = {COURSE_ID: 123}

    render(<AIExperienceRow {...defaultProps} />)

    const titleLink = screen.getByText('Customer Service Training')
    expect(titleLink).toHaveAttribute('href', '/courses/123/ai_experiences/1')
  })
})
