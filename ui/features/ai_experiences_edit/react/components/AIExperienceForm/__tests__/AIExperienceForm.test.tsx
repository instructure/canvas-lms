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
import AIExperienceForm from '../AIExperienceForm'
import type {AIExperience} from '../../../../types'
import fakeEnv from '@canvas/test-utils/fakeENV'

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

  afterEach(() => {
    cleanup()
    fakeEnv.teardown()
  })

  beforeEach(() => {
    vi.clearAllMocks()
    fakeEnv.setup({COURSE_ID: 123})
  })

  describe('rendering', () => {
    it('renders form for new AI experience', () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)
      expect(screen.getByText('New Knowledge Chat')).toBeInTheDocument()
    })

    it('renders form for editing AI experience', () => {
      render(
        <AIExperienceForm
          aiExperience={mockAiExperience}
          onSubmit={mockOnSubmit}
          isLoading={false}
        />,
      )
      expect(screen.getByText('Edit Test Experience')).toBeInTheDocument()
    })

    it('renders all form fields', () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      expect(screen.getByLabelText(/Knowledge chat name/)).toBeInTheDocument()
      expect(screen.getByLabelText(/Knowledge chat description/)).toBeInTheDocument()
      expect(screen.getByLabelText(/Text source/)).toBeInTheDocument()
      expect(screen.getByLabelText(/Learning objective targets/)).toBeInTheDocument()
      expect(screen.getByLabelText(/Pedagogical guidance/)).toBeInTheDocument()
    })

    it('renders configuration section', () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      expect(screen.getByText('Configurations')).toBeInTheDocument()
      expect(
        screen.getByText(
          'Define the completion rules, pedagogical guidance, and sources of the large language model (LLM).',
        ),
      ).toBeInTheDocument()
    })

    it('renders action buttons', () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      expect(screen.getByText('Cancel')).toBeInTheDocument()
      expect(screen.getByText('Save')).toBeInTheDocument()
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
    it('calls onSubmit with form data when Save button is clicked', async () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      const titleInput = screen.getByLabelText(/Knowledge chat name/) as HTMLInputElement
      const descriptionInput = screen.getByLabelText(
        /Knowledge chat description/,
      ) as HTMLTextAreaElement
      const factsInput = screen.getByLabelText(/Text source/) as HTMLTextAreaElement
      const learningObjectivesInput = screen.getByLabelText(
        /Learning objective targets/,
      ) as HTMLTextAreaElement
      const pedagogicalGuidanceInput = screen.getByLabelText(
        /Pedagogical guidance/,
      ) as HTMLTextAreaElement

      fireEvent.change(titleInput, {target: {value: 'New Title'}})
      fireEvent.change(descriptionInput, {target: {value: 'New Description'}})
      fireEvent.change(factsInput, {target: {value: 'New Facts'}})
      fireEvent.change(learningObjectivesInput, {target: {value: 'New Learning Objectives'}})
      fireEvent.change(pedagogicalGuidanceInput, {target: {value: 'New Pedagogical Guidance'}})

      const saveButton = screen.getByText('Save')
      fireEvent.click(saveButton)

      await waitFor(() => {
        expect(mockOnSubmit).toHaveBeenCalledWith(
          expect.objectContaining({
            title: 'New Title',
            description: 'New Description',
            facts: 'New Facts',
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

  describe('form validation', () => {
    it('shows error when title is empty on submission', async () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      const saveButton = screen.getByText('Save')
      fireEvent.click(saveButton)

      await waitFor(() => {
        expect(screen.getByText('Knowledge chat name required')).toBeInTheDocument()
      })

      expect(mockOnSubmit).not.toHaveBeenCalled()
    })

    it('shows error when facts is empty on submission', async () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      const titleInput = screen.getByLabelText(/Knowledge chat name/) as HTMLInputElement
      fireEvent.change(titleInput, {target: {value: 'Test Title'}})

      const saveButton = screen.getByText('Save')
      fireEvent.click(saveButton)

      await waitFor(() => {
        expect(screen.getByText('Please provide facts students should know')).toBeInTheDocument()
      })

      expect(mockOnSubmit).not.toHaveBeenCalled()
    })

    it('shows error when learning_objective is empty on submission', async () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      const titleInput = screen.getByLabelText(/Knowledge chat name/) as HTMLInputElement
      fireEvent.change(titleInput, {target: {value: 'Test Title'}})

      const saveButton = screen.getByText('Save')
      fireEvent.click(saveButton)

      await waitFor(() => {
        expect(
          screen.getByText('Please provide at least one learning objective'),
        ).toBeInTheDocument()
      })

      expect(mockOnSubmit).not.toHaveBeenCalled()
    })

    it('shows error when pedagogical_guidance is empty on submission', async () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      const titleInput = screen.getByLabelText(/Knowledge chat name/) as HTMLInputElement
      fireEvent.change(titleInput, {target: {value: 'Test Title'}})

      const saveButton = screen.getByText('Save')
      fireEvent.click(saveButton)

      await waitFor(() => {
        expect(screen.getByText('Please provide pedagogical guidance')).toBeInTheDocument()
      })

      expect(mockOnSubmit).not.toHaveBeenCalled()
    })

    it('shows error banner when validation fails', async () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      const saveButton = screen.getByText('Save')
      fireEvent.click(saveButton)

      await waitFor(() => {
        expect(
          screen.getByText(
            'Some required information is missing. Please complete all highlighted fields before saving.',
          ),
        ).toBeInTheDocument()
      })
    })

    it('does not show errors until first submission attempt', () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      expect(screen.queryByText('Knowledge chat name required')).not.toBeInTheDocument()
      expect(
        screen.queryByText('Please provide facts students should know'),
      ).not.toBeInTheDocument()
      expect(
        screen.queryByText('Please provide at least one learning objective'),
      ).not.toBeInTheDocument()
      expect(screen.queryByText('Please provide pedagogical guidance')).not.toBeInTheDocument()
    })

    it('clears error when field is filled', async () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      const saveButton = screen.getByText('Save')
      fireEvent.click(saveButton)

      await waitFor(() => {
        expect(screen.getByText('Knowledge chat name required')).toBeInTheDocument()
      })

      const titleInput = screen.getByLabelText(/Knowledge chat name/) as HTMLInputElement
      fireEvent.change(titleInput, {target: {value: 'Test Title'}})

      await waitFor(() => {
        expect(screen.queryByText('Knowledge chat name required')).not.toBeInTheDocument()
      })
    })

    it('submits successfully when all required fields are filled', async () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)

      const titleInput = screen.getByLabelText(/Knowledge chat name/) as HTMLInputElement
      const factsInput = screen.getByLabelText(/Text source/) as HTMLTextAreaElement
      const learningObjectivesInput = screen.getByLabelText(
        /Learning objective targets/,
      ) as HTMLTextAreaElement
      const pedagogicalGuidanceInput = screen.getByLabelText(
        /Pedagogical guidance/,
      ) as HTMLTextAreaElement

      fireEvent.change(titleInput, {target: {value: 'New Title'}})
      fireEvent.change(factsInput, {target: {value: 'New Facts'}})
      fireEvent.change(learningObjectivesInput, {target: {value: 'New Learning Objectives'}})
      fireEvent.change(pedagogicalGuidanceInput, {target: {value: 'New Pedagogical Guidance'}})

      const saveButton = screen.getByText('Save')
      fireEvent.click(saveButton)

      await waitFor(() => {
        expect(mockOnSubmit).toHaveBeenCalledWith(
          expect.objectContaining({
            title: 'New Title',
            facts: 'New Facts',
            learning_objective: 'New Learning Objectives',
            pedagogical_guidance: 'New Pedagogical Guidance',
          }),
        )
      })
    })
  })

  describe('context file handling', () => {
    const fillRequiredFields = () => {
      fireEvent.change(screen.getByLabelText(/Knowledge chat name/), {target: {value: 'Title'}})
      fireEvent.change(screen.getByLabelText(/Text source/), {target: {value: 'Facts'}})
      fireEvent.change(screen.getByLabelText(/Learning objective targets/), {
        target: {value: 'Objectives'},
      })
      fireEvent.change(screen.getByLabelText(/Pedagogical guidance/), {target: {value: 'Guidance'}})
    }

    it('includes context_file_ids as empty array in submit payload when no files', async () => {
      render(<AIExperienceForm onSubmit={mockOnSubmit} isLoading={false} />)
      fillRequiredFields()
      fireEvent.click(screen.getByText('Save'))

      await waitFor(() => {
        expect(mockOnSubmit).toHaveBeenCalledWith(expect.objectContaining({context_file_ids: []}))
      })
    })

    it('seeds contextFiles state from aiExperience.context_files on edit load', async () => {
      const aiExperienceWithFiles: AIExperience = {
        ...mockAiExperience,
        context_files: [
          {
            id: '42',
            display_name: 'syllabus.pdf',
            url: 'https://example.com/42',
            size: 1024,
            content_type: 'application/pdf',
          },
          {
            id: '99',
            display_name: 'rubric.pdf',
            url: 'https://example.com/99',
            size: 2048,
            content_type: 'application/pdf',
          },
        ],
      }

      render(
        <AIExperienceForm
          aiExperience={aiExperienceWithFiles}
          onSubmit={mockOnSubmit}
          isLoading={false}
        />,
      )

      fireEvent.click(screen.getByText('Save'))

      await waitFor(() => {
        expect(mockOnSubmit).toHaveBeenCalledWith(
          expect.objectContaining({context_file_ids: ['42', '99']}),
        )
      })
    })
  })

  describe('failed context files alert', () => {
    it('shows an error alert naming the failed file', () => {
      render(
        <AIExperienceForm
          aiExperience={{
            ...mockAiExperience,
            failed_context_file_names: ['poison.pdf'],
          }}
          onSubmit={mockOnSubmit}
          isLoading={false}
        />,
      )
      expect(screen.getByTestId('ai-experience-edit-index-failed-notice')).toBeInTheDocument()
      expect(screen.getByText(/Activity couldn't be loaded/)).toBeInTheDocument()
      expect(screen.getByText(/poison\.pdf/)).toBeInTheDocument()
    })

    it('lists all failed file names in the alert', () => {
      render(
        <AIExperienceForm
          aiExperience={{
            ...mockAiExperience,
            failed_context_file_names: ['poison.pdf', 'corrupt.docx'],
          }}
          onSubmit={mockOnSubmit}
          isLoading={false}
        />,
      )
      expect(screen.getByTestId('ai-experience-edit-index-failed-notice')).toBeInTheDocument()
      expect(screen.getByText(/poison\.pdf, corrupt\.docx/)).toBeInTheDocument()
    })

    it('does not show the alert when failed_context_file_names is absent', () => {
      render(
        <AIExperienceForm
          aiExperience={mockAiExperience}
          onSubmit={mockOnSubmit}
          isLoading={false}
        />,
      )
      expect(screen.queryByTestId('ai-experience-edit-index-failed-notice')).not.toBeInTheDocument()
    })
  })
})
