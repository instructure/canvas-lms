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
import {
  SpeedGraderLegacy_CommentBankItemsCount,
  SpeedGraderLegacy_CommentBankItems,
} from '../graphql/queries'
import fakeENV from '@canvas/test-utils/fakeENV'
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('use-debounce', () => ({
  useDebounce: jest.fn((value: string) => [value, {isPending: () => false}]),
}))

jest.mock('@canvas/do-fetch-api-effect')

describe('CommentLibrary', () => {
  const defaultUserId = '1'
  const defaultCourseId = '1'

  const createCountMock = (userId: string, totalCount: number) => ({
    request: {
      query: SpeedGraderLegacy_CommentBankItemsCount,
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
      query: SpeedGraderLegacy_CommentBankItems,
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

  const createSuggestionsMock = (
    userId: string,
    query: string,
    suggestions: Array<{_id: string; comment: string}> = [
      {_id: 'suggestion-1', comment: 'Great work on this assignment!'},
      {_id: 'suggestion-2', comment: 'Great job!'},
    ],
  ) => ({
    request: {
      query: SpeedGraderLegacy_CommentBankItems,
      variables: {userId, query, first: 5},
    },
    result: {
      data: {
        legacyNode: {
          __typename: 'User',
          commentBankItemsConnection: {
            __typename: 'CommentBankItemConnection',
            nodes: suggestions,
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
      comment: '',
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
    ;(doFetchApi as jest.Mock).mockResolvedValue({})
  })

  afterEach(() => {
    fakeENV.teardown()
    jest.clearAllMocks()
    jest.useRealTimers()
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
            query: SpeedGraderLegacy_CommentBankItemsCount,
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
    beforeEach(() => {
      const {useDebounce} = require('use-debounce')
      useDebounce.mockReturnValue(['', {isPending: () => false}])
    })

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

  describe('Comment Suggestions Integration', () => {
    describe('Debounced search behavior', () => {
      it('does not trigger query when comment length is less than 3 characters', async () => {
        const mocks = [createCountMock(defaultUserId, 10)]

        setup(mocks, {comment: 'ab'})

        await waitFor(() => {
          expect(screen.getByTestId('comment-library-button')).toBeInTheDocument()
        })

        // No suggestions query should be triggered
        // If it was triggered, we'd get a "No more mocked responses" error
      })

      it('triggers query when comment length is 3 or more characters', async () => {
        const {useDebounce} = require('use-debounce')
        useDebounce.mockReturnValue(['great', {isPending: () => false}])

        const mocks = [
          createCountMock(defaultUserId, 10),
          createSuggestionsMock(defaultUserId, 'great'),
        ]

        setup(mocks, {comment: 'great'})

        await waitFor(() => {
          expect(screen.getByTestId('comment-library-button')).toBeInTheDocument()
        })
      })

      it('strips HTML tags from comment before querying', async () => {
        const {useDebounce} = require('use-debounce')
        useDebounce.mockReturnValue(['hello', {isPending: () => false}])

        const mocks = [
          createCountMock(defaultUserId, 10),
          createSuggestionsMock(defaultUserId, 'hello'),
        ]

        setup(mocks, {comment: '<p>hello</p>'})

        await waitFor(() => {
          expect(screen.getByTestId('comment-library-button')).toBeInTheDocument()
        })
      })

      it('skips query when comment_library_suggestions_enabled is false', async () => {
        fakeENV.setup({comment_library_suggestions_enabled: false})

        const mocks = [createCountMock(defaultUserId, 10)]

        setup(mocks, {comment: 'great work'})

        await waitFor(() => {
          expect(screen.getByTestId('comment-library-button')).toBeInTheDocument()
        })

        // No suggestions query should be triggered
      })
    })

    describe('Toggle state management', () => {
      it('disables suggestions when toggle is turned off', async () => {
        const user = userEvent.setup()
        const {useDebounce} = require('use-debounce')
        useDebounce.mockReturnValue(['great', {isPending: () => false}])

        const mocks = [
          createCountMock(defaultUserId, 10),
          createCommentsMock(defaultUserId, defaultCourseId),
          createSuggestionsMock(defaultUserId, 'great'),
        ]

        setup(mocks, {comment: 'great'})

        // Wait for suggestions to appear
        await waitFor(
          () => {
            expect(screen.getByTestId('comment-suggestion-suggestion-1')).toBeInTheDocument()
          },
          {timeout: 3000},
        )

        // Open tray
        await user.click(screen.getByTestId('comment-library-button'))

        await waitFor(() => {
          expect(screen.getByText('Manage Comment Library')).toBeInTheDocument()
        })

        // Turn off suggestions toggle
        const checkbox = screen.getByTestId('suggestions-when-typing-toggle')
        await user.click(checkbox)

        // Close tray
        await user.click(screen.getByTestId('tray-close-button'))

        // Suggestions should no longer appear
        await waitFor(() => {
          expect(screen.queryByTestId('comment-suggestion-suggestion-1')).not.toBeInTheDocument()
        })
      })

      it('shows toggle in checked state when suggestions are enabled', async () => {
        const user = userEvent.setup()
        const {useDebounce} = require('use-debounce')
        useDebounce.mockReturnValue(['test', {isPending: () => false}])

        const mocks = [
          createCountMock(defaultUserId, 10),
          createCommentsMock(defaultUserId, defaultCourseId),
          createSuggestionsMock(defaultUserId, 'test', [{_id: 'test-1', comment: 'Test comment'}]),
        ]

        // Start with suggestions enabled (default)
        setup(mocks, {comment: 'test'})

        // Wait for suggestions to appear
        await waitFor(
          () => {
            expect(screen.getByTestId('comment-suggestion-test-1')).toBeInTheDocument()
          },
          {timeout: 3000},
        )

        // Open tray
        await user.click(screen.getByTestId('comment-library-button'))

        await waitFor(() => {
          expect(screen.getByText('Manage Comment Library')).toBeInTheDocument()
        })

        // Toggle should be checked initially since suggestions are enabled
        const checkbox = screen.getByTestId('suggestions-when-typing-toggle')
        expect(checkbox).toBeChecked()
      })
    })

    describe('Suggestions visibility logic', () => {
      it('renders suggestions anchor when suggestion conditions could be met', async () => {
        const {useDebounce} = require('use-debounce')
        useDebounce.mockReturnValue(['great', {isPending: () => false}])

        const mocks = [
          createCountMock(defaultUserId, 10),
          createSuggestionsMock(defaultUserId, 'great'),
        ]

        setup(mocks, {comment: 'great'})

        await waitFor(() => {
          expect(screen.getByTestId('comment-suggestions-anchor')).toBeInTheDocument()
        })
      })

      it('hides suggestions popover when debounce is pending', async () => {
        const {useDebounce} = require('use-debounce')
        useDebounce.mockReturnValue(['great', {isPending: () => true}])

        const mocks = [createCountMock(defaultUserId, 10)]

        setup(mocks, {comment: 'great'})

        await waitFor(() => {
          expect(screen.getByTestId('comment-library-button')).toBeInTheDocument()
        })

        // Suggestions popover should not be visible
        expect(screen.queryByText('Insert Comment from Library')).not.toBeInTheDocument()
      })

      it('hides suggestions popover when no results are returned', async () => {
        const {useDebounce} = require('use-debounce')
        useDebounce.mockReturnValue(['xyz', {isPending: () => false}])

        const mocks = [
          createCountMock(defaultUserId, 10),
          createSuggestionsMock(defaultUserId, 'xyz', []),
        ]

        setup(mocks, {comment: 'xyz'})

        await waitFor(() => {
          expect(screen.getByTestId('comment-library-button')).toBeInTheDocument()
        })

        // Suggestions popover should not be visible when no results
        expect(screen.queryByText('Insert Comment from Library')).not.toBeInTheDocument()
      })
    })

    describe('State management on comment selection from suggestions', () => {
      it('renders suggestions with correct data for selection', async () => {
        const {useDebounce} = require('use-debounce')
        useDebounce.mockReturnValue(['great', {isPending: () => false}])

        const mocks = [
          createCountMock(defaultUserId, 10),
          createSuggestionsMock(defaultUserId, 'great'),
        ]

        setup(mocks, {comment: 'great'})

        // Wait for suggestions to appear
        await waitFor(
          () => {
            expect(screen.getByTestId('comment-suggestion-suggestion-1')).toBeInTheDocument()
          },
          {timeout: 3000},
        )

        // Verify suggestion content
        expect(screen.getByTestId('comment-suggestion-suggestion-1')).toHaveTextContent(
          'Great work on this assignment!',
        )
        expect(screen.getByTestId('comment-suggestion-suggestion-2')).toHaveTextContent(
          'Great job!',
        )
      })
    })

    describe('State reset on comment clear', () => {
      it('re-enables search when comment is cleared', async () => {
        const {useDebounce} = require('use-debounce')
        useDebounce.mockReturnValue(['', {isPending: () => false}])

        const mocks = [createCountMock(defaultUserId, 10)]

        const {rerender} = setup(mocks, {comment: 'great'})

        await waitFor(() => {
          expect(screen.getByTestId('comment-library-button')).toBeInTheDocument()
        })

        // Now clear the comment
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

        rerender(
          <MockedProvider mocks={mocks} addTypename={true} cache={cache}>
            <CommentLibraryContent
              comment=""
              userId={defaultUserId}
              courseId={defaultCourseId}
              setComment={jest.fn()}
              setFocusToTextArea={jest.fn()}
            />
          </MockedProvider>,
        )

        // Search should be re-enabled (verified by the fact that typing again would trigger search)
        await waitFor(() => {
          expect(screen.getByTestId('comment-library-button')).toBeInTheDocument()
        })
      })
    })

    describe('Integration with suggestion query', () => {
      it('fetches suggestions with correct variables', async () => {
        const {useDebounce} = require('use-debounce')
        useDebounce.mockReturnValue(['test', {isPending: () => false}])

        const mocks = [
          createCountMock(defaultUserId, 10),
          createSuggestionsMock(defaultUserId, 'test', [{_id: 'test-1', comment: 'Test comment'}]),
        ]

        setup(mocks, {comment: 'test'})

        await waitFor(() => {
          expect(screen.getByTestId('comment-library-button')).toBeInTheDocument()
        })

        // The mock will fail if the variables don't match exactly
        await waitFor(
          () => {
            expect(screen.getByTestId('comment-suggestion-test-1')).toBeInTheDocument()
          },
          {timeout: 3000},
        )
      })

      it('returns empty array when no results', async () => {
        const {useDebounce} = require('use-debounce')
        useDebounce.mockReturnValue(['nothing', {isPending: () => false}])

        const mocks = [
          createCountMock(defaultUserId, 10),
          createSuggestionsMock(defaultUserId, 'nothing', []),
        ]

        setup(mocks, {comment: 'nothing'})

        await waitFor(() => {
          expect(screen.getByTestId('comment-library-button')).toBeInTheDocument()
        })

        // No suggestions should be shown
        expect(screen.queryByText('Insert Comment from Library')).not.toBeInTheDocument()
      })

      it('filters null nodes from query results', async () => {
        const {useDebounce} = require('use-debounce')
        useDebounce.mockReturnValue(['test', {isPending: () => false}])

        const mocks = [
          createCountMock(defaultUserId, 10),
          {
            request: {
              query: SpeedGraderLegacy_CommentBankItems,
              variables: {userId: defaultUserId, query: 'test', first: 5},
            },
            result: {
              data: {
                legacyNode: {
                  __typename: 'User',
                  commentBankItemsConnection: {
                    __typename: 'CommentBankItemConnection',
                    nodes: [null, {_id: 'test-1', comment: 'Test comment'}, null],
                    pageInfo: {
                      __typename: 'PageInfo',
                      hasNextPage: false,
                      endCursor: null,
                    },
                  },
                },
              },
            },
          },
        ]

        setup(mocks, {comment: 'test'})

        await waitFor(
          () => {
            expect(screen.getByTestId('comment-suggestion-test-1')).toBeInTheDocument()
          },
          {timeout: 3000},
        )

        // Should only have one suggestion (nulls filtered out)
        expect(screen.queryByTestId('comment-suggestion-null')).not.toBeInTheDocument()
      })
    })
  })
})
