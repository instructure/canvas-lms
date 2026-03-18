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
import {cleanup, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import fakeEnv from '@canvas/test-utils/fakeENV'
import AiExperiencesIndex from '../AiExperiencesIndex'

const server = setupServer()

beforeAll(() => server.listen())
afterAll(() => server.close())

beforeEach(() => {
  vi.clearAllMocks()
  fakeEnv.setup({COURSE_ID: 123})
})

afterEach(() => {
  server.resetHandlers()
  cleanup()
  fakeEnv.teardown()
})

const mockExperiences = [
  {
    id: 1,
    title: 'Customer Service Training',
    workflow_state: 'published',
    created_at: '2025-01-15T10:30:00Z',
  },
  {
    id: 2,
    title: 'Sales Pitch Practice',
    workflow_state: 'unpublished',
    created_at: '2025-01-16T14:20:00Z',
  },
]

describe('AiExperiencesIndex', () => {
  describe('empty state', () => {
    it('shows teacher empty state when no experiences exist', async () => {
      server.use(
        http.get('/api/v1/courses/123/ai_experiences', () =>
          HttpResponse.json({experiences: [], can_manage: true}),
        ),
      )

      render(<AiExperiencesIndex />)

      await waitFor(() =>
        expect(screen.getByText('No AI experiences created yet.')).toBeInTheDocument(),
      )
      expect(screen.getByText('Create new')).toBeInTheDocument()
      expect(
        screen.getByText('Click the Create New button to start building your first AI experience.'),
      ).toBeInTheDocument()
    })
  })

  describe('teacher view', () => {
    it('links experience titles to their show page', async () => {
      server.use(
        http.get('/api/v1/courses/123/ai_experiences', () =>
          HttpResponse.json({experiences: mockExperiences, can_manage: true}),
        ),
      )

      render(<AiExperiencesIndex />)

      await waitFor(() => expect(screen.getByText('Customer Service Training')).toBeInTheDocument())
      expect(screen.getByText('Customer Service Training')).toHaveAttribute(
        'href',
        '/courses/123/ai_experiences/1',
      )
    })

    it('navigates to edit page when Edit is clicked from the options menu', async () => {
      server.use(
        http.get('/api/v1/courses/123/ai_experiences', () =>
          HttpResponse.json({experiences: mockExperiences, can_manage: true}),
        ),
      )
      const user = userEvent.setup()
      render(<AiExperiencesIndex />)

      await waitFor(() => expect(screen.getByText('Customer Service Training')).toBeInTheDocument())

      const originalLocation = window.location
      delete (window as any).location
      ;(window as any).location = {href: ''}

      await user.click(screen.getAllByTestId('ai-experience-menu')[0])
      await user.click(screen.getByText('Edit'))

      expect(window.location.href).toBe('/courses/123/ai_experiences/1/edit')
      ;(window as any).location = originalLocation
    })

    it('navigates to test conversation page when Test Conversation is clicked', async () => {
      server.use(
        http.get('/api/v1/courses/123/ai_experiences', () =>
          HttpResponse.json({experiences: mockExperiences, can_manage: true}),
        ),
      )
      const user = userEvent.setup()
      render(<AiExperiencesIndex />)

      await waitFor(() => expect(screen.getByText('Customer Service Training')).toBeInTheDocument())

      const originalLocation = window.location
      delete (window as any).location
      ;(window as any).location = {href: ''}

      await user.click(screen.getAllByTestId('ai-experience-menu')[0])
      await user.click(screen.getByText('Test Conversation'))

      expect(window.location.href).toBe('/courses/123/ai_experiences/1?preview=true')
      ;(window as any).location = originalLocation
    })

    it('removes experience from list after delete is confirmed', async () => {
      server.use(
        http.get('/api/v1/courses/123/ai_experiences', () =>
          HttpResponse.json({experiences: mockExperiences, can_manage: true}),
        ),
        http.delete('/api/v1/courses/123/ai_experiences/:id', () =>
          HttpResponse.json({success: true}),
        ),
      )
      window.confirm = vi.fn(() => true)
      const user = userEvent.setup()
      render(<AiExperiencesIndex />)

      await waitFor(() => expect(screen.getByText('Customer Service Training')).toBeInTheDocument())
      await user.click(screen.getAllByTestId('ai-experience-menu')[0])
      await user.click(screen.getByText('Delete'))

      await waitFor(() =>
        expect(screen.queryByText('Customer Service Training')).not.toBeInTheDocument(),
      )
    })

    it('lists both published and unpublished experiences', async () => {
      server.use(
        http.get('/api/v1/courses/123/ai_experiences', () =>
          HttpResponse.json({experiences: mockExperiences, can_manage: true}),
        ),
      )

      render(<AiExperiencesIndex />)

      await waitFor(() => expect(screen.getByText('Customer Service Training')).toBeInTheDocument())
      expect(screen.getByText('Sales Pitch Practice')).toBeInTheDocument()
    })
  })
})
