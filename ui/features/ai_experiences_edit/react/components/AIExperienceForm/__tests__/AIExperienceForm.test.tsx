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
import AIExperienceForm from '../AIExperienceForm'
import type {AIExperience} from '../../../../types'

const server = setupServer()

const mockAiExperience: AIExperience = {
  id: '1',
  title: 'Test Experience',
  description: 'Test Description',
  facts: 'Test Facts',
  learning_objective: 'Test Objectives',
  pedagogical_guidance: 'Test Pedagogical Guidance',
  workflow_state: 'unpublished',
}

describe('AIExperienceForm', () => {
  const mockOnSubmit = vi.fn()
  const mockOnCancel = vi.fn()

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  afterEach(() => {
    server.resetHandlers()
    cleanup()
  })

  beforeEach(() => {
    vi.clearAllMocks()
    // @ts-expect-error
    window.ENV = {COURSE_ID: 123}
  })

  describe('rendering', () => {
    it('renders form for new AI experience', () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)
      expect(screen.getByText('New AI Experience')).toBeInTheDocument()
    })

    it('renders form for editing AI experience', () => {
      render(
        <AIExperienceForm
          aiExperience={mockAiExperience}
          onSubmit={mockOnSubmit}
          isLoading={false}
        />,
      )
      expect(screen.getByText('Edit AI Experience')).toBeInTheDocument()
    })

    it('renders all form fields', () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      expect(screen.getByLabelText(/Title/)).toBeInTheDocument()
      expect(screen.getByLabelText(/Description/)).toBeInTheDocument()
      expect(screen.getByLabelText(/Facts students should know/)).toBeInTheDocument()
      expect(screen.getByLabelText(/Learning objectives/)).toBeInTheDocument()
      expect(screen.getByLabelText(/Pedagogical guidance/)).toBeInTheDocument()
    })

    it('renders configuration section with gradient header', () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      expect(screen.getByText('Configurations')).toBeInTheDocument()
      expect(screen.getByText('Learning design')).toBeInTheDocument()
      expect(
        screen.getByText('What should students know and how should the AI behave?'),
      ).toBeInTheDocument()
    })

    it('renders action buttons', () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      expect(screen.getByText('Cancel')).toBeInTheDocument()
      expect(screen.getByText('Preview')).toBeInTheDocument()
      expect(screen.getByText('Save as draft')).toBeInTheDocument()
    })

    it('renders not published status', () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)
      expect(screen.getByText('Not published')).toBeInTheDocument()
    })

    it('populates form fields when editing', () => {
      render(
        <AIExperienceForm
          aiExperience={mockAiExperience}
          onSubmit={mockOnSubmit}
          isLoading={false}
        />,
      )

      expect(screen.getByDisplayValue('Test Experience')).toBeInTheDocument()
      expect(screen.getByDisplayValue('Test Description')).toBeInTheDocument()
      expect(screen.getByDisplayValue('Test Facts')).toBeInTheDocument()
      expect(screen.getByDisplayValue('Test Objectives')).toBeInTheDocument()
      expect(screen.getByDisplayValue('Test Pedagogical Guidance')).toBeInTheDocument()
    })
  })

  describe('form submission', () => {
    it('calls onSubmit with form data when Save as draft is clicked', async () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      const titleInput = screen.getByLabelText(/Title/) as HTMLInputElement
      const descriptionInput = screen.getByLabelText(/Description/) as HTMLTextAreaElement
      const learningObjectivesInput = screen.getByLabelText(
        /Learning objectives/,
      ) as HTMLTextAreaElement
      const pedagogicalGuidanceInput = screen.getByLabelText(
        /Pedagogical guidance/,
      ) as HTMLTextAreaElement

      fireEvent.change(titleInput, {target: {value: 'New Title'}})
      fireEvent.change(descriptionInput, {target: {value: 'New Description'}})
      fireEvent.change(learningObjectivesInput, {target: {value: 'New Learning Objectives'}})
      fireEvent.change(pedagogicalGuidanceInput, {target: {value: 'New Pedagogical Guidance'}})

      const saveButton = screen.getByText('Save as draft')
      fireEvent.click(saveButton)

      await waitFor(() => {
        expect(mockOnSubmit).toHaveBeenCalledWith(
          expect.objectContaining({
            title: 'New Title',
            description: 'New Description',
            learning_objective: 'New Learning Objectives',
            pedagogical_guidance: 'New Pedagogical Guidance',
          }),
        )
      })
    })

    it('disables save button when loading', () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={true} />)

      const saveButton = screen.getByText('Saving...')
      expect(saveButton).toBeInTheDocument()
    })
  })

  describe('cancel functionality', () => {
    it('calls onCancel when Cancel button is clicked', () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} onCancel={mockOnCancel} />)

      const cancelButton = screen.getByText('Cancel')
      fireEvent.click(cancelButton)

      expect(mockOnCancel).toHaveBeenCalled()
    })
  })

  describe('preview menu', () => {
    it('opens preview menu when Preview button is clicked', async () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      const previewButton = screen.getByText('Preview')
      fireEvent.click(previewButton)

      await waitFor(() => {
        expect(screen.getByText('Preview experience')).toBeInTheDocument()
        expect(screen.getByText('Run chat simulation')).toBeInTheDocument()
        expect(screen.getByText('Coming soon')).toBeInTheDocument()
      })
    })

    it('Run chat simulation is disabled', async () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      const previewButton = screen.getByText('Preview')
      fireEvent.click(previewButton)

      await waitFor(() => {
        const runSimulationItem = screen
          .getByText('Run chat simulation')
          .closest('[role="menuitem"]')
        expect(runSimulationItem).toHaveAttribute('aria-disabled', 'true')
      })
    })

    it('opens preview confirmation modal when Preview experience is clicked', async () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      const previewButton = screen.getByText('Preview')
      fireEvent.click(previewButton)

      await waitFor(() => {
        expect(screen.getByText('Preview experience')).toBeInTheDocument()
      })

      const previewExperienceItem = screen.getByText('Preview experience')
      fireEvent.click(previewExperienceItem)

      await waitFor(() => {
        expect(screen.getByText('Preview AI experience')).toBeInTheDocument()
        expect(
          screen.getByText(
            'We will save this experience as a draft so you can preview it. Please confirm to proceed.',
          ),
        ).toBeInTheDocument()
      })
    })

    it('calls onSubmit when preview is confirmed', async () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      const previewButton = screen.getByText('Preview')
      fireEvent.click(previewButton)

      await waitFor(() => {
        expect(screen.getByText('Preview experience')).toBeInTheDocument()
      })

      const previewExperienceItem = screen.getByText('Preview experience')
      fireEvent.click(previewExperienceItem)

      await waitFor(() => {
        expect(screen.getByText('Confirm')).toBeInTheDocument()
      })

      const confirmButton = screen.getByText('Confirm')
      fireEvent.click(confirmButton)

      await waitFor(() => {
        expect(mockOnSubmit).toHaveBeenCalled()
      })
    })
  })

  describe('delete functionality', () => {
    it('renders three-dot menu button', () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      const menuButton = screen.getAllByText('More options')[0].closest('button')
      expect(menuButton).toBeInTheDocument()
    })

    it('shows delete option in menu', async () => {
      render(
        <AIExperienceForm
          aiExperience={mockAiExperience}
          onSubmit={mockOnSubmit}
          isLoading={false}
        />,
      )

      const menuButton = screen.getAllByText('More options')[0].closest('button')
      fireEvent.click(menuButton!)

      await waitFor(() => {
        expect(screen.getByText('Delete')).toBeInTheDocument()
      })
    })

    it('delete is disabled when creating new experience', async () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      const menuButton = screen.getAllByText('More options')[0].closest('button')
      fireEvent.click(menuButton!)

      await waitFor(() => {
        const deleteItem = screen.getByText('Delete').closest('[role="menuitem"]')
        expect(deleteItem).toHaveAttribute('aria-disabled', 'true')
      })
    })

    it('opens delete confirmation modal when Delete is clicked', async () => {
      render(
        <AIExperienceForm
          aiExperience={mockAiExperience}
          onSubmit={mockOnSubmit}
          isLoading={false}
        />,
      )

      const menuButton = screen.getAllByText('More options')[0].closest('button')
      fireEvent.click(menuButton!)

      await waitFor(() => {
        expect(screen.getByText('Delete')).toBeInTheDocument()
      })

      const deleteMenuItem = screen.getByText('Delete')
      fireEvent.click(deleteMenuItem)

      await waitFor(() => {
        expect(screen.getByText('Delete AI Experience')).toBeInTheDocument()
        expect(
          screen.getByText(
            'Are you sure you want to delete "Test Experience"? This action cannot be undone.',
          ),
        ).toBeInTheDocument()
      })
    })

    it('closes delete modal when Cancel is clicked', async () => {
      render(
        <AIExperienceForm
          aiExperience={mockAiExperience}
          onSubmit={mockOnSubmit}
          isLoading={false}
        />,
      )

      const menuButton = screen.getAllByText('More options')[0].closest('button')
      fireEvent.click(menuButton!)

      await waitFor(() => {
        expect(screen.getByText('Delete')).toBeInTheDocument()
      })

      const deleteMenuItem = screen.getByText('Delete')
      fireEvent.click(deleteMenuItem)

      await waitFor(() => {
        expect(screen.getByText('Delete AI Experience')).toBeInTheDocument()
      })

      const cancelButtons = screen.getAllByText('Cancel')
      const modalCancelButton = cancelButtons[cancelButtons.length - 1].closest('button')
      fireEvent.click(modalCancelButton!)

      await waitFor(() => {
        expect(screen.queryByText('Delete AI Experience')).not.toBeInTheDocument()
      })
    })

    it('calls delete API when confirmed', async () => {
      let deleteCalled = false
      server.use(
        http.delete('/api/v1/courses/123/ai_experiences/1', () => {
          deleteCalled = true
          return HttpResponse.json({})
        }),
      )

      render(
        <AIExperienceForm
          aiExperience={mockAiExperience}
          onSubmit={mockOnSubmit}
          isLoading={false}
        />,
      )

      const menuButton = screen.getAllByText('More options')[0].closest('button')
      fireEvent.click(menuButton!)

      await waitFor(() => {
        expect(screen.getByText('Delete')).toBeInTheDocument()
      })

      const deleteMenuItem = screen.getByText('Delete')
      fireEvent.click(deleteMenuItem)

      await waitFor(() => {
        expect(screen.getByText('Delete AI Experience')).toBeInTheDocument()
      })

      const deleteButtons = screen.getAllByText('Delete')
      const confirmDeleteButton = deleteButtons[deleteButtons.length - 1].closest('button')
      fireEvent.click(confirmDeleteButton!)

      await waitFor(() => {
        expect(deleteCalled).toBe(true)
      })
    })
  })
})
