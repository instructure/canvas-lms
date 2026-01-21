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
import AIExperiencePublishButton from '../components/AIExperiencePublishButton'

const server = setupServer(
  http.put('/api/v1/courses/123/ai_experiences/1', () => {
    return HttpResponse.json({
      id: 1,
      workflow_state: 'published',
      can_unpublish: true,
    })
  }),
)

describe('AIExperiencePublishButton', () => {
  const defaultProps = {
    experienceId: '1',
    courseId: '123',
    isPublished: false,
    canUnpublish: true,
    onPublishChange: vi.fn(),
  }

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    server.resetHandlers()
  })

  afterEach(() => {
    cleanup()
    vi.clearAllMocks()
  })

  it('renders unpublished button correctly', () => {
    render(<AIExperiencePublishButton {...defaultProps} />)
    expect(screen.getByTestId('ai-experience-publish-button')).toBeInTheDocument()
    expect(screen.getByText('Unpublished')).toBeInTheDocument()
  })

  it('renders published button correctly', () => {
    render(<AIExperiencePublishButton {...defaultProps} isPublished={true} />)
    expect(screen.getByText('Published')).toBeInTheDocument()
  })

  it('opens menu when button is clicked', async () => {
    render(<AIExperiencePublishButton {...defaultProps} />)
    const button = screen.getByTestId('ai-experience-publish-button')
    fireEvent.click(button)

    await waitFor(() => {
      expect(screen.getByTestId('publish-option')).toBeInTheDocument()
      expect(screen.getByTestId('unpublish-option')).toBeInTheDocument()
    })
  })

  it('publish option is disabled when already published', async () => {
    render(<AIExperiencePublishButton {...defaultProps} isPublished={true} />)
    const button = screen.getByTestId('ai-experience-publish-button')
    fireEvent.click(button)

    await waitFor(() => {
      const publishOption = screen.getByTestId('publish-option')
      expect(publishOption).toHaveAttribute('aria-disabled', 'true')
    })
  })

  it('unpublish option is disabled when not published', async () => {
    render(<AIExperiencePublishButton {...defaultProps} isPublished={false} />)
    const button = screen.getByTestId('ai-experience-publish-button')
    fireEvent.click(button)

    await waitFor(() => {
      const unpublishOption = screen.getByTestId('unpublish-option')
      expect(unpublishOption).toHaveAttribute('aria-disabled', 'true')
    })
  })

  it('unpublish option is disabled when cannot unpublish', async () => {
    render(<AIExperiencePublishButton {...defaultProps} isPublished={true} canUnpublish={false} />)
    const button = screen.getByTestId('ai-experience-publish-button')
    fireEvent.click(button)

    await waitFor(() => {
      const unpublishOption = screen.getByTestId('unpublish-option')
      expect(unpublishOption).toHaveAttribute('aria-disabled', 'true')
      expect(screen.getByText('(Students have conversations)')).toBeInTheDocument()
    })
  })

  it('calls API and callback when publishing', async () => {
    const onPublishChange = vi.fn()
    render(<AIExperiencePublishButton {...defaultProps} onPublishChange={onPublishChange} />)

    const button = screen.getByTestId('ai-experience-publish-button')
    fireEvent.click(button)

    await waitFor(() => {
      expect(screen.getByTestId('publish-option')).toBeInTheDocument()
    })

    const publishOption = screen.getByTestId('publish-option')
    fireEvent.click(publishOption)

    await waitFor(() => {
      expect(onPublishChange).toHaveBeenCalledWith('published')
    })
  })

  it('calls API and callback when unpublishing', async () => {
    server.use(
      http.put('/api/v1/courses/123/ai_experiences/1', () => {
        return HttpResponse.json({
          id: 1,
          workflow_state: 'unpublished',
          can_unpublish: true,
        })
      }),
    )

    const onPublishChange = vi.fn()
    render(
      <AIExperiencePublishButton
        {...defaultProps}
        isPublished={true}
        onPublishChange={onPublishChange}
      />,
    )

    const button = screen.getByTestId('ai-experience-publish-button')
    fireEvent.click(button)

    await waitFor(() => {
      expect(screen.getByTestId('unpublish-option')).toBeInTheDocument()
    })

    const unpublishOption = screen.getByTestId('unpublish-option')
    fireEvent.click(unpublishOption)

    await waitFor(() => {
      expect(onPublishChange).toHaveBeenCalledWith('unpublished')
    })
  })

  it('shows error message when API call fails', async () => {
    server.use(
      http.put('/api/v1/courses/123/ai_experiences/1', () => {
        return HttpResponse.json(
          {
            errors: {
              workflow_state: ["Can't unpublish if students have started conversations"],
            },
          },
          {status: 400},
        )
      }),
    )

    const onPublishChange = vi.fn()
    render(
      <AIExperiencePublishButton
        {...defaultProps}
        isPublished={true}
        onPublishChange={onPublishChange}
      />,
    )

    const button = screen.getByTestId('ai-experience-publish-button')
    fireEvent.click(button)

    await waitFor(() => {
      expect(screen.getByTestId('unpublish-option')).toBeInTheDocument()
    })

    const unpublishOption = screen.getByTestId('unpublish-option')
    fireEvent.click(unpublishOption)

    await waitFor(() => {
      expect(onPublishChange).not.toHaveBeenCalled()
    })
  })
})
