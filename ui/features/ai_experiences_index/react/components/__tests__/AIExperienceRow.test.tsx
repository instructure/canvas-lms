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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import AIExperienceRow from '../AIExperienceRow'

const defaultProps = {
  canManage: true,
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
    global.fetch = vi.fn()
    ;(global as any).ENV = {COURSE_ID: 123}
  })

  afterEach(() => {
    vi.restoreAllMocks()
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

  describe('Teacher view (canManage = true)', () => {
    it('shows published status text', () => {
      render(<AIExperienceRow {...defaultProps} workflowState="published" />)
      expect(screen.getByText('Published')).toBeInTheDocument()
    })

    it('shows unpublished status text', () => {
      render(<AIExperienceRow {...defaultProps} workflowState="unpublished" />)
      expect(screen.getByText('Not published')).toBeInTheDocument()
    })

    it('shows publish/unpublish button', () => {
      render(<AIExperienceRow {...defaultProps} />)
      expect(screen.getByTestId('ai-experience-publish-toggle')).toBeInTheDocument()
    })

    it('shows kebab menu', () => {
      render(<AIExperienceRow {...defaultProps} />)
      expect(screen.getByTestId('ai-experience-menu')).toBeInTheDocument()
    })

    it('kebab menu has Edit, Test Conversation, and Delete options', async () => {
      const user = userEvent.setup()
      render(<AIExperienceRow {...defaultProps} />)

      const menuButton = screen.getByTestId('ai-experience-menu')
      await user.click(menuButton)

      expect(screen.getByText('Edit')).toBeInTheDocument()
      expect(screen.getByText('Test Conversation')).toBeInTheDocument()
      expect(screen.getByText('Delete')).toBeInTheDocument()
    })
  })

  describe('Student view (canManage = false)', () => {
    const studentProps = {...defaultProps, canManage: false}

    it('does not show published status text', () => {
      render(<AIExperienceRow {...studentProps} workflowState="published" />)
      expect(screen.queryByText('Published')).not.toBeInTheDocument()
    })

    it('does not show unpublished status text', () => {
      render(<AIExperienceRow {...studentProps} workflowState="unpublished" />)
      expect(screen.queryByText('Not published')).not.toBeInTheDocument()
    })

    it('does not show publish/unpublish button', () => {
      render(<AIExperienceRow {...studentProps} />)
      expect(screen.queryByTestId('ai-experience-publish-toggle')).not.toBeInTheDocument()
    })

    it('does not show kebab menu', () => {
      render(<AIExperienceRow {...studentProps} />)
      expect(screen.queryByTestId('ai-experience-menu')).not.toBeInTheDocument()
    })

    it('title link is still clickable', () => {
      ;(global as any).ENV = {COURSE_ID: 123}
      render(<AIExperienceRow {...studentProps} />)

      const titleLink = screen.getByText('Customer Service Training')
      expect(titleLink).toHaveAttribute('href', '/courses/123/ai_experiences/1')
    })

    it('still shows creation date', () => {
      render(<AIExperienceRow {...studentProps} />)
      expect(screen.getByText(/Created on January 15, 2025/)).toBeInTheDocument()
    })

    it('displays Not Started pill when submission_status is not_started', () => {
      render(<AIExperienceRow {...studentProps} submissionStatus="not_started" />)
      expect(screen.getByText('Not Started')).toBeInTheDocument()
    })

    it('displays spinner then In Progress pill with percentage when submission_status is in_progress', async () => {
      ;(global.fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => ({progress: {percentage: 35}}),
      })

      render(<AIExperienceRow {...studentProps} submissionStatus="in_progress" />)

      // Initially shows spinner
      expect(screen.getByTitle('Loading progress')).toBeInTheDocument()

      // After fetch, shows pill with percentage
      await waitFor(() => {
        expect(screen.getByText('In Progress (35%)')).toBeInTheDocument()
      })

      // Spinner should be gone
      expect(screen.queryByTitle('Loading progress')).not.toBeInTheDocument()
    })

    it('displays In Progress with 0% when fetch fails', async () => {
      ;(global.fetch as any).mockRejectedValueOnce(new Error('Network error'))

      render(<AIExperienceRow {...studentProps} submissionStatus="in_progress" />)

      // Initially shows spinner
      expect(screen.getByTitle('Loading progress')).toBeInTheDocument()

      // After failed fetch, shows pill with 0%
      await waitFor(() => {
        expect(screen.getByText('In Progress (0%)')).toBeInTheDocument()
      })
    })

    it('displays In Progress with 0% when progress data is missing', async () => {
      ;(global.fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => ({}),
      })

      render(<AIExperienceRow {...studentProps} submissionStatus="in_progress" />)

      await waitFor(() => {
        expect(screen.getByText('In Progress (0%)')).toBeInTheDocument()
      })
    })

    it('displays Submitted pill when submission_status is submitted', () => {
      render(<AIExperienceRow {...studentProps} submissionStatus="submitted" />)
      expect(screen.getByText('Submitted')).toBeInTheDocument()
    })

    it('does not display pill when submission_status is undefined', () => {
      render(<AIExperienceRow {...studentProps} />)
      expect(screen.queryByText('Not Started')).not.toBeInTheDocument()
      expect(screen.queryByText(/In Progress/)).not.toBeInTheDocument()
      expect(screen.queryByText('Submitted')).not.toBeInTheDocument()
    })
  })

  describe('Teacher view with submission status', () => {
    it('never displays submission status pill even when provided', () => {
      render(<AIExperienceRow {...defaultProps} submissionStatus="not_started" />)
      expect(screen.queryByText('Not Started')).not.toBeInTheDocument()
    })
  })
})
