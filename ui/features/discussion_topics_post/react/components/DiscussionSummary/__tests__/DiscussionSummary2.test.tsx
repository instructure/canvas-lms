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
import {render, waitFor} from '@testing-library/react'
import {DiscussionSummary, DiscussionSummaryProps} from '../DiscussionSummary'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {MockedProvider} from '@apollo/client/testing'
import doFetchApi from '@canvas/do-fetch-api-effect'
import userEvent from '@testing-library/user-event'
import fakeENV from '@canvas/test-utils/fakeENV'

jest.mock('@canvas/do-fetch-api-effect')

declare const ENV: {
  discussion_topic_id: string
  context_id: string
  context_type: string
}

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

    // Reset mocks between tests
    jest.clearAllMocks()
  })

  afterEach(() => {
    ;(doFetchApi as jest.Mock).mockClear()
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  describe('Rendering', () => {
    it('should display loading state initially', () => {
      const {getByTestId} = setup()

      expect(getByTestId('summary-loading')).toHaveTextContent('Loading discussion summary...')
    })

    it('should display generic error message when there is an error', async () => {
      ;(doFetchApi as jest.Mock).mockImplementationOnce(() =>
        Promise.reject(new Error('Some error message')),
      )

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

    it('should display the specific error message when there is an API error with a specific error message', async () => {
      // Mock an API error with a specific error message in the response
      const mockJson = jest.fn().mockResolvedValue({error: 'Some error message.'})
      ;(doFetchApi as jest.Mock).mockImplementationOnce(() =>
        Promise.reject({
          response: {
            json: mockJson,
            status: 500,
          },
        }),
      )

      const {getByTestId} = setup()

      expect(doFetchApi).toHaveBeenCalledWith({
        method: 'GET',
        path: `/api/v1/courses/${ENV.context_id}/discussion_topics/${ENV.discussion_topic_id}/summaries`,
      })

      // The component should show the specific error message from the API response
      await waitFor(() => {
        expect(getByTestId('summary-error')).toHaveTextContent('Some error message.')
      })
    })

    it('should not display the response error message when the error status is 404', async () => {
      const mockJson = jest.fn().mockResolvedValue({error: 'Some error message.'})
      ;(doFetchApi as jest.Mock).mockImplementationOnce(() =>
        Promise.reject({
          response: {
            json: mockJson,
            status: 404,
          },
        }),
      )

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
      ;(doFetchApi as jest.Mock).mockResolvedValue({
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
        postDiscussionSummaryFeedback,
      })

      expect(postDiscussionSummaryFeedback).toHaveBeenCalledWith('seen')
    })

    it('should reset and call setSummary with the latest generated discussion summary with group context', async () => {
      window.ENV = {
        ...window.ENV,
        // @ts-expect-error
        context_type: 'Group',
      }
      ;(doFetchApi as jest.Mock).mockResolvedValue({
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

        const alert = getByText(
          /The discussion board has some new activity since this summary was generated/,
        )
        expect(alert).toBeInTheDocument()
      })

      it('should not display an alert when the summary is not obsolete', async () => {
        const {queryByText} = setup({
          summary: expectedSummary,
        })

        const alert = queryByText(
          /The discussion board has some new activity since this summary was generated/,
        )
        expect(alert).not.toBeInTheDocument()
      })
    })
  })
})
