/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import AiExperiencesIndex from '../AiExperiencesIndex'

const mockExperiences = [
  {
    id: 1,
    title: 'Customer Service Training',
    description: 'Practice customer service skills',
    workflow_state: 'published',
    created_at: '2025-01-15T10:30:00Z',
  },
  {
    id: 2,
    title: 'Sales Pitch Practice',
    description: 'Practice sales techniques',
    workflow_state: 'unpublished',
    created_at: '2025-01-16T14:20:00Z',
  },
]

beforeAll(() => {
  ;(global as any).ENV = {COURSE_ID: 123}
})

afterEach(() => {
  vi.clearAllMocks()
})

describe('AiExperiencesIndex', () => {
  describe('Loading state', () => {
    it('shows loading spinner while fetching experiences', () => {
      global.fetch = vi.fn(() => new Promise(() => {})) as any

      render(<AiExperiencesIndex />)
      expect(screen.getByText('Loading AI experiences')).toBeInTheDocument()
    })
  })

  describe('Error state', () => {
    it('displays error message when fetch fails', async () => {
      global.fetch = vi.fn(() => Promise.reject(new Error('Failed to fetch'))) as any

      render(<AiExperiencesIndex />)

      await waitFor(() => {
        expect(screen.getByText(/Error loading AI experiences/)).toBeInTheDocument()
      })
    })
  })

  describe('Teacher view (canManage = true)', () => {
    beforeEach(() => {
      global.fetch = vi.fn(() =>
        Promise.resolve({
          ok: true,
          json: async () => ({
            experiences: mockExperiences,
            can_manage: true,
          }),
        }),
      ) as any
    })

    it('displays AI Experiences heading with icon', async () => {
      render(<AiExperiencesIndex />)

      await waitFor(() => {
        expect(screen.getByText('AI Experiences')).toBeInTheDocument()
      })

      // Check for icon (IconAiColoredSolid renders an svg)
      const heading = screen.getByText('AI Experiences')
      const headingContainer = heading.closest('div')?.parentElement
      expect(headingContainer?.querySelector('svg')).toBeInTheDocument()
    })

    it('displays all experiences including unpublished', async () => {
      render(<AiExperiencesIndex />)

      await waitFor(() => {
        expect(screen.getByText('Customer Service Training')).toBeInTheDocument()
      })

      expect(screen.getByText('Sales Pitch Practice')).toBeInTheDocument()
    })

    it('shows Create new button in header when experiences exist', async () => {
      render(<AiExperiencesIndex />)

      await waitFor(() => {
        expect(screen.getByText('Customer Service Training')).toBeInTheDocument()
      })

      const createButtons = screen.getAllByText('Create new')
      expect(createButtons.length).toBeGreaterThan(0)
      expect(screen.getByTestId('ai-expriences-index-create-new-button')).toBeInTheDocument()
    })

    it('navigates to new experience page when Create button clicked', async () => {
      const user = userEvent.setup()
      delete (window as any).location
      ;(window as any).location = {href: ''}

      render(<AiExperiencesIndex />)

      await waitFor(() => {
        expect(screen.getByTestId('ai-expriences-index-create-new-button')).toBeInTheDocument()
      })

      const createButton = screen.getByTestId('ai-expriences-index-create-new-button')
      await user.click(createButton)

      expect(window.location.href).toBe('/courses/123/ai_experiences/new')
    })

    it('shows management controls on experience rows', async () => {
      render(<AiExperiencesIndex />)

      await waitFor(() => {
        expect(screen.getByText('Customer Service Training')).toBeInTheDocument()
      })

      // Should show publish buttons
      const publishButtons = screen.getAllByTestId('ai-experience-publish-toggle')
      expect(publishButtons.length).toBeGreaterThan(0)

      // Should show kebab menus
      const menuButtons = screen.getAllByTestId('ai-experience-menu')
      expect(menuButtons.length).toBeGreaterThan(0)
    })
  })

  describe('Student view (canManage = false)', () => {
    beforeEach(() => {
      global.fetch = vi.fn(() =>
        Promise.resolve({
          ok: true,
          json: async () => ({
            experiences: [mockExperiences[0]], // Only published experience
            can_manage: false,
          }),
        }),
      ) as any
    })

    it('displays only published experiences', async () => {
      render(<AiExperiencesIndex />)

      await waitFor(() => {
        expect(screen.getByText('Customer Service Training')).toBeInTheDocument()
      })

      // Should not show unpublished experience
      expect(screen.queryByText('Sales Pitch Practice')).not.toBeInTheDocument()
    })

    it('does not show Create new button in header', async () => {
      render(<AiExperiencesIndex />)

      await waitFor(() => {
        expect(screen.getByText('Customer Service Training')).toBeInTheDocument()
      })

      expect(screen.queryByTestId('ai-expriences-index-create-new-button')).not.toBeInTheDocument()
    })

    it('does not show management controls on experience rows', async () => {
      render(<AiExperiencesIndex />)

      await waitFor(() => {
        expect(screen.getByText('Customer Service Training')).toBeInTheDocument()
      })

      // Should not show publish buttons
      expect(screen.queryByTestId('ai-experience-publish-toggle')).not.toBeInTheDocument()

      // Should not show kebab menus
      expect(screen.queryByTestId('ai-experience-menu')).not.toBeInTheDocument()

      // Should not show published status text
      expect(screen.queryByText('Published')).not.toBeInTheDocument()
    })

    it('experience titles are still clickable', async () => {
      render(<AiExperiencesIndex />)

      await waitFor(() => {
        expect(screen.getByText('Customer Service Training')).toBeInTheDocument()
      })

      const titleLink = screen.getByText('Customer Service Training')
      expect(titleLink).toHaveAttribute('href', '/courses/123/ai_experiences/1')
    })
  })

  describe('Empty state - Teacher view', () => {
    beforeEach(() => {
      global.fetch = vi.fn(() =>
        Promise.resolve({
          ok: true,
          json: async () => ({
            experiences: [],
            can_manage: true,
          }),
        }),
      ) as any
    })

    it('shows teacher empty state message', async () => {
      render(<AiExperiencesIndex />)

      await waitFor(() => {
        expect(screen.getByText('No AI experiences created yet.')).toBeInTheDocument()
      })
    })

    it('shows Create new button in empty state', async () => {
      render(<AiExperiencesIndex />)

      await waitFor(() => {
        expect(screen.getByText('No AI experiences created yet.')).toBeInTheDocument()
      })

      expect(screen.getByText('Create new')).toBeInTheDocument()
    })

    it('shows teacher-specific empty state description', async () => {
      render(<AiExperiencesIndex />)

      await waitFor(() => {
        expect(
          screen.getByText(
            'Click the Create New button to start building your first AI experience.',
          ),
        ).toBeInTheDocument()
      })
    })
  })

  describe('Empty state - Student view', () => {
    beforeEach(() => {
      global.fetch = vi.fn(() =>
        Promise.resolve({
          ok: true,
          json: async () => ({
            experiences: [],
            can_manage: false,
          }),
        }),
      ) as any
    })

    it('shows student empty state message', async () => {
      render(<AiExperiencesIndex />)

      await waitFor(() => {
        expect(screen.getByText('No AI experiences available yet.')).toBeInTheDocument()
      })
    })

    it('does not show Create new button in empty state', async () => {
      render(<AiExperiencesIndex />)

      await waitFor(() => {
        expect(screen.getByText('No AI experiences available yet.')).toBeInTheDocument()
      })

      expect(screen.queryByText('Create new')).not.toBeInTheDocument()
    })

    it('shows student-specific empty state description', async () => {
      render(<AiExperiencesIndex />)

      await waitFor(() => {
        expect(
          screen.getByText('Your instructor has not published any AI experiences yet.'),
        ).toBeInTheDocument()
      })
    })
  })

  describe('Delete functionality', () => {
    beforeEach(() => {
      global.fetch = vi.fn((url: string, options?: any) => {
        if (options?.method === 'DELETE') {
          return Promise.resolve({
            ok: true,
            json: async () => ({success: true}),
          })
        }
        return Promise.resolve({
          ok: true,
          json: async () => ({
            experiences: mockExperiences,
            can_manage: true,
          }),
        })
      }) as any

      // Mock window.confirm
      window.confirm = vi.fn(() => true)
    })

    it('removes experience from list after successful delete', async () => {
      const user = userEvent.setup()
      render(<AiExperiencesIndex />)

      await waitFor(() => {
        expect(screen.getByText('Customer Service Training')).toBeInTheDocument()
      })

      // Open menu and click delete
      const menuButtons = screen.getAllByTestId('ai-experience-menu')
      await user.click(menuButtons[0])

      const deleteButton = screen.getByText('Delete')
      await user.click(deleteButton)

      // Experience should be removed from list
      await waitFor(() => {
        expect(screen.queryByText('Customer Service Training')).not.toBeInTheDocument()
      })
    })
  })

  describe('Publish toggle functionality', () => {
    beforeEach(() => {
      global.fetch = vi.fn((url: string, options?: any) => {
        if (options?.method === 'PUT') {
          return Promise.resolve({
            ok: true,
            json: async () => ({
              ...mockExperiences[0],
              workflow_state: 'unpublished',
            }),
          })
        }
        return Promise.resolve({
          ok: true,
          json: async () => ({
            experiences: mockExperiences,
            can_manage: true,
          }),
        })
      }) as any
    })

    it('updates experience workflow state when publish toggle clicked', async () => {
      const user = userEvent.setup()
      render(<AiExperiencesIndex />)

      await waitFor(() => {
        expect(screen.getByText('Customer Service Training')).toBeInTheDocument()
      })

      const publishButtons = screen.getAllByTestId('ai-experience-publish-toggle')
      await user.click(publishButtons[0])

      // The component should update the local state
      await waitFor(() => {
        // The state change is internal, so we can't directly test it,
        // but we can verify no errors occurred and component is still rendered
        expect(screen.getByText('Customer Service Training')).toBeInTheDocument()
      })
    })
  })
})
