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

import React from 'react'
import {render, waitFor, screen, act} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {MockedProvider} from '@apollo/client/testing'
import {CommentLibraryContent} from '../CommentLibrary'
import {InMemoryCache} from '@apollo/client'
import {SpeedGrader_CommentBankItemsCount, SpeedGrader_CommentBankItems} from '../graphql/queries'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('CommentLibrary', () => {
  const defaultUserId = '1'
  const defaultCourseId = '1'

  const createCountMock = (userId: string, totalCount: number) => ({
    request: {
      query: SpeedGrader_CommentBankItemsCount,
      variables: {userId},
    },
    result: {
      data: {
        legacyNode: {
          __typename: 'User',
          commentBankItemsConnection: {
            __typename: 'CommentBankItemsConnection',
            pageInfo: {
              __typename: 'PageInfo',
              totalCount,
            },
          },
        },
      },
    },
  })

  const createCommentsMock = (
    userId: string,
    courseId: string,
    comments: Array<{_id: string; comment: string}> = [
      {_id: 'comment-1', comment: 'Great work!'},
      {_id: 'comment-2', comment: 'Needs improvement'},
      {_id: 'comment-3', comment: 'Well done'},
    ],
  ) => ({
    request: {
      query: SpeedGrader_CommentBankItems,
      variables: {userId, courseId, first: 20, after: ''},
    },
    result: {
      data: {
        legacyNode: {
          __typename: 'User',
          commentBankItemsConnection: {
            __typename: 'CommentBankItemConnection',
            nodes: comments,
            pageInfo: {
              __typename: 'PageInfo',
              hasNextPage: false,
              endCursor: null,
            },
          },
        },
      },
    },
  })

  const setup = (mocks: any[], props = {}) => {
    const defaultProps = {
      userId: defaultUserId,
      courseId: defaultCourseId,
      setComment: jest.fn(),
      setFocusToTextArea: jest.fn(),
      ...props,
    }

    const cache = new InMemoryCache({
      typePolicies: {
        User: {
          fields: {
            commentBankItemsConnection: {
              keyArgs: ['courseId'],
              merge(existing, incoming) {
                if (!existing) return incoming
                return {
                  ...incoming,
                  nodes: [...existing.nodes, ...incoming.nodes],
                }
              },
            },
          },
        },
      },
    })

    return render(
      <MockedProvider mocks={mocks} addTypename={true} cache={cache}>
        <CommentLibraryContent {...defaultProps} />
      </MockedProvider>,
    )
  }

  beforeEach(() => {
    fakeENV.setup({comment_library_suggestions_enabled: true})
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  describe('Rendering Tests', () => {
    it('does not render button until data loads', () => {
      const mocks = [createCountMock(defaultUserId, 10)]
      const {queryByTestId} = setup(mocks)

      // Button should not be visible during initial loading state
      // (Spinner has 500ms delay to prevent flickering on fast loads)
      expect(queryByTestId('comment-library-button')).not.toBeInTheDocument()
    })

    it('renders button with comment count when data loads', async () => {
      const mocks = [createCountMock(defaultUserId, 10)]
      const {getByTestId, getByText} = setup(mocks)

      await waitFor(() => {
        expect(getByTestId('comment-library-button')).toBeInTheDocument()
      })

      expect(getByTestId('comment-library-count')).toHaveTextContent('10')
      expect(getByText('Open Comment Library')).toBeInTheDocument()
    })
  })

  describe('Count Display Logic Tests', () => {
    it('displays exact count for 0', async () => {
      const mocks = [createCountMock(defaultUserId, 0)]
      const {getByTestId} = setup(mocks)

      await waitFor(() => {
        expect(getByTestId('comment-library-count')).toHaveTextContent('0')
      })
    })

    it('displays exact count for 50', async () => {
      const mocks = [createCountMock(defaultUserId, 50)]
      const {getByTestId} = setup(mocks)

      await waitFor(() => {
        expect(getByTestId('comment-library-count')).toHaveTextContent('50')
      })
    })

    it('displays exact count for 99', async () => {
      const mocks = [createCountMock(defaultUserId, 99)]
      const {getByTestId} = setup(mocks)

      await waitFor(() => {
        expect(getByTestId('comment-library-count')).toHaveTextContent('99')
      })
    })

    it('displays "99+" for count of 100', async () => {
      const mocks = [createCountMock(defaultUserId, 100)]
      const {getByTestId} = setup(mocks)

      await waitFor(() => {
        expect(getByTestId('comment-library-count')).toHaveTextContent('99+')
      })
    })

    it('displays "99+" for count of 500', async () => {
      const mocks = [createCountMock(defaultUserId, 500)]
      const {getByTestId} = setup(mocks)

      await waitFor(() => {
        expect(getByTestId('comment-library-count')).toHaveTextContent('99+')
      })
    })
  })

  describe('Feature Flag Tests', () => {
    it('renders button without tooltip when suggestions are enabled', async () => {
      fakeENV.setup({comment_library_suggestions_enabled: true})
      const mocks = [createCountMock(defaultUserId, 10)]
      const {getByTestId, queryByText} = setup(mocks)

      await waitFor(() => {
        expect(getByTestId('comment-library-button')).toBeInTheDocument()
      })

      expect(queryByText('Comment Library (Suggestions Disabled)')).not.toBeInTheDocument()
    })

    it('renders button with tooltip when suggestions are disabled', async () => {
      fakeENV.setup({comment_library_suggestions_enabled: false})
      const mocks = [createCountMock(defaultUserId, 10)]
      const {getByTestId, getByText} = setup(mocks)

      await waitFor(() => {
        expect(getByTestId('comment-library-button')).toBeInTheDocument()
      })

      // Tooltip text should be in the document
      expect(getByText('Comment Library (Suggestions Disabled)')).toBeInTheDocument()
    })
  })

  describe('GraphQL Error Handling', () => {
    it('does not show button on query error', async () => {
      const mocks = [
        {
          request: {
            query: SpeedGrader_CommentBankItemsCount,
            variables: {userId: defaultUserId},
          },
          error: new Error('GraphQL error'),
        },
      ]
      const {queryByTestId} = setup(mocks)

      // Should not show button initially
      expect(queryByTestId('comment-library-button')).not.toBeInTheDocument()

      await waitFor(
        () => {
          // Should still not show button after error
          expect(queryByTestId('comment-library-button')).not.toBeInTheDocument()
        },
        {timeout: 3000},
      )
    })
  })

  describe('setCommentFromLibrary callback', () => {
    it('calls setComment and setFocusToTextArea when comment is selected', async () => {
      jest.useFakeTimers()
      const user = userEvent.setup({delay: null})
      const setComment = jest.fn()
      const setFocusToTextArea = jest.fn()
      const mocks = [
        createCountMock(defaultUserId, 3),
        createCommentsMock(defaultUserId, defaultCourseId),
      ]

      setup(mocks, {setComment, setFocusToTextArea})

      await waitFor(() => {
        expect(screen.getByTestId('comment-library-button')).toBeInTheDocument()
      })

      await user.click(screen.getByTestId('comment-library-button'))

      await waitFor(() => {
        expect(screen.getByText('Great work!')).toBeInTheDocument()
      })

      // Select a comment
      await user.click(screen.getByText('Great work!'))

      // Verify comment is set
      expect(setComment).toHaveBeenCalledWith('Great work!')

      // setFocusToTextArea should not be called yet (async timeout)
      expect(setFocusToTextArea).not.toHaveBeenCalled()

      // Fast-forward timers to trigger async focus
      act(() => {
        jest.runAllTimers()
      })

      // Now setFocus should be called
      expect(setFocusToTextArea).toHaveBeenCalled()

      jest.useRealTimers()
    })

    it('closes tray after comment selection', async () => {
      const user = userEvent.setup()
      const setComment = jest.fn()
      const setFocusToTextArea = jest.fn()
      const mocks = [
        createCountMock(defaultUserId, 3),
        createCommentsMock(defaultUserId, defaultCourseId),
      ]

      setup(mocks, {setComment, setFocusToTextArea})

      await waitFor(() => {
        expect(screen.getByTestId('comment-library-button')).toBeInTheDocument()
      })

      await user.click(screen.getByTestId('comment-library-button'))

      await waitFor(() => {
        expect(screen.getByText('Great work!')).toBeInTheDocument()
      })

      // Select a comment
      await user.click(screen.getByText('Great work!'))

      // Verify tray closes
      await waitFor(() => {
        expect(screen.queryByText('Manage Comment Library')).not.toBeInTheDocument()
      })
    })
  })
})
