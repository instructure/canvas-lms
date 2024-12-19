/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, waitFor, fireEvent} from '@testing-library/react'
import {DiscussionSummary} from '../DiscussionSummary'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {MockedProvider} from '@apollo/client/testing'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv'

jest.mock('@canvas/do-fetch-api-effect')

const setup = (props = {}) => {
  const defaultProps = {
    onDisableSummaryClick: jest.fn(),
    breakpoints: {mobileOnly: false},
    ...props,
  }

  return render(
    <MockedProvider>
      <AlertManagerContext.Provider
        // @ts-expect-error
        value={{setOnFailure: props.setOnFailure || jest.fn(), setOnSuccess: jest.fn()}}
      >
        {/* @ts-expect-error */}
        <DiscussionSummary {...defaultProps} />
      </AlertManagerContext.Provider>
    </MockedProvider>
  )
}

describe('DiscussionSummary', () => {
  let oldEnv: GlobalEnv

  beforeEach(() => {
    oldEnv = window.ENV
    window.ENV = {
      ...window.ENV,
      // @ts-expect-error
      discussion_topic_id: '5678',
      context_id: '1234',
      context_type: 'Course',
    }
  })

  afterEach(() => {
    // @ts-expect-error
    doFetchApi.mockClear()
  })

  afterAll(() => {
    window.ENV = oldEnv
  })

  describe('Rendering', () => {
    it('should display loading state initially', () => {
      const {getByTestId} = setup()

      expect(getByTestId('summary-loading')).toHaveTextContent('Loading discussion summary...')
    })

    it('should display generic error message when there is an error', async () => {
      // @ts-expect-error
      doFetchApi.mockRejectedValue(new Error('Some error message'))

      const {getByTestId} = setup()

      expect(doFetchApi).toHaveBeenCalledWith({
        method: 'GET',
        // @ts-expect-error
        path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries`,
        params: {userInput: ''},
      })
      await waitFor(() => {
        expect(getByTestId('summary-error')).toHaveTextContent(
          'An unexpected error occurred while loading the discussion summary.'
        )
      })
    })

    it('should display the response error message when there is an error', async () => {
      // @ts-expect-error
      doFetchApi.mockRejectedValue({
        response: {
          json: async () => {
            return {error: 'Some error message.'}
          },
        },
      })

      const {getByTestId} = setup()

      expect(doFetchApi).toHaveBeenCalledWith({
        method: 'GET',
        // @ts-expect-error
        path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries`,
        params: {userInput: ''},
      })
      await waitFor(() => {
        expect(getByTestId('summary-error')).toHaveTextContent('Some error message.')
      })
    })

    it('should render course discussion summary text when loaded', async () => {
      // @ts-expect-error
      doFetchApi.mockResolvedValue({
        json: {id: 1, text: 'This is a discussion summary'},
      })

      const {getByTestId} = setup()

      expect(doFetchApi).toHaveBeenCalledWith({
        method: 'GET',
        // @ts-expect-error
        path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries`,
        params: {userInput: ''},
      })
      await waitFor(() => {
        expect(getByTestId('summary-text')).toHaveTextContent('This is a discussion summary')
      })
      expect(doFetchApi).toHaveBeenCalledWith({
        method: 'POST',
        // @ts-expect-error
        path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${
          // @ts-expect-error
          ENV.discussion_topic_id
        }/summaries/${1}/feedback`,
        body: {
          _action: 'seen',
        },
      })
    })

    it('should render group discussion summary text when loaded', async () => {
      window.ENV = {
        ...window.ENV,
        // @ts-expect-error
        context_type: 'Group',
      }

      // @ts-expect-error
      doFetchApi.mockResolvedValue({
        json: {id: 1, text: 'This is a discussion summary'},
      })

      const {getByTestId} = setup()

      expect(doFetchApi).toHaveBeenCalledWith({
        method: 'GET',
        // @ts-expect-error
        path: `/api/v1/groups/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries`,
        params: {userInput: ''},
      })
      await waitFor(() => {
        expect(getByTestId('summary-text')).toHaveTextContent('This is a discussion summary')
      })
      expect(doFetchApi).toHaveBeenCalledWith({
        method: 'POST',
        // @ts-expect-error
        path: `/api/v1/groups/${ENV.context_id}/discussion_topics/${
          // @ts-expect-error
          ENV.discussion_topic_id
        }/summaries/${1}/feedback`,
        body: {
          _action: 'seen',
        },
      })
    })
  })

  describe('Interactions', () => {
    beforeEach(() => {
      // @ts-expect-error
      doFetchApi.mockResolvedValueOnce({json: {id: 1, text: 'This is a discussion summary'}})
    })

    it('should disable summary when disable button is clicked', async () => {
      // @ts-expect-error
      doFetchApi.mockResolvedValueOnce({json: {liked: false, disliked: false}})
      // @ts-expect-error
      doFetchApi.mockResolvedValueOnce({json: {liked: false, disliked: false}})
      // @ts-expect-error
      doFetchApi.mockResolvedValueOnce({json: {success: true}})

      const {getByTestId} = setup()

      // @ts-expect-error
      let disableButton
      await waitFor(() => {
        disableButton = getByTestId('summary-disable-button')
      })
      await waitFor(() => {
        // @ts-expect-error
        fireEvent.click(disableButton)
      })

      // @ts-expect-error
      expect(doFetchApi.mock.calls).toEqual([
        [
          {
            method: 'GET',
            // @ts-expect-error
            path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries`,
            params: {userInput: ''},
          },
        ],
        [
          {
            method: 'POST',
            // @ts-expect-error
            path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries/1/feedback`,
            body: {
              _action: 'seen',
            },
          },
        ],
        [
          {
            method: 'POST',
            // @ts-expect-error
            path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries/1/feedback`,
            body: {
              _action: 'disable_summary',
            },
          },
        ],
        [
          {
            method: 'PUT',
            // @ts-expect-error
            path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries/disable`,
          },
        ],
      ])
    })

    it('should generate summary for user input when generate button is clicked', async () => {
      // @ts-expect-error
      doFetchApi.mockResolvedValueOnce({json: {liked: false, disliked: false}})
      // @ts-expect-error
      doFetchApi.mockResolvedValueOnce({
        json: {id: 2, text: 'This is some other discussion summary'},
      })
      // @ts-expect-error
      doFetchApi.mockResolvedValueOnce({json: {liked: false, disliked: false}})

      const {getByTestId} = setup()

      // @ts-expect-error
      let generateButton, userInput
      await waitFor(() => {
        generateButton = getByTestId('summary-generate-button')
        userInput = getByTestId('summary-user-input')
      })
      await waitFor(() => {
        // @ts-expect-error
        fireEvent.change(userInput, {target: {value: 'focus on student feedback'}})
      })
      await waitFor(() => {
        // @ts-expect-error
        fireEvent.click(generateButton)
      })

      // @ts-expect-error
      expect(doFetchApi.mock.calls).toEqual([
        [
          {
            method: 'GET',
            // @ts-expect-error
            path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries`,
            params: {userInput: ''},
          },
        ],
        [
          {
            method: 'POST',
            // @ts-expect-error
            path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries/1/feedback`,
            body: {
              _action: 'seen',
            },
          },
        ],
        [
          {
            method: 'GET',
            params: {userInput: 'focus on student feedback'},
            // @ts-expect-error
            path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries`,
          },
        ],
        [
          {
            method: 'POST',
            // @ts-expect-error
            path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries/2/feedback`,
            body: {
              _action: 'seen',
            },
          },
        ],
      ])
    })

    it('should toggle like state when like/dislike button is clicked', async () => {
      // @ts-expect-error
      doFetchApi.mockResolvedValueOnce({json: {liked: false, disliked: false}})
      // @ts-expect-error
      doFetchApi.mockResolvedValueOnce({json: {liked: true, disliked: false}})
      // @ts-expect-error
      doFetchApi.mockResolvedValueOnce({json: {liked: false, disliked: true}})
      // @ts-expect-error
      doFetchApi.mockResolvedValueOnce({json: {liked: false, disliked: false}})

      const {getByTestId} = setup()

      // @ts-expect-error
      let likeButton, dislikeButton
      await waitFor(() => {
        likeButton = getByTestId('summary-like-button')
        dislikeButton = getByTestId('summary-dislike-button')
      })
      await waitFor(() => {
        // @ts-expect-error
        fireEvent.click(likeButton)
      })
      await waitFor(() => {
        // @ts-expect-error
        fireEvent.click(dislikeButton)
      })
      await waitFor(() => {
        // @ts-expect-error
        fireEvent.click(dislikeButton)
      })

      // @ts-expect-error
      expect(doFetchApi.mock.calls).toEqual([
        [
          {
            method: 'GET',
            // @ts-expect-error
            path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries`,
            params: {userInput: ''},
          },
        ],
        [
          {
            method: 'POST',
            // @ts-expect-error
            path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries/1/feedback`,
            body: {
              _action: 'seen',
            },
          },
        ],
        [
          {
            method: 'POST',
            // @ts-expect-error
            path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries/1/feedback`,
            body: {
              _action: 'like',
            },
          },
        ],
        [
          {
            method: 'POST',
            // @ts-expect-error
            path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries/1/feedback`,
            body: {
              _action: 'dislike',
            },
          },
        ],
        [
          {
            method: 'POST',
            // @ts-expect-error
            path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries/1/feedback`,
            body: {
              _action: 'reset_like',
            },
          },
        ],
      ])
    })

    it('should handle feedback submission failure', async () => {
      // @ts-expect-error
      doFetchApi.mockRejectedValue(new Error('Some error message'))

      const setOnFailure = jest.fn()
      setup({setOnFailure})

      await waitFor(() => {})

      // @ts-expect-error
      expect(doFetchApi.mock.calls).toEqual([
        [
          {
            method: 'GET',
            // @ts-expect-error
            path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries`,
            params: {userInput: ''},
          },
        ],
        [
          {
            method: 'POST',
            // @ts-expect-error
            path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries/1/feedback`,
            body: {
              _action: 'seen',
            },
          },
        ],
      ])
      expect(setOnFailure).toHaveBeenCalledWith(
        'There was an unexpected error while submitting the discussion summary feedback.'
      )
    })
  })
})
