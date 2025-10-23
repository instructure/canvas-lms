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
import {render, waitFor, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {MockedProvider} from '@apollo/client/testing'
import {CommentLibraryContent} from '../CommentLibrary'
import fakeENV from '@canvas/test-utils/fakeENV'
import {SpeedGrader_CommentBankItemsCount} from '../graphql/queries'

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

  const setup = (mocks: any[], props = {}) => {
    const defaultProps = {
      userId: defaultUserId,
      courseId: defaultCourseId,
      ...props,
    }

    return render(
      <MockedProvider mocks={mocks} addTypename={true}>
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

  describe('Dynamic Data Updates', () => {
    it('re-renders when userId changes', async () => {
      const mocks = [createCountMock('1', 10), createCountMock('2', 25)]
      const {getByTestId, rerender} = setup(mocks, {userId: '1'})

      await waitFor(() => {
        expect(getByTestId('comment-library-count')).toHaveTextContent('10')
      })

      rerender(
        <MockedProvider mocks={mocks} addTypename={true}>
          <CommentLibraryContent userId="2" courseId={defaultCourseId} />
        </MockedProvider>,
      )

      await waitFor(() => {
        expect(getByTestId('comment-library-count')).toHaveTextContent('25')
      })
    })
  })

  describe('Tray Integration Tests', () => {
    it('tray is closed by default', async () => {
      const mocks = [createCountMock(defaultUserId, 10)]
      setup(mocks)

      await waitFor(() => {
        expect(screen.getByTestId('comment-library-button')).toBeInTheDocument()
      })

      // Tray should exist but content should not be visible
      expect(screen.queryByTestId('library-comment-area')).not.toBeInTheDocument()
    })

    it('opens tray when comment library button is clicked', async () => {
      const user = userEvent.setup()
      const mocks = [createCountMock(defaultUserId, 10)]
      setup(mocks)

      await waitFor(() => {
        expect(screen.getByTestId('comment-library-button')).toBeInTheDocument()
      })

      const button = screen.getByTestId('comment-library-button')
      await user.click(button)

      // Tray should now be open
      await waitFor(() => {
        expect(screen.getByText('Manage Comment Library')).toBeInTheDocument()
      })
    })
  })
})
