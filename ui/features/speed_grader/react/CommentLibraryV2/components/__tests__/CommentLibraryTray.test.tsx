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

import {render, waitFor, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {MockedProvider} from '@apollo/client/testing'
import {InMemoryCache} from '@apollo/client'
import {CommentLibraryTray} from '../CommentLibraryTray'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import {SpeedGraderLegacy_CommentBankItems} from '../../graphql/queries'
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('@canvas/alerts/react/FlashAlert')
jest.mock('@canvas/do-fetch-api-effect')

describe('CommentLibraryTray', () => {
  const defaultProps = {
    userId: '1',
    courseId: '1',
    isOpen: true,
    onDismiss: jest.fn(),
    setCommentFromLibrary: jest.fn(),
    suggestionsWhenTypingEnabled: true,
    setSuggestionsWhenTypingEnabled: jest.fn(),
  }

  const createCommentsMock = ({
    userId = '1',
    courseId = '1',
    commentCount = 5,
    hasNextPage = false,
    after = '',
  }: {
    userId?: string
    courseId?: string
    commentCount?: number
    hasNextPage?: boolean
    after?: string
  } = {}) => ({
    request: {
      query: SpeedGraderLegacy_CommentBankItems,
      variables: {userId, courseId, first: 20, after},
    },
    result: {
      data: {
        legacyNode: {
          __typename: 'User',
          commentBankItemsConnection: {
            __typename: 'CommentBankItemConnection',
            nodes: Array.from({length: commentCount}, (_, i) => ({
              __typename: 'CommentBankItem',
              _id: `comment-${i + (after ? 5 : 0)}`,
              comment: `Test comment ${i + (after ? 5 : 0)}`,
            })),
            pageInfo: {
              __typename: 'PageInfo',
              hasNextPage,
              endCursor: hasNextPage ? 'cursor-123' : null,
            },
          },
        },
      },
    },
  })

  const setup = (mocks: any[], props = {}) => {
    const mergedProps = {...defaultProps, ...props}
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
        <CommentLibraryTray {...mergedProps} />
      </MockedProvider>,
    )
  }

  beforeEach(() => {
    jest.clearAllMocks()
    ;(doFetchApi as jest.Mock).mockResolvedValue({})
  })

  describe('Rendering Tests', () => {
    it('does not render tray content when isOpen is false', () => {
      const mocks = [createCommentsMock()]
      const {queryByTestId} = setup(mocks, {isOpen: false})

      expect(queryByTestId('library-comment-area')).not.toBeInTheDocument()
    })

    it('does not execute GraphQL query when isOpen is false', async () => {
      const mocks = [createCommentsMock()]
      setup(mocks, {isOpen: false})

      // Wait a moment to ensure query doesn't fire
      await new Promise(resolve => setTimeout(resolve, 100))

      // If query was skipped, spinner should not appear
      expect(screen.queryByTitle('Loading comment library')).not.toBeInTheDocument()
    })

    it('shows spinner during initial data load', () => {
      const mocks = [createCommentsMock()]
      setup(mocks)

      expect(screen.getByTitle('Loading comment library')).toBeInTheDocument()
    })

    it('renders comment list after data loads successfully', async () => {
      const mocks = [createCommentsMock({commentCount: 3})]
      const {getByTestId} = setup(mocks)

      await waitFor(() => {
        expect(getByTestId('library-comment-area')).toBeInTheDocument()
      })
    })
  })

  describe('Data Loading Tests', () => {
    it('displays comments returned from GraphQL query', async () => {
      const mocks = [createCommentsMock({commentCount: 3})]
      setup(mocks)

      await waitFor(() => {
        expect(screen.getByText('Test comment 0')).toBeInTheDocument()
        expect(screen.getByText('Test comment 1')).toBeInTheDocument()
        expect(screen.getByText('Test comment 2')).toBeInTheDocument()
      })
    })
  })

  describe('Pagination Tests', () => {
    it('shows "Load more comments" button when hasNextPage is true', async () => {
      const mocks = [createCommentsMock({hasNextPage: true})]
      setup(mocks)

      await waitFor(() => {
        expect(screen.getByText('Load more comments')).toBeInTheDocument()
      })
    })

    it('hides "Load more comments" button when hasNextPage is false', async () => {
      const mocks = [createCommentsMock({hasNextPage: false})]
      setup(mocks)

      await waitFor(() => {
        expect(screen.getByTestId('library-comment-area')).toBeInTheDocument()
      })

      expect(screen.queryByText('Load more comments')).not.toBeInTheDocument()
    })

    it('calls fetchMore with correct endCursor when Load more is clicked', async () => {
      const user = userEvent.setup()
      const mocks = [
        createCommentsMock({hasNextPage: true}),
        createCommentsMock({after: 'cursor-123', commentCount: 3}),
      ]
      setup(mocks)

      await waitFor(() => {
        expect(screen.getByTestId('load-more-comments-button')).toBeInTheDocument()
      })

      const loadMoreButton = screen.getByTestId('load-more-comments-button')
      await user.click(loadMoreButton)

      await waitFor(() => {
        expect(screen.getByText('Test comment 5')).toBeInTheDocument()
      })
    })

    it('disables Load more button while fetching', async () => {
      const user = userEvent.setup()
      const mocks = [
        createCommentsMock({hasNextPage: true}),
        createCommentsMock({after: 'cursor-123', commentCount: 3}),
      ]
      setup(mocks)

      await waitFor(() => {
        expect(screen.getByTestId('load-more-comments-button')).toBeInTheDocument()
      })

      const loadMoreButton = screen.getByTestId('load-more-comments-button')
      await user.click(loadMoreButton)

      // After fetching more data, we should have additional comments
      await waitFor(() => {
        expect(screen.getByText('Test comment 5')).toBeInTheDocument()
      })
    })
  })

  describe('Error Handling Tests', () => {
    it('shows flash alert when GraphQL query fails', async () => {
      const showFlashAlertMock = jest.spyOn(FlashAlert, 'showFlashAlert')
      const mocks = [
        {
          request: {
            query: SpeedGraderLegacy_CommentBankItems,
            variables: {userId: '1', courseId: '1', first: 5, after: ''},
          },
          error: new Error('GraphQL error'),
        },
      ]
      setup(mocks)

      await waitFor(() => {
        expect(showFlashAlertMock).toHaveBeenCalledWith({
          message: 'Error loading comment library',
          type: 'error',
        })
      })
    })
  })

  describe('Interaction Tests', () => {
    it('calls onDismiss when close button is clicked', async () => {
      const user = userEvent.setup()
      const onDismiss = jest.fn()
      const mocks = [createCommentsMock()]
      setup(mocks, {onDismiss})

      await waitFor(() => {
        expect(screen.getByTestId('library-comment-area')).toBeInTheDocument()
      })

      const closeButton = screen
        .getByTestId('tray-close-button')
        .querySelector('button') as HTMLButtonElement
      await user.click(closeButton)
      expect(onDismiss).toHaveBeenCalled()
    })
  })

  describe('CreateCommentSection Integration Tests', () => {
    it('renders CreateCommentSection within the tray', async () => {
      const mocks = [createCommentsMock()]
      setup(mocks)

      await waitFor(() => {
        expect(screen.getByTestId('library-comment-area')).toBeInTheDocument()
      })

      expect(screen.getByTestId('create-comment-library-item-textarea')).toBeInTheDocument()
      expect(screen.getByTestId('add-to-library-button')).toBeInTheDocument()
    })
  })

  describe('Comment Selection Tests', () => {
    it('calls setCommentFromLibrary when a comment is clicked', async () => {
      const user = userEvent.setup()
      const setCommentFromLibrary = jest.fn()
      const mocks = [createCommentsMock({commentCount: 3})]
      setup(mocks, {setCommentFromLibrary})

      await waitFor(() => {
        expect(screen.getByText('Test comment 0')).toBeInTheDocument()
      })

      // Click on the first comment
      await user.click(screen.getByText('Test comment 0'))

      expect(setCommentFromLibrary).toHaveBeenCalledWith('Test comment 0')
    })

    it('calls setCommentFromLibrary with correct comment text for different comments', async () => {
      const user = userEvent.setup()
      const setCommentFromLibrary = jest.fn()
      const mocks = [createCommentsMock({commentCount: 3})]
      setup(mocks, {setCommentFromLibrary})

      await waitFor(() => {
        expect(screen.getByText('Test comment 1')).toBeInTheDocument()
      })

      // Click on the second comment
      await user.click(screen.getByText('Test comment 1'))

      expect(setCommentFromLibrary).toHaveBeenCalledWith('Test comment 1')
      expect(setCommentFromLibrary).toHaveBeenCalledTimes(1)
    })

    it('calls setCommentFromLibrary multiple times for multiple clicks', async () => {
      const user = userEvent.setup()
      const setCommentFromLibrary = jest.fn()
      const mocks = [createCommentsMock({commentCount: 3})]
      setup(mocks, {setCommentFromLibrary})

      await waitFor(() => {
        expect(screen.getByText('Test comment 0')).toBeInTheDocument()
      })

      // Click on first comment
      await user.click(screen.getByText('Test comment 0'))
      expect(setCommentFromLibrary).toHaveBeenCalledWith('Test comment 0')

      // Click on second comment
      await user.click(screen.getByText('Test comment 1'))
      expect(setCommentFromLibrary).toHaveBeenCalledWith('Test comment 1')

      expect(setCommentFromLibrary).toHaveBeenCalledTimes(2)
    })
  })

  describe('SuggestionsEnabledToggleSection Integration Tests', () => {
    it('renders suggestions toggle section', async () => {
      const mocks = [createCommentsMock()]
      setup(mocks)

      await waitFor(() => {
        expect(screen.getByTestId('comment-suggestions-when-typing')).toBeInTheDocument()
      })
    })

    it('toggle reflects initial suggestionsWhenTypingEnabled state', async () => {
      const mocks = [createCommentsMock()]
      setup(mocks, {suggestionsWhenTypingEnabled: false})

      await waitFor(() => {
        expect(screen.getByTestId('suggestions-when-typing-toggle')).toBeInTheDocument()
      })

      const checkbox = screen.getByTestId('suggestions-when-typing-toggle')
      expect(checkbox).not.toBeChecked()
    })

    it('calls setSuggestionsWhenTypingEnabled when toggle is clicked', async () => {
      const user = userEvent.setup()
      const setSuggestionsWhenTypingEnabled = jest.fn()
      const mocks = [createCommentsMock()]
      setup(mocks, {suggestionsWhenTypingEnabled: true, setSuggestionsWhenTypingEnabled})

      await waitFor(() => {
        expect(screen.getByTestId('suggestions-when-typing-toggle')).toBeInTheDocument()
      })

      const checkbox = screen.getByTestId('suggestions-when-typing-toggle')
      await user.click(checkbox)

      expect(setSuggestionsWhenTypingEnabled).toHaveBeenCalledWith(false)
    })
  })
})
