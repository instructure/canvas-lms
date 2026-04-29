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
import AIExperienceList from '../AIExperienceList'
import type {AiExperience} from '../../types'

const mockExperiences: AiExperience[] = [
  {
    id: 1,
    title: 'Customer Service Training',
    description: 'Practice customer service scenarios',
    workflow_state: 'published',
    facts: 'You are a customer service representative',
    learning_objective: 'Learn to handle complaints',
    pedagogical_guidance: 'A customer calls about billing',
    created_at: '2025-01-15T10:30:00Z',
  },
  {
    id: 2,
    title: 'Sales Simulation',
    description: 'Practice sales techniques',
    workflow_state: 'unpublished',
    facts: 'You are a sales representative',
    learning_objective: 'Learn to close deals',
    pedagogical_guidance: 'A potential customer is interested',
    created_at: '2025-01-10T14:20:00Z',
  },
]

const defaultProps = {
  canManage: true,
  experiences: mockExperiences,
  onEdit: vi.fn(),
  onTestConversation: vi.fn(),
  onPublishToggle: vi.fn(),
  onDelete: vi.fn(),
}

describe('AIExperienceList', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders all experiences passed as props', () => {
    render(<AIExperienceList {...defaultProps} />)

    expect(screen.getByText('Customer Service Training')).toBeInTheDocument()
    expect(screen.getByText('Sales Simulation')).toBeInTheDocument()
  })

  it('displays formatted creation dates', () => {
    render(<AIExperienceList {...defaultProps} />)

    expect(screen.getByText(/Created on January 15, 2025/)).toBeInTheDocument()
    expect(screen.getByText(/Created on January 10, 2025/)).toBeInTheDocument()
  })

  it('shows correct publish status for each experience', () => {
    render(<AIExperienceList {...defaultProps} />)

    expect(screen.getByText('Published')).toBeInTheDocument()
    expect(screen.getByText('Not published')).toBeInTheDocument()
  })

  it('calls onEdit when edit menu item is clicked', async () => {
    const user = userEvent.setup()
    render(<AIExperienceList {...defaultProps} />)

    // Click the menu button for the first experience
    const menuButtons = screen.getAllByTestId('ai-experience-menu')
    await user.click(menuButtons[0])

    // Click the Edit menu item
    const editButton = screen.getByText('Edit')
    await user.click(editButton)

    expect(defaultProps.onEdit).toHaveBeenCalledWith(1)
  })

  it('calls onTestConversation when test conversation menu item is clicked', async () => {
    const user = userEvent.setup()
    render(<AIExperienceList {...defaultProps} />)

    // Click the menu button for the first experience
    const menuButtons = screen.getAllByTestId('ai-experience-menu')
    await user.click(menuButtons[0])

    // Click the Test Conversation menu item
    const testButton = screen.getByText('Test Conversation')
    await user.click(testButton)

    expect(defaultProps.onTestConversation).toHaveBeenCalledWith(1)
  })

  it('calls onPublishToggle when publish button is clicked', async () => {
    const user = userEvent.setup()
    render(<AIExperienceList {...defaultProps} />)

    // Click the publish button for the unpublished experience (second one)
    const publishButtons = screen.getAllByTestId('ai-experience-publish-toggle')
    await user.click(publishButtons[1]) // Second experience is unpublished

    expect(defaultProps.onPublishToggle).toHaveBeenCalledWith(2, 'published')
  })

  it('calls onPublishToggle with unpublished when unpublish button is clicked', async () => {
    const user = userEvent.setup()
    render(<AIExperienceList {...defaultProps} />)

    // Click the unpublish button for the published experience (first one)
    const publishButtons = screen.getAllByTestId('ai-experience-publish-toggle')
    await user.click(publishButtons[0]) // First experience is published

    expect(defaultProps.onPublishToggle).toHaveBeenCalledWith(1, 'unpublished')
  })

  it('calls onDelete when delete menu item is clicked', async () => {
    const user = userEvent.setup()
    render(<AIExperienceList {...defaultProps} />)

    // Click the menu button for the first experience
    const menuButtons = screen.getAllByTestId('ai-experience-menu')
    await user.click(menuButtons[0])

    // Click the Delete menu item
    const deleteButton = screen.getByText('Delete')
    await user.click(deleteButton)

    expect(defaultProps.onDelete).toHaveBeenCalledWith(1)
  })

  it('renders empty list when no experiences provided', () => {
    render(<AIExperienceList {...defaultProps} experiences={[]} />)

    expect(screen.queryByText('Customer Service Training')).not.toBeInTheDocument()
    expect(screen.queryByText('Sales Simulation')).not.toBeInTheDocument()
  })
})
