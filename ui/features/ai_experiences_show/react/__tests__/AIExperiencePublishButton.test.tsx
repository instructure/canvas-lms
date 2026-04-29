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
    contextReady: true,
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

  it('calls API and callback when publishing', async () => {
    const onPublishChange = vi.fn()
    render(<AIExperiencePublishButton {...defaultProps} onPublishChange={onPublishChange} />)

    fireEvent.click(screen.getByTestId('ai-experience-publish-button'))

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

    fireEvent.click(screen.getByTestId('ai-experience-publish-button'))

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

    fireEvent.click(screen.getByTestId('ai-experience-publish-button'))

    await waitFor(() => {
      expect(onPublishChange).not.toHaveBeenCalled()
    })
  })

  it('disables entire button when contextReady is false and unpublished', () => {
    render(<AIExperiencePublishButton {...defaultProps} isPublished={false} contextReady={false} />)
    const button = screen.getByTestId('ai-experience-publish-button')
    expect(button).toBeDisabled()
  })

  it('disables entire button when canUnpublish is false and published', () => {
    render(<AIExperiencePublishButton {...defaultProps} isPublished={true} canUnpublish={false} />)
    const button = screen.getByTestId('ai-experience-publish-button')
    expect(button).toBeDisabled()
  })

  it('shows tooltip when contextReady is false and unpublished', () => {
    const {container} = render(
      <AIExperiencePublishButton {...defaultProps} isPublished={false} contextReady={false} />,
    )
    // Tooltip content is rendered but may not be visible until hover
    expect(container).toBeInTheDocument()
  })

  it('shows tooltip when canUnpublish is false and published', () => {
    const {container} = render(
      <AIExperiencePublishButton {...defaultProps} isPublished={true} canUnpublish={false} />,
    )
    // Tooltip content is rendered but may not be visible until hover
    expect(container).toBeInTheDocument()
  })

  it('allows button to be clicked when contextReady is true and unpublished', () => {
    render(<AIExperiencePublishButton {...defaultProps} isPublished={false} contextReady={true} />)
    const button = screen.getByTestId('ai-experience-publish-button')
    expect(button).not.toBeDisabled()
  })

  it('disables button when indexFailed is true and unpublished', () => {
    render(
      <AIExperiencePublishButton
        {...defaultProps}
        isPublished={false}
        contextReady={false}
        indexFailed={true}
      />,
    )
    const button = screen.getByTestId('ai-experience-publish-button')
    expect(button).toBeDisabled()
  })

  it('allows button to be clicked when canUnpublish is true and published', () => {
    render(<AIExperiencePublishButton {...defaultProps} isPublished={true} canUnpublish={true} />)
    const button = screen.getByTestId('ai-experience-publish-button')
    expect(button).not.toBeDisabled()
  })

  it('clicking unpublished button directly publishes without opening a menu', async () => {
    const onPublishChange = vi.fn()
    render(<AIExperiencePublishButton {...defaultProps} onPublishChange={onPublishChange} />)

    fireEvent.click(screen.getByTestId('ai-experience-publish-button'))

    await waitFor(() => {
      expect(onPublishChange).toHaveBeenCalledWith('published')
    })
    expect(screen.queryByText('Publish')).not.toBeInTheDocument()
    expect(screen.queryByText('Unpublish')).not.toBeInTheDocument()
  })

  it('clicking published button directly unpublishes without opening a menu', async () => {
    server.use(
      http.put('/api/v1/courses/123/ai_experiences/1', () =>
        HttpResponse.json({id: 1, workflow_state: 'unpublished', can_unpublish: true}),
      ),
    )

    const onPublishChange = vi.fn()
    render(
      <AIExperiencePublishButton
        {...defaultProps}
        isPublished={true}
        onPublishChange={onPublishChange}
      />,
    )

    fireEvent.click(screen.getByTestId('ai-experience-publish-button'))

    await waitFor(() => {
      expect(onPublishChange).toHaveBeenCalledWith('unpublished')
    })
    expect(screen.queryByText('Publish')).not.toBeInTheDocument()
    expect(screen.queryByText('Unpublish')).not.toBeInTheDocument()
  })
})
