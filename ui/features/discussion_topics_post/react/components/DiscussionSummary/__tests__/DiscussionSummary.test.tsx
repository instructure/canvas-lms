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
import {DiscussionSummary, DiscussionSummaryProps} from '../DiscussionSummary'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {MockedProvider} from '@apollo/client/testing'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv'
import {DiscussionSummaryRatings} from '../DiscussionSummaryRatings'
import {useScope as createI18nScope} from '@canvas/i18n'
import userEvent from '@testing-library/user-event'

jest.mock('@canvas/do-fetch-api-effect')

declare const ENV: {
  discussion_topic_id: string
  context_id: string
  context_type: string
}

const I18n = createI18nScope('discussion_posts')

const setup = (props: Partial<DiscussionSummaryProps> = {}) => {
  const defaultProps: DiscussionSummaryProps = {
    onDisableSummaryClick: jest.fn(),
    isMobile: false,
    summary: null,
    onSetSummary: jest.fn(),
    isFeedbackLoading: false,
    onSetIsFeedbackLoading: jest.fn(),
    liked: false,
    onSetLiked: jest.fn(),
    disliked: false,
    onSetDisliked: jest.fn(),
    postDiscussionSummaryFeedback: jest.fn().mockResolvedValue(Promise.resolve()),
    ...props,
  }

  return render(
    <MockedProvider>
      <AlertManagerContext.Provider
      // @ts-expect-error
      value={{setOnFailure: props.setOnFailure || jest.fn(), setOnSuccess: jest.fn()}}
      >
        <DiscussionSummary {...defaultProps} />
      </AlertManagerContext.Provider>
    </MockedProvider>,
  )
}

describe('DiscussionSummary', () => {
  const expectedSummary = {
    id: 1,
    text: 'This is a discussion summary',
    obsolete: false
  }
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
    (doFetchApi as jest.Mock).mockClear()
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
      (doFetchApi as jest.Mock).mockRejectedValue(new Error('Some error message'))

      const {getByTestId} = setup()

      expect(doFetchApi).toHaveBeenCalledWith({
        method: 'GET',
        path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries`,
      })
      await waitFor(() => {
        expect(getByTestId('summary-error')).toHaveTextContent(
          'An unexpected error occurred while loading the discussion summary.',
        )
      })
    })

    it('should display the response error message when there is an error', async () => {
      (doFetchApi as jest.Mock).mockRejectedValue({
        response: {
          json: async () => {
            return {error: 'Some error message.'}
          },
        },
      })

      const {getByTestId} = setup()

      expect(doFetchApi).toHaveBeenCalledWith({
        method: 'GET',
        path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries`,
      })
      await waitFor(() => {
        expect(getByTestId('summary-error')).toHaveTextContent('Some error message.')
      })
    })

    it('should not display the response error message when the error status is 404', async () => {
      (doFetchApi as jest.Mock).mockRejectedValue({
        response: {
          json: async () => {
            return {error: 'Some error message.'}
          },
          status: 404,
        },
      })

      const {queryByTestId} = setup()

      expect(doFetchApi).toHaveBeenCalledWith({
        method: 'GET',
        path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries`,
      })
      await waitFor(() => {
        expect(queryByTestId('summary-error')).not.toBeInTheDocument()
      })
    })

    it('should reset and call setSummary with the latest generated discussion summary in course context', async () => {
      (doFetchApi as jest.Mock).mockResolvedValue({
        json: expectedSummary,
      })
      const setSummary = jest.fn()
      setup({onSetSummary: setSummary})

      expect(setSummary).toHaveBeenNthCalledWith(1, null)
      await waitFor(() => {
        expect(setSummary).toHaveBeenNthCalledWith(2, expectedSummary)
      })
    })

    it('should render course discussion summary text when provided', async () => {
      const {getByTestId} = setup({
        summary: expectedSummary,
      })

      expect(getByTestId('summary-text')).toHaveTextContent(expectedSummary.text)
    })

    it('should call postDiscussionSummaryFeedback when summary is provided', async () => {
      const postDiscussionSummaryFeedback = jest.fn()
      setup({
        summary: expectedSummary,
        postDiscussionSummaryFeedback
      })

      expect(postDiscussionSummaryFeedback).toHaveBeenCalledWith('seen')
    })

    it('should reset and call setSummary with the latest generated discussion summary with group context', async () => {
      window.ENV = {
        ...window.ENV,
        // @ts-expect-error
        context_type: 'Group',
      };
      (doFetchApi as jest.Mock).mockResolvedValue({
        json: expectedSummary,
      })
      const setSummary = jest.fn()
      setup({onSetSummary: setSummary})

      expect(setSummary).toHaveBeenNthCalledWith(1, null)
      await waitFor(() => {
        expect(setSummary).toHaveBeenNthCalledWith(2, expectedSummary)
      })
      expect(doFetchApi).toHaveBeenCalledWith({
        method: 'GET',
        path: `/api/v1/groups/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries`,
      })
    })

    describe('Generate Button', () => {
      it('generate button is enabled when not loading and user input is changed', async () => {
        const {getByTestId} = setup({
          summary: expectedSummary,
        })

        const generateButton = getByTestId('summary-generate-button')
        expect(generateButton).toBeDisabled()

        const userInput = getByTestId('summary-user-input')
        await userEvent.click(userInput)
        await userEvent.type(userInput, 'text')

        expect(generateButton).toBeEnabled()
      })

      it('generate button is enabled when not loading and there is no initial summary', async () => {
        const {getByTestId} = setup({
          summary: undefined,
        })

        const generateButton = getByTestId('summary-generate-button')
        expect(generateButton).toBeEnabled()
      })

      it('generate button is enabled when not loading and the summary is obsolete', async () => {
        const {getByTestId} = setup({
          summary: {...expectedSummary, obsolete: true},
        })

        const generateButton = getByTestId('summary-generate-button')
        expect(generateButton).toBeEnabled()
      })

      it('generate button is disabled when summary is loading', async () => {
        const {getByTestId} = setup({
          summary: null,
        })

        const generateButton = getByTestId('summary-generate-button')
        expect(generateButton).toBeDisabled()
      })

      it('generate button is disabled when feedback is loading', async () => {
        const {getByTestId} = setup({
          summary: expectedSummary,
          isFeedbackLoading: true,
        })

        const generateButton = getByTestId('summary-generate-button')
        expect(generateButton).toBeDisabled()
      })

      it('generate button is disabled when not loading and summary is available, not obsolete and user input is not changed', async () => {
        const {getByTestId} = setup({
          summary: expectedSummary,
        })

        const generateButton = getByTestId('summary-generate-button')
        expect(generateButton).toBeDisabled()
      })
    })

    describe('Obsolete alert', () => {
      it('should display an alert when the summary is obsolete', async () => {
        const {getByText} = setup({
          summary: {...expectedSummary, obsolete: true},
        })

        const alert = getByText(/There have been new replies since this summary/)
        expect(alert).toBeInTheDocument()
      })

      it('should not display an alert when the summary is not obsolete', async () => {
        const {queryByText} = setup({
          summary: expectedSummary,
        })

        const alert = queryByText(/There have been new replies since this summary/)
        expect(alert).not.toBeInTheDocument()
      })
    })
   })

  describe('Interactions', () => {
    beforeEach(() => {
      (doFetchApi as jest.Mock).mockResolvedValueOnce({json: expectedSummary})
    })

    it('should call onDisableSummaryClick when disable button is clicked', async () => {
      const onDisableSummaryClick = jest.fn()
      const {getByTestId} = setup({
        summary: expectedSummary,
        onDisableSummaryClick: onDisableSummaryClick
      })

      let disableButton: HTMLElement | null = null
      await waitFor(() => {
      disableButton = getByTestId('summary-disable-icon-button')
      })
      await waitFor(() => {
        fireEvent.click(disableButton!)
      })

      expect(onDisableSummaryClick).toHaveBeenCalled()
    })

    it('should call fetchSummary with correct parameters when generate button is clicked', async () => {
      const {getByTestId} = setup({
        summary: expectedSummary,
      })

      let generateButton: HTMLElement | null = null
      let userInput: HTMLElement | null = null
      await waitFor(() => {
        generateButton = getByTestId('summary-generate-button')
        userInput = getByTestId('summary-user-input')
      })
      await waitFor(() => {
        fireEvent.change(userInput!, {target: {value: 'focus on student feedback'}})
      })
      await waitFor(() => {
        fireEvent.click(generateButton!)
      })

      expect(doFetchApi).toHaveBeenCalledWith({
        method: 'POST',
        path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries`,
        params: {userInput: 'focus on student feedback'},
      })
    })

    it('should call postDiscussionSummaryFeedback with like when like button is clicked', async () => {
      (doFetchApi as jest.Mock).mockResolvedValueOnce({json: {liked: false, disliked: false}});
      (doFetchApi as jest.Mock).mockResolvedValueOnce({json: {liked: true, disliked: false}})

      const setLiked = jest.fn()
      const postDiscussionSummaryFeedback = jest.fn()
      const {getByTestId} = setup({
        summary: expectedSummary,
        postDiscussionSummaryFeedback,
        liked: false,
        disliked: false,
        onSetLiked: setLiked,
      })
      let likeButton: HTMLElement | null = null
      await waitFor(() => {
        likeButton = getByTestId('summary-like-button')
      })
      await waitFor(() => {
        fireEvent.click(likeButton!)
      })

      expect(postDiscussionSummaryFeedback).toHaveBeenCalledWith('seen')
      expect(postDiscussionSummaryFeedback).toHaveBeenCalledWith('like')
    })

    it('should call postDiscussionSummaryFeedback with dislike when dislike button is clicked', async () => {
      (doFetchApi as jest.Mock).mockResolvedValueOnce({json: {liked: false, disliked: false}});
      (doFetchApi as jest.Mock).mockResolvedValueOnce({json: {liked: false, disliked: true}})

      const setDisliked = jest.fn()
      const postDiscussionSummaryFeedback = jest.fn()
      const {getByTestId} = setup({
        summary: expectedSummary,
        postDiscussionSummaryFeedback,
        liked: false,
        disliked: false,
        onSetDisliked: setDisliked,
      })
      let dislikeButton: HTMLElement | null = null
      await waitFor(() => {
        dislikeButton = getByTestId('summary-dislike-button')
      })
      await waitFor(() => {
        fireEvent.click(dislikeButton!)
      })

      expect(postDiscussionSummaryFeedback).toHaveBeenCalledWith('seen')
      expect(postDiscussionSummaryFeedback).toHaveBeenCalledWith('dislike')
    })

    it('should call postDiscussionSummaryFeedback with reset_like when dislike is true and dislike button is clicked', async () => {
      (doFetchApi as jest.Mock).mockResolvedValueOnce({json: {liked: false, disliked: true}});
      (doFetchApi as jest.Mock).mockResolvedValueOnce({json: {liked: false, disliked: false}})

      const setDisliked = jest.fn()
      const postDiscussionSummaryFeedback = jest.fn()
      const {getByTestId} = setup({
        summary: expectedSummary,
        postDiscussionSummaryFeedback,
        liked: false,
        disliked: true,
        onSetDisliked: setDisliked,
      })
      let dislikeButton: HTMLElement | null = null
      await waitFor(() => {
        dislikeButton = getByTestId('summary-dislike-button')
      })
      await waitFor(() => {
        fireEvent.click(dislikeButton!)
      })

      expect(postDiscussionSummaryFeedback).toHaveBeenCalledWith('seen')
      expect(postDiscussionSummaryFeedback).toHaveBeenCalledWith('reset_like')
    })
  })

  describe('DiscussionSummaryRatings', () => {
    const defaultProps = {
      onLikeClick: jest.fn(),
      onDislikeClick: jest.fn(),
      liked: false,
      disliked: false,
      isEnabled: true,
    }
  
    it('should display "Do you like this summary?" when neither liked nor disliked', () => {
      const { getByText } = render(<DiscussionSummaryRatings {...defaultProps} />)
      expect(getByText(I18n.t('Do you like this summary?'))).toBeInTheDocument()
    })
  
    it('should display "Thank you for sharing!" when liked is true', () => {
      const { getByText } = render(<DiscussionSummaryRatings {...defaultProps} liked={true} />)
      expect(getByText(I18n.t('Thank you for sharing!'))).toBeInTheDocument()
    })
  
    it('should display "Thank you for sharing!" when disliked is true', () => {
      const { getByText } = render(<DiscussionSummaryRatings {...defaultProps} disliked={true} />)
      expect(getByText(I18n.t('Thank you for sharing!'))).toBeInTheDocument()
    })
  })

})
