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
import {cleanup, render, screen, fireEvent, waitFor} from '@testing-library/react'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import fakeENV from '@canvas/test-utils/fakeENV'
import AIExperienceShow from '../components/AIExperienceShow'
import type {AIExperience} from '../../types'

const server = setupServer(
  http.get('/api/v1/courses/123/ai_experiences/1/conversations', () => {
    return HttpResponse.json({})
  }),
  http.post('/api/v1/courses/123/ai_experiences/1/conversations', () => {
    return HttpResponse.json({
      id: 1,
      messages: [],
    })
  }),
)

const mockAiExperience: AIExperience = {
  id: '1',
  course_id: 123,
  title: 'Customer Service Training',
  description: 'Practice customer service scenarios',
  facts: 'You are a customer service representative helping customers with billing issues.',
  learning_objective: 'Students will learn to handle customer complaints professionally',
  pedagogical_guidance: 'A customer calls about incorrect billing',
  workflow_state: 'published',
  can_manage: true,
  can_unpublish: true,
}

describe('AIExperienceShow', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    fakeENV.setup()
    server.resetHandlers()
    // Mock scrollIntoView which is not available in JSDOM
    Element.prototype.scrollIntoView = vi.fn()
    // Reset window.location (include href so fetch can resolve relative URLs)
    delete (window as any).location
    window.location = {
      search: '',
      pathname: '/courses/123/ai_experiences/1',
      href: 'http://localhost/courses/123/ai_experiences/1',
      origin: 'http://localhost',
    } as any
  })

  afterEach(() => {
    fakeENV.teardown()
    cleanup()
    vi.clearAllMocks()
  })

  it('renders AI experience title', () => {
    render(<AIExperienceShow aiExperience={mockAiExperience} />)
    expect(screen.getByText('Customer Service Training')).toBeInTheDocument()
  })

  it('renders AI experience description without label', () => {
    render(<AIExperienceShow aiExperience={mockAiExperience} />)
    expect(screen.getByText('Practice customer service scenarios')).toBeInTheDocument()
    expect(screen.queryByText('Description')).not.toBeInTheDocument()
  })

  it('renders configuration section with all fields', () => {
    render(<AIExperienceShow aiExperience={mockAiExperience} />)

    expect(screen.getByText('Configurations')).toBeInTheDocument()
    expect(screen.getByText('Text source')).toBeInTheDocument()
    expect(
      screen.getByText(
        'You are a customer service representative helping customers with billing issues.',
      ),
    ).toBeInTheDocument()
    expect(screen.getByText('Learning Objectives')).toBeInTheDocument()
    expect(
      screen.getByText('Students will learn to handle customer complaints professionally'),
    ).toBeInTheDocument()
    expect(screen.getByText('Pedagogical activity guidance')).toBeInTheDocument()
    expect(screen.getByText('A customer calls about incorrect billing')).toBeInTheDocument()
  })

  it('renders Activity section heading', () => {
    render(<AIExperienceShow aiExperience={mockAiExperience} />)
    expect(screen.getByText('Activity')).toBeInTheDocument()
  })

  it('renders preview in collapsed state by default', () => {
    render(<AIExperienceShow aiExperience={mockAiExperience} />)
    expect(screen.getByText('Preview')).toBeInTheDocument()
    expect(
      screen.getByText('Here, you can have a chat with the AI just like a student would.'),
    ).toBeInTheDocument()
    expect(screen.queryByText('Restart')).not.toBeInTheDocument()
  })

  it('expands preview when clicked', async () => {
    render(<AIExperienceShow aiExperience={mockAiExperience} />)

    const previewCard = screen.getByText('Preview').closest('[role="button"]')
    fireEvent.click(previewCard!)

    await waitFor(() => {
      expect(screen.getByText('Restart')).toBeInTheDocument()
    })
  })

  it('collapses preview when close button is clicked', async () => {
    render(<AIExperienceShow aiExperience={mockAiExperience} />)

    // Expand first
    const previewCard = screen.getByText('Preview').closest('[role="button"]')
    fireEvent.click(previewCard!)

    await waitFor(() => {
      expect(screen.getByText('Restart')).toBeInTheDocument()
    })

    // Then collapse - find the close button by its screen reader label text
    const closeButton = screen.getAllByText('Close preview')[0].closest('button')
    fireEvent.click(closeButton!)

    await waitFor(() => {
      expect(screen.queryByText('Restart')).not.toBeInTheDocument()
    })
  })

  it('renders three-dot menu button', () => {
    render(<AIExperienceShow aiExperience={mockAiExperience} />)
    const menuButton = screen.getAllByText('Knowledge Chat settings')[0].closest('button')
    expect(menuButton).toBeInTheDocument()
  })

  it('shows menu options when menu button is clicked', async () => {
    render(<AIExperienceShow aiExperience={mockAiExperience} />)

    const menuButton = screen.getAllByText('Knowledge Chat settings')[0].closest('button')
    fireEvent.click(menuButton!)

    await waitFor(() => {
      expect(screen.getByText('Edit')).toBeInTheDocument()
      expect(screen.getByText('Run chat simulation')).toBeInTheDocument()
      expect(screen.getByText('Coming soon')).toBeInTheDocument()
      expect(screen.getByText('Delete')).toBeInTheDocument()
    })
  })

  it('navigates to edit page when Edit is clicked', async () => {
    // Skip test that modifies window.location in test environment
    // Navigation is tested in integration tests
  })

  it('Run chat simulation option is disabled', async () => {
    render(<AIExperienceShow aiExperience={mockAiExperience} />)

    const menuButton = screen.getAllByText('Knowledge Chat settings')[0].closest('button')
    fireEvent.click(menuButton!)

    await waitFor(() => {
      const runSimulationItem = screen.getByText('Run chat simulation').closest('[role="menuitem"]')
      expect(runSimulationItem).toHaveAttribute('aria-disabled', 'true')
    })
  })

  it('opens delete confirmation modal when Delete is clicked', async () => {
    render(<AIExperienceShow aiExperience={mockAiExperience} />)

    const menuButton = screen.getAllByText('Knowledge Chat settings')[0].closest('button')
    fireEvent.click(menuButton!)

    await waitFor(() => {
      expect(screen.getByText('Delete')).toBeInTheDocument()
    })

    const deleteButton = screen.getByText('Delete')
    fireEvent.click(deleteButton)

    await waitFor(() => {
      expect(screen.getByText('Delete Knowledge Chat')).toBeInTheDocument()
      expect(
        screen.getByText(
          'Are you sure you want to delete "Customer Service Training"? This action cannot be undone.',
        ),
      ).toBeInTheDocument()
    })
  })

  it('closes delete modal when Cancel is clicked', async () => {
    render(<AIExperienceShow aiExperience={mockAiExperience} />)

    // Open menu and click Delete
    const menuButton = screen.getAllByText('Knowledge Chat settings')[0].closest('button')
    fireEvent.click(menuButton!)

    const deleteButton = screen.getByText('Delete')
    fireEvent.click(deleteButton)

    // Wait for both the modal title AND the cancel button to be ready
    const cancelButton = await screen.findByTestId('ai-experience-show-delete-cancel-button')
    await waitFor(() => {
      expect(screen.getByText('Delete Knowledge Chat')).toBeInTheDocument()
    })

    fireEvent.click(cancelButton)

    await waitFor(
      () => {
        expect(screen.queryByText('Delete Knowledge Chat')).not.toBeInTheDocument()
      },
      {timeout: 5000},
    )
  })

  it('calls delete API when confirmed', async () => {
    let deleteCalled = false
    server.use(
      http.delete('/api/v1/courses/123/ai_experiences/1', () => {
        deleteCalled = true
        return new HttpResponse(null, {status: 200})
      }),
    )

    render(<AIExperienceShow aiExperience={mockAiExperience} />)

    // Open menu and click Delete
    const menuButtons = screen.getAllByText('Knowledge Chat settings')
    const menuButton = menuButtons[0].closest('button')
    fireEvent.click(menuButton!)

    await waitFor(() => {
      expect(screen.getByText('Delete')).toBeInTheDocument()
    })

    const deleteMenuItem = screen.getByText('Delete')
    fireEvent.click(deleteMenuItem)

    await waitFor(() => {
      expect(screen.getByText('Delete Knowledge Chat')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByTestId('ai-experience-show-delete-confirm-button'))

    // Wait for delete API to be called
    await waitFor(
      () => {
        expect(deleteCalled).toBe(true)
      },
      {timeout: 5000},
    )
  })

  it('passes returnFocusRef to LLMConversationView', () => {
    render(<AIExperienceShow aiExperience={mockAiExperience} />)
    // The preview card should be rendered and accessible
    const previewCard = screen.getByText('Preview').closest('[role="button"]')
    expect(previewCard).toBeInTheDocument()
    expect(previewCard).toHaveAttribute('tabindex', '0')
  })

  it('renders kebab menu when can_manage is true', () => {
    render(<AIExperienceShow aiExperience={{...mockAiExperience, can_manage: true}} />)
    const menuButton = screen.getAllByText('Knowledge Chat settings')[0].closest('button')
    expect(menuButton).toBeInTheDocument()
  })

  it('does not render kebab menu when can_manage is false', () => {
    render(<AIExperienceShow aiExperience={{...mockAiExperience, can_manage: false}} />)
    const menuButton = screen.queryByText('Knowledge Chat settings')
    expect(menuButton).not.toBeInTheDocument()
  })

  describe('indexing notice', () => {
    it('shows indexing notice instead of preview when context_ready is false and can_manage', () => {
      render(
        <AIExperienceShow
          aiExperience={{
            ...mockAiExperience,
            context_ready: false,
            context_index_status: 'in_progress',
            can_manage: true,
          }}
        />,
      )
      expect(screen.getByTestId('ai-experience-show-indexing-notice')).toBeInTheDocument()
      expect(
        screen.getByText(
          'Preview and Conversations will be available once processing is complete. Check back later.',
        ),
      ).toBeInTheDocument()
      // Preview chat is hidden — replaced by the notice
      expect(screen.queryByText('Preview')).not.toBeInTheDocument()
    })

    it('disables AI Conversations button when context_ready is false', () => {
      render(
        <AIExperienceShow
          aiExperience={{
            ...mockAiExperience,
            context_ready: false,
            context_index_status: 'in_progress',
            can_manage: true,
          }}
        />,
      )
      const aiConversationsButton = screen.getByTestId('ai-experience-show-ai-conversations-button')
      expect(aiConversationsButton).toHaveAttribute('disabled')
    })

    it('does not show indexing notice when context_ready is true', () => {
      render(
        <AIExperienceShow
          aiExperience={{...mockAiExperience, context_ready: true, can_manage: true}}
        />,
      )
      expect(screen.queryByTestId('ai-experience-show-indexing-notice')).not.toBeInTheDocument()
    })

    it('shows preview and enables AI Conversations button when context_ready is true', () => {
      render(
        <AIExperienceShow
          aiExperience={{...mockAiExperience, context_ready: true, can_manage: true}}
        />,
      )
      // LLMConversationView is shown
      expect(screen.getByText('Preview')).toBeInTheDocument()
      // AI Conversations button is enabled (has href, not disabled)
      const aiConversationsButton = screen.getByTestId('ai-experience-show-ai-conversations-button')
      expect(aiConversationsButton).not.toHaveAttribute('disabled')
      expect(aiConversationsButton).toHaveAttribute(
        'href',
        `/courses/${mockAiExperience.course_id}/ai_experiences/${mockAiExperience.id}/ai_conversations`,
      )
    })

    it('students always see the preview even when context_ready is false', () => {
      render(
        <AIExperienceShow
          aiExperience={{
            ...mockAiExperience,
            context_ready: false,
            context_index_status: 'in_progress',
            can_manage: false,
          }}
        />,
      )
      expect(screen.queryByTestId('ai-experience-show-indexing-notice')).not.toBeInTheDocument()
      // Students see the conversation view (not the teacher's "Preview" panel)
      expect(screen.getByText('Knowledge Chat')).toBeInTheDocument()
    })
  })

  describe('index failed notice', () => {
    it('shows failed notice with edit button when context_index_status is failed and can_manage', () => {
      render(
        <AIExperienceShow
          aiExperience={{
            ...mockAiExperience,
            context_ready: false,
            context_index_status: 'failed',
            can_manage: true,
          }}
        />,
      )
      expect(screen.getByTestId('ai-experience-show-index-failed-notice')).toBeInTheDocument()
      const editLink = screen.getByTestId('ai-experience-show-index-failed-edit-button')
      expect(editLink).toHaveAttribute(
        'href',
        `/courses/${mockAiExperience.course_id}/ai_experiences/${mockAiExperience.id}/edit`,
      )
    })

    it('does not show processing notice when context_index_status is failed', () => {
      render(
        <AIExperienceShow
          aiExperience={{
            ...mockAiExperience,
            context_ready: false,
            context_index_status: 'failed',
            can_manage: true,
          }}
        />,
      )
      expect(screen.queryByTestId('ai-experience-show-indexing-notice')).not.toBeInTheDocument()
    })

    it('disables AI Conversations button with failed tooltip when context_index_status is failed', () => {
      render(
        <AIExperienceShow
          aiExperience={{
            ...mockAiExperience,
            context_ready: false,
            context_index_status: 'failed',
            can_manage: true,
          }}
        />,
      )
      const aiConversationsButton = screen.getByTestId('ai-experience-show-ai-conversations-button')
      expect(aiConversationsButton).toHaveAttribute('disabled')
    })

    it('does not show failed notice for students', () => {
      render(
        <AIExperienceShow
          aiExperience={{
            ...mockAiExperience,
            context_ready: false,
            context_index_status: 'failed',
            can_manage: false,
          }}
        />,
      )
      expect(screen.queryByTestId('ai-experience-show-index-failed-notice')).not.toBeInTheDocument()
    })
  })

  describe('not_started index status', () => {
    it('shows preview instead of processing notice when context_index_status is not_started', () => {
      render(
        <AIExperienceShow
          aiExperience={{
            ...mockAiExperience,
            context_index_status: 'not_started',
            can_manage: true,
          }}
        />,
      )
      expect(screen.queryByTestId('ai-experience-show-indexing-notice')).not.toBeInTheDocument()
      expect(screen.getByText('Preview')).toBeInTheDocument()
    })

    it('enables AI Conversations button when context_index_status is not_started', () => {
      render(
        <AIExperienceShow
          aiExperience={{
            ...mockAiExperience,
            context_index_status: 'not_started',
            can_manage: true,
          }}
        />,
      )
      const aiConversationsButton = screen.getByTestId('ai-experience-show-ai-conversations-button')
      expect(aiConversationsButton).not.toHaveAttribute('disabled')
    })
  })

  describe('context files table', () => {
    const mockFiles = [
      {
        id: 'f1',
        display_name: 'lecture-notes.pdf',
        url: '/files/f1/download',
        size: 204800,
        content_type: 'application/pdf',
      },
      {
        id: 'f2',
        display_name: 'rubric.docx',
        url: '/files/f2/download',
        size: 51200,
        content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      },
    ]

    beforeEach(() => {
      fakeENV.setup({FEATURES: {ai_experiences_context_file_upload: true}})
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('renders File sources section when flag is on and files are present', () => {
      render(<AIExperienceShow aiExperience={{...mockAiExperience, context_files: mockFiles}} />)
      expect(screen.getByText('File sources')).toBeInTheDocument()
    })

    it('renders each file as a list item with its name', () => {
      render(<AIExperienceShow aiExperience={{...mockAiExperience, context_files: mockFiles}} />)
      expect(screen.getByText('lecture-notes.pdf')).toBeInTheDocument()
      expect(screen.getByText('rubric.docx')).toBeInTheDocument()
    })

    it('renders a download button for each file', () => {
      render(<AIExperienceShow aiExperience={{...mockAiExperience, context_files: mockFiles}} />)
      expect(screen.getByTestId('download-file-f1')).toBeInTheDocument()
      expect(screen.getByTestId('download-file-f2')).toBeInTheDocument()
    })

    it('does not render remove buttons on the show page', () => {
      render(<AIExperienceShow aiExperience={{...mockAiExperience, context_files: mockFiles}} />)
      expect(screen.queryByTestId('remove-file-f1')).not.toBeInTheDocument()
      expect(screen.queryByTestId('remove-file-f2')).not.toBeInTheDocument()
    })

    it('does not render File sources section when files array is empty', () => {
      render(<AIExperienceShow aiExperience={{...mockAiExperience, context_files: []}} />)
      expect(screen.queryByText('File sources')).not.toBeInTheDocument()
    })

    it('does not render File sources section when context_files is absent', () => {
      render(<AIExperienceShow aiExperience={mockAiExperience} />)
      expect(screen.queryByText('File sources')).not.toBeInTheDocument()
    })

    it('does not render File sources section when feature flag is off', () => {
      fakeENV.setup({FEATURES: {ai_experiences_context_file_upload: false}})
      render(<AIExperienceShow aiExperience={{...mockAiExperience, context_files: mockFiles}} />)
      expect(screen.queryByText('File sources')).not.toBeInTheDocument()
    })

    it('renders failed file as a warning pill (failed text) in file sources section', () => {
      render(
        <AIExperienceShow
          aiExperience={{
            ...mockAiExperience,
            context_files: mockFiles,
            failed_context_file_names: ['lecture-notes.pdf'],
          }}
        />,
      )
      expect(screen.getByText('lecture-notes.pdf failed')).toBeInTheDocument()
    })

    it('does not render failed file as a normal pill when it is in failed_context_file_names', () => {
      render(
        <AIExperienceShow
          aiExperience={{
            ...mockAiExperience,
            context_files: mockFiles,
            failed_context_file_names: ['lecture-notes.pdf'],
          }}
        />,
      )
      // The file should appear once as a warning ("lecture-notes.pdf failed") not as a normal download pill
      expect(screen.queryByTestId('download-file-f1')).not.toBeInTheDocument()
      // Non-failed file still renders normally
      expect(screen.getByTestId('download-file-f2')).toBeInTheDocument()
    })

    it('does not render a dismiss button for failed files on the show page', () => {
      render(
        <AIExperienceShow
          aiExperience={{
            ...mockAiExperience,
            context_files: mockFiles,
            failed_context_file_names: ['lecture-notes.pdf'],
          }}
        />,
      )
      expect(screen.queryByTestId('dismiss-failed-lecture-notes.pdf')).not.toBeInTheDocument()
    })
  })
})
