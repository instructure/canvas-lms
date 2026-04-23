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

import '@instructure/canvas-theme'
import React from 'react'
import {cleanup, render, screen, fireEvent, waitFor} from '@testing-library/react'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import AIExperienceManager from '../AIExperienceManager'
import fakeEnv from '@canvas/test-utils/fakeENV'
import {showFlashError} from '@instructure/platform-alerts'

vi.mock('@instructure/platform-alerts', async () => {
  const actual = await vi.importActual('@instructure/platform-alerts')
  return {
    ...actual,
    showFlashError: vi.fn(() => vi.fn()),
    showFlashSuccess: vi.fn(() => vi.fn()),
  }
})

const server = setupServer()

const mockAiExperience = {
  id: '1',
  title: 'Test Experience',
  description: 'Test Description',
  facts: 'Test Facts',
  learning_objective: 'Test Objectives',
  pedagogical_guidance: 'Test Guidance',
  workflow_state: 'unpublished',
}

describe('AIExperienceManager', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    fakeEnv.setup({COURSE_ID: 123})
    vi.clearAllMocks()
  })

  afterEach(() => {
    server.resetHandlers()
    cleanup()
    fakeEnv.teardown()
  })

  describe('save error handling', () => {
    it('shows a flash error with the backend message when file sync fails', async () => {
      server.use(
        http.put('/courses/123/ai_experiences/1', () => {
          return HttpResponse.json(
            {base: ['Failed to sync files: 503 - Service Unavailable']},
            {status: 400},
          )
        }),
      )

      render(<AIExperienceManager aiExperience={mockAiExperience} />)

      fireEvent.click(screen.getByTestId('ai-experience-save-as-draft-item'))

      await waitFor(() => {
        expect(showFlashError).toHaveBeenCalledWith(
          expect.stringContaining('Failed to sync files: 503 - Service Unavailable'),
        )
      })
    })

    it('shows a generic flash error when the server returns an unparseable response', async () => {
      server.use(
        http.put('/courses/123/ai_experiences/1', () => {
          return new HttpResponse('Internal Server Error', {status: 500})
        }),
      )

      render(<AIExperienceManager aiExperience={mockAiExperience} />)

      fireEvent.click(screen.getByTestId('ai-experience-save-as-draft-item'))

      await waitFor(() => {
        expect(showFlashError).toHaveBeenCalledWith(
          expect.stringContaining('An unexpected error occurred'),
        )
      })
    })
  })
})
