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
import {DiscussionSummaryRatings} from '../DiscussionSummaryRatings'
import {useScope as createI18nScope} from '@canvas/i18n'
import fakeENV from '@canvas/test-utils/fakeENV'

jest.mock('@canvas/do-fetch-api-effect')

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
    obsolete: false,
    usage: {currentCount: 3, limit: 5},
  }

  beforeEach(() => {
    fakeENV.setup({
      discussion_topic_id: '5678',
      context_id: '1234',
      context_type: 'Course',
    })
    // Reset mock for each test
    jest.clearAllMocks()
    ;(doFetchApi as jest.Mock).mockReset()
  })

  afterEach(() => {
    fakeENV.teardown()
    ;(doFetchApi as jest.Mock).mockClear()
  })
  describe('DiscussionSummaryUsagePill', () => {
    it('should display a pill with summary usage information and an enabled Generate button if some usage left', async () => {
      ;(doFetchApi as jest.Mock).mockImplementationOnce(() =>
        Promise.resolve({
          json: expectedSummary,
        }),
      )

      const {getByTestId} = setup({
        summary: null,
      })

      await waitFor(() => {
        const pill = getByTestId('summary-usage-pill')
        expect(pill).toHaveTextContent('3 / 5')
      })

      await waitFor(() => {
        const generateButton = getByTestId('summary-generate-button')
        expect(generateButton).not.toBeDisabled()
      })
    })

    it('should display a pill with summary usage information and a disabled Generate button if no usage left', async () => {
      ;(doFetchApi as jest.Mock).mockImplementationOnce(() =>
        Promise.resolve({
          json: {id: 1, text: 'This is a discussion summary', usage: {currentCount: 5, limit: 5}},
        }),
      )

      const {getByTestId} = setup({
        summary: null,
      })

      await waitFor(() => {
        const pill = getByTestId('summary-usage-pill')
        expect(pill).toHaveTextContent('5 / 5')
      })

      await waitFor(() => {
        const generateButton = getByTestId('summary-generate-button')
        expect(generateButton).toBeDisabled()
      })
    })
  })

  describe('Interactions', () => {
    beforeEach(() => {
      ;(doFetchApi as jest.Mock).mockResolvedValueOnce({json: expectedSummary})
    })

    it('should call onDisableSummaryClick when disable button is clicked', async () => {
      const onDisableSummaryClick = jest.fn()
      const {getByTestId} = setup({
        summary: expectedSummary,
        onDisableSummaryClick: onDisableSummaryClick,
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
        // @ts-expect-error
        path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries`,
        params: {userInput: 'focus on student feedback'},
      })
    })

    it('should call postDiscussionSummaryFeedback with like when like button is clicked', async () => {
      ;(doFetchApi as jest.Mock).mockResolvedValueOnce({json: {liked: false, disliked: false}})
      ;(doFetchApi as jest.Mock).mockResolvedValueOnce({json: {liked: true, disliked: false}})

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
      // Setup mocks specifically for this test
      const mockFetchApi = doFetchApi as jest.Mock
      mockFetchApi.mockImplementation(() =>
        Promise.resolve({json: {liked: false, disliked: false}}),
      )

      const setDisliked = jest.fn()
      const postDiscussionSummaryFeedback = jest.fn().mockResolvedValue({})

      const {getByTestId} = setup({
        summary: expectedSummary,
        postDiscussionSummaryFeedback,
        liked: false,
        disliked: false,
        onSetDisliked: setDisliked,
      })

      // Find the dislike button
      const dislikeButton = await waitFor(() => getByTestId('summary-dislike-button'))
      expect(dislikeButton).toBeInTheDocument()

      // Click the dislike button
      await waitFor(() => {
        fireEvent.click(dislikeButton)
      })

      // Verify the expected function calls
      expect(postDiscussionSummaryFeedback).toHaveBeenCalledWith('seen')
      expect(postDiscussionSummaryFeedback).toHaveBeenCalledWith('dislike')
    })

    it('should call postDiscussionSummaryFeedback with reset_like when dislike is true and dislike button is clicked', async () => {
      // Setup mocks specifically for this test
      const mockFetchApi = doFetchApi as jest.Mock
      mockFetchApi.mockImplementation(() => Promise.resolve({json: {liked: false, disliked: true}}))

      const setDisliked = jest.fn()
      const postDiscussionSummaryFeedback = jest.fn().mockResolvedValue({})

      const {getByTestId} = setup({
        summary: expectedSummary,
        postDiscussionSummaryFeedback,
        liked: false,
        disliked: true, // Already disliked
        onSetDisliked: setDisliked,
      })

      // Find the dislike button
      const dislikeButton = await waitFor(() => getByTestId('summary-dislike-button'))
      expect(dislikeButton).toBeInTheDocument()

      // Click the dislike button
      await waitFor(() => {
        fireEvent.click(dislikeButton)
      })

      // Verify the expected function calls
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
      const {getByText} = render(<DiscussionSummaryRatings {...defaultProps} />)
      expect(getByText(I18n.t('Do you like this summary?'))).toBeInTheDocument()
    })

    it('should display "Thank you for sharing!" when liked is true', () => {
      const {getByText} = render(<DiscussionSummaryRatings {...defaultProps} liked={true} />)
      expect(getByText(I18n.t('Thank you for sharing!'))).toBeInTheDocument()
    })

    it('should display "Thank you for sharing!" when disliked is true', () => {
      const {getByText} = render(<DiscussionSummaryRatings {...defaultProps} disliked={true} />)
      expect(getByText(I18n.t('Thank you for sharing!'))).toBeInTheDocument()
    })
  })
})
