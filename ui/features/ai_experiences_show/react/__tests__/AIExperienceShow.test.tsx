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

import '@instructure/canvas-theme'
import React from 'react'
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import AIExperienceShow from '../components/AIExperienceShow'
import type {AIExperience} from '../../types'

const mockAiExperience: AIExperience = {
  id: '1',
  course_id: 123,
  title: 'Customer Service Training',
  description: 'Practice customer service scenarios',
  facts: 'You are a customer service representative helping customers with billing issues.',
  learning_objective: 'Students will learn to handle customer complaints professionally',
  scenario: 'A customer calls about incorrect billing',
}

describe('AIExperienceShow', () => {
  beforeEach(() => {
    fetchMock.restore()
    // Mock the API call that LLMConversationView makes
    fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', {
      messages: [],
    })
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders AI experience title', () => {
    render(<AIExperienceShow aiExperience={mockAiExperience} />)
    expect(screen.getByText('Customer Service Training')).toBeInTheDocument()
  })

  it('renders AI experience description', () => {
    render(<AIExperienceShow aiExperience={mockAiExperience} />)
    expect(screen.getByText('Practice customer service scenarios')).toBeInTheDocument()
  })

  it('renders configuration section with all fields', () => {
    render(<AIExperienceShow aiExperience={mockAiExperience} />)

    expect(screen.getByText('Configurations')).toBeInTheDocument()
    expect(screen.getByText('Facts students should know')).toBeInTheDocument()
    expect(
      screen.getByText(
        'You are a customer service representative helping customers with billing issues.',
      ),
    ).toBeInTheDocument()
    expect(screen.getByText('Learning objectives')).toBeInTheDocument()
    expect(
      screen.getByText('Students will learn to handle customer complaints professionally'),
    ).toBeInTheDocument()
    expect(screen.getByText('Pedagogical guidance')).toBeInTheDocument()
    expect(screen.getByText('A customer calls about incorrect billing')).toBeInTheDocument()
  })

  it('renders test AI experience button', () => {
    render(<AIExperienceShow aiExperience={mockAiExperience} />)
    expect(screen.getByText('Test AI Experience')).toBeInTheDocument()
  })

  it('opens conversation view when test button is clicked', async () => {
    render(<AIExperienceShow aiExperience={mockAiExperience} />)

    const testButton = screen.getByText('Test AI Experience')
    fireEvent.click(testButton)

    await waitFor(() => {
      expect(screen.getByText('Close and Reset')).toBeInTheDocument()
    })
  })

  it('hides test button when conversation is open', () => {
    render(<AIExperienceShow aiExperience={mockAiExperience} />)

    const testButton = screen.getByText('Test AI Experience')
    fireEvent.click(testButton)

    expect(screen.queryByText('Test AI Experience')).not.toBeInTheDocument()
  })

  it('shows test button again after closing conversation', async () => {
    render(<AIExperienceShow aiExperience={mockAiExperience} />)

    const testButton = screen.getByText('Test AI Experience')
    fireEvent.click(testButton)

    await waitFor(() => {
      expect(screen.getByText('Close and Reset')).toBeInTheDocument()
    })

    const closeButton = screen.getByText('Close and Reset')
    fireEvent.click(closeButton)

    expect(screen.getByText('Test AI Experience')).toBeInTheDocument()
  })

  // Note: Focus management is tested in integration tests
  // jsdom doesn't fully support focus behavior with refs
})
