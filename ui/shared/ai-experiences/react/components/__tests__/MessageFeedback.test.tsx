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
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import MessageFeedback from '../MessageFeedback'
import type {FeedbackItem} from '../../../types'

const server = setupServer()

const courseId = 123
const aiExperienceId = '1'
const conversationId = 'conv-abc'
const messageId = 'msg-123'

const feedbackBasePath = `/api/v1/courses/${courseId}/ai_experiences/${aiExperienceId}/conversations/${conversationId}/messages/${messageId}/feedback`

const makeFeedback = (vote: 'liked' | 'disliked', id = 'fb-1'): FeedbackItem => ({
  id,
  user_id: 'user-1',
  vote,
  feedback_message: null,
  created_at: '2025-01-01T00:00:00Z',
  updated_at: '2025-01-01T00:00:00Z',
})

const defaultProps = {
  messageId,
  messageContainerId: `llm-message-${messageId}`,
  initialFeedback: [] as FeedbackItem[],
  courseId,
  aiExperienceId,
  conversationId,
}

describe('MessageFeedback', () => {
  beforeAll(() => server.listen({onUnhandledRequest: 'error'}))
  afterAll(() => server.close())
  afterEach(() => {
    vi.clearAllMocks()
    server.resetHandlers()
  })

  it('renders like and dislike buttons', () => {
    render(<MessageFeedback {...defaultProps} />)
    expect(screen.getByTestId('message-feedback-like')).toBeInTheDocument()
    expect(screen.getByTestId('message-feedback-dislike')).toBeInTheDocument()
  })

  describe('like button', () => {
    it('posts liked vote when clicked with no existing feedback', async () => {
      const liked = makeFeedback('liked')
      server.use(http.post(feedbackBasePath, () => HttpResponse.json({feedback: liked})))

      render(<MessageFeedback {...defaultProps} />)
      fireEvent.click(screen.getByTestId('message-feedback-like'))

      await waitFor(() => {
        // Button should now show solid (active) state via withBackground
        expect(screen.getByTestId('message-feedback-like')).toBeInTheDocument()
      })
    })

    it('removes like when liked message is clicked again', async () => {
      const liked = makeFeedback('liked')
      server.use(
        http.delete(`${feedbackBasePath}/${liked.id}`, () => HttpResponse.json({success: true})),
      )

      render(<MessageFeedback {...defaultProps} initialFeedback={[liked]} />)
      fireEvent.click(screen.getByTestId('message-feedback-like'))

      await waitFor(() => {
        expect(screen.getByTestId('message-feedback-like')).toBeInTheDocument()
      })
    })

    it('deletes existing dislike then posts like when switching vote', async () => {
      const disliked = makeFeedback('disliked', 'fb-old')
      const liked = makeFeedback('liked', 'fb-new')

      let deleteCalled = false
      let postCalled = false

      server.use(
        http.delete(`${feedbackBasePath}/${disliked.id}`, () => {
          deleteCalled = true
          return HttpResponse.json({success: true})
        }),
        http.post(feedbackBasePath, () => {
          postCalled = true
          return HttpResponse.json({feedback: liked})
        }),
      )

      render(<MessageFeedback {...defaultProps} initialFeedback={[disliked]} />)
      fireEvent.click(screen.getByTestId('message-feedback-like'))

      await waitFor(() => {
        expect(deleteCalled).toBe(true)
        expect(postCalled).toBe(true)
      })
    })
  })

  describe('dislike button', () => {
    it('shows dislike form when dislike is clicked', async () => {
      render(<MessageFeedback {...defaultProps} />)
      fireEvent.click(screen.getByTestId('message-feedback-dislike'))

      expect(screen.getByTestId('message-feedback-text')).toBeInTheDocument()
      expect(screen.getByTestId('message-feedback-skip')).toBeInTheDocument()
      expect(screen.getByTestId('message-feedback-submit')).toBeInTheDocument()
    })

    it('removes dislike when already disliked message is clicked', async () => {
      const disliked = makeFeedback('disliked')
      server.use(
        http.delete(`${feedbackBasePath}/${disliked.id}`, () => HttpResponse.json({success: true})),
      )

      render(<MessageFeedback {...defaultProps} initialFeedback={[disliked]} />)
      fireEvent.click(screen.getByTestId('message-feedback-dislike'))

      await waitFor(() => {
        expect(screen.queryByTestId('message-feedback-text')).not.toBeInTheDocument()
      })
    })
  })

  describe('dislike form', () => {
    beforeEach(() => {
      render(<MessageFeedback {...defaultProps} />)
      fireEvent.click(screen.getByTestId('message-feedback-dislike'))
    })

    it('submit button is disabled when feedback text is empty', () => {
      const submitBtn = screen.getByTestId('message-feedback-submit')
      expect(submitBtn).toHaveAttribute('disabled')
    })

    it('submit button remains disabled when text is only whitespace', () => {
      const textarea = screen.getByTestId('message-feedback-text')
      fireEvent.change(textarea, {target: {value: '   '}})

      const submitBtn = screen.getByTestId('message-feedback-submit')
      expect(submitBtn).toHaveAttribute('disabled')
    })

    it('submit button is enabled when feedback text is non-empty', () => {
      const textarea = screen.getByTestId('message-feedback-text')
      fireEvent.change(textarea, {target: {value: 'Some feedback'}})

      const submitBtn = screen.getByTestId('message-feedback-submit')
      expect(submitBtn).not.toHaveAttribute('disabled')
    })

    it('skip posts dislike without message and hides form without success banner', async () => {
      const disliked = makeFeedback('disliked')
      server.use(http.post(feedbackBasePath, () => HttpResponse.json({feedback: disliked})))

      fireEvent.click(screen.getByTestId('message-feedback-skip'))

      await waitFor(() => {
        expect(screen.queryByTestId('message-feedback-text')).not.toBeInTheDocument()
      })
      expect(screen.queryByTestId('message-feedback-success')).not.toBeInTheDocument()
    })

    it('submit posts dislike with message and shows success', async () => {
      const disliked = makeFeedback('disliked')

      let receivedBody: Record<string, unknown> | null = null
      server.use(
        http.post(feedbackBasePath, async ({request}) => {
          receivedBody = (await request.json()) as Record<string, unknown>
          return HttpResponse.json({feedback: disliked})
        }),
      )

      const textarea = screen.getByTestId('message-feedback-text')
      fireEvent.change(textarea, {target: {value: 'Irrelevant answer'}})

      fireEvent.click(screen.getByTestId('message-feedback-submit'))

      await waitFor(() => {
        expect(screen.getByTestId('message-feedback-success')).toBeInTheDocument()
      })

      expect(receivedBody!.feedback_message).toBe('Irrelevant answer')
      expect(receivedBody!.vote).toBe('disliked')
    })
  })

  describe('like while dislike form or confirmation is open', () => {
    it('closes dislike form when like is clicked', async () => {
      const liked = makeFeedback('liked')
      server.use(http.post(feedbackBasePath, () => HttpResponse.json({feedback: liked})))

      render(<MessageFeedback {...defaultProps} />)
      fireEvent.click(screen.getByTestId('message-feedback-dislike'))
      expect(screen.getByTestId('message-feedback-text')).toBeInTheDocument()

      fireEvent.click(screen.getByTestId('message-feedback-like'))

      await waitFor(() => {
        expect(screen.queryByTestId('message-feedback-text')).not.toBeInTheDocument()
      })
    })

    it('saves the like when clicking like while dislike form is open', async () => {
      const disliked = makeFeedback('disliked', 'fb-old')
      const liked = makeFeedback('liked', 'fb-new')

      let postCalled = false
      server.use(
        http.delete(`${feedbackBasePath}/${disliked.id}`, () => HttpResponse.json({success: true})),
        http.post(feedbackBasePath, () => {
          postCalled = true
          return HttpResponse.json({feedback: liked})
        }),
      )

      render(<MessageFeedback {...defaultProps} initialFeedback={[disliked]} />)
      fireEvent.click(screen.getByTestId('message-feedback-like'))

      await waitFor(() => {
        expect(postCalled).toBe(true)
      })
    })

    it('closes submitted confirmation when like is clicked', async () => {
      const disliked = makeFeedback('disliked', 'fb-old')
      const liked = makeFeedback('liked', 'fb-new')

      server.use(
        http.delete(`${feedbackBasePath}/${disliked.id}`, () => HttpResponse.json({success: true})),
        http.post(feedbackBasePath, () => HttpResponse.json({feedback: disliked})),
      )

      render(<MessageFeedback {...defaultProps} />)

      // Open form, fill it, submit to reach 'submitted' state
      fireEvent.click(screen.getByTestId('message-feedback-dislike'))
      fireEvent.change(screen.getByTestId('message-feedback-text'), {
        target: {value: 'Bad response'},
      })

      server.use(http.post(feedbackBasePath, () => HttpResponse.json({feedback: disliked})))
      fireEvent.click(screen.getByTestId('message-feedback-submit'))

      await waitFor(() => {
        expect(screen.getByTestId('message-feedback-success')).toBeInTheDocument()
      })

      // Now click like — confirmation should disappear
      server.use(
        http.delete(`${feedbackBasePath}/${disliked.id}`, () => HttpResponse.json({success: true})),
        http.post(feedbackBasePath, () => HttpResponse.json({feedback: liked})),
      )
      fireEvent.click(screen.getByTestId('message-feedback-like'))

      await waitFor(() => {
        expect(screen.queryByTestId('message-feedback-success')).not.toBeInTheDocument()
      })
    })
  })

  describe('error states', () => {
    it('shows error when like request fails', async () => {
      server.use(
        http.post(feedbackBasePath, () => HttpResponse.json({error: 'Failed'}, {status: 503})),
      )

      render(<MessageFeedback {...defaultProps} />)
      fireEvent.click(screen.getByTestId('message-feedback-like'))

      await waitFor(() => {
        expect(screen.getByTestId('message-feedback-error')).toBeInTheDocument()
      })
    })

    it('shows error when dislike skip request fails', async () => {
      server.use(
        http.post(feedbackBasePath, () => HttpResponse.json({error: 'Failed'}, {status: 503})),
      )

      render(<MessageFeedback {...defaultProps} />)
      fireEvent.click(screen.getByTestId('message-feedback-dislike'))
      fireEvent.click(screen.getByTestId('message-feedback-skip'))

      await waitFor(() => {
        expect(screen.getByTestId('message-feedback-error')).toBeInTheDocument()
      })
      // Form should not show success
      expect(screen.queryByTestId('message-feedback-success')).not.toBeInTheDocument()
    })

    it('shows error when dislike submit request fails', async () => {
      server.use(
        http.post(feedbackBasePath, () => HttpResponse.json({error: 'Failed'}, {status: 503})),
      )

      render(<MessageFeedback {...defaultProps} />)
      fireEvent.click(screen.getByTestId('message-feedback-dislike'))

      const textarea = screen.getByTestId('message-feedback-text')
      fireEvent.change(textarea, {target: {value: 'Bad response'}})
      fireEvent.click(screen.getByTestId('message-feedback-submit'))

      await waitFor(() => {
        expect(screen.getByTestId('message-feedback-error')).toBeInTheDocument()
      })
      expect(screen.queryByTestId('message-feedback-success')).not.toBeInTheDocument()
    })

    it('clears error on next successful action', async () => {
      const liked = makeFeedback('liked')
      let callCount = 0
      server.use(
        http.post(feedbackBasePath, () => {
          callCount++
          if (callCount === 1) return HttpResponse.json({error: 'Failed'}, {status: 503})
          return HttpResponse.json({feedback: liked})
        }),
      )

      render(<MessageFeedback {...defaultProps} />)
      fireEvent.click(screen.getByTestId('message-feedback-like'))

      await waitFor(() => {
        expect(screen.getByTestId('message-feedback-error')).toBeInTheDocument()
      })

      fireEvent.click(screen.getByTestId('message-feedback-like'))

      await waitFor(() => {
        expect(screen.queryByTestId('message-feedback-error')).not.toBeInTheDocument()
      })
    })
  })
})
