/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {render, fireEvent, waitFor} from '@testing-library/react'
import CommentArea from '../CommentArea'
import fakeEnv from '@canvas/test-utils/fakeENV'
import {MockedProvider} from '@apollo/client/testing'
import {
  SpeedGraderLegacy_CommentBankItemsCount,
  SpeedGraderLegacy_CommentBankItems,
} from '../CommentLibraryV2/graphql/queries'

// Mock @canvas/apollo-v3 to use the test's Apollo context instead of creating its own
vi.mock('@canvas/apollo-v3', () => ({
  ApolloProvider: ({children}) => children,
  createClient: vi.fn(),
}))

// Mock CanvasRce with minimal editor interface
vi.mock('@canvas/rce/react/CanvasRce', () => ({
  default: React.forwardRef((props, ref) => {
    React.useEffect(() => {
      if (ref) {
        const mockEditor = {
          focus: vi.fn(),
          setContent: vi.fn(),
          dom: {encode: vi.fn(text => text)},
        }
        if (typeof ref === 'function') ref({editor: mockEditor})
        else ref.current = {editor: mockEditor}
      }
    }, [ref])

    return <textarea id={props.textareaId} readOnly={props.readOnly} />
  }),
}))

// Mock child components of CommentLibrary
vi.mock('../CommentLibraryV2/components/CommentLibraryTray', () => ({
  // eslint-disable-next-line react/prop-types
  CommentLibraryTray: ({setCommentFromLibrary}) => (
    <div data-testid="comment-library-tray">
      <button onClick={() => setCommentFromLibrary('Selected comment text')}>Insert Comment</button>
    </div>
  ),
}))

vi.mock('../CommentLibraryV2/Suggestions', () => ({
  default: ({setComment}) => (
    <div data-testid="suggestions">
      <button onClick={() => setComment?.('Suggested comment')}>Insert Suggestion</button>
    </div>
  ),
}))

// Helper to create mock queries for different states
const createMockQueries = ({loading = false, itemCount = 5} = {}) => [
  {
    request: {
      query: SpeedGraderLegacy_CommentBankItemsCount,
      variables: {userId: '1'},
    },
    result: {
      data: {
        legacyNode: {
          __typename: 'User',
          commentBankItemsConnection: {
            __typename: 'CommentBankItemsConnection',
            pageInfo: {
              __typename: 'PageInfo',
              totalCount: itemCount,
            },
          },
        },
      },
    },
    delay: loading ? Infinity : 0,
  },
  {
    request: {
      query: SpeedGraderLegacy_CommentBankItems,
      variables: {userId: '1', query: '', first: 5},
    },
    result: {
      data: {
        legacyNode: {
          __typename: 'User',
          commentBankItemsConnection: {
            __typename: 'CommentBankItemConnection',
            nodes: [],
          },
        },
      },
    },
  },
]

// Setup function to render CommentArea with MockedProvider
const setupWithMocks = (mocks, props = {}) => {
  const {InMemoryCache} = require('@apollo/client')

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
      <CommentArea {...props} />
    </MockedProvider>,
  )
}

describe('CommentArea', () => {
  let getTextAreaRefMock
  let handleCommentChangeMock

  const defaultProps = () => {
    return {
      getTextAreaRef: getTextAreaRefMock,
      courseId: '1',
      userId: '1',
      handleCommentChange: handleCommentChangeMock,
    }
  }

  beforeEach(() => {
    getTextAreaRefMock = vi.fn()
    handleCommentChangeMock = vi.fn()
  })

  afterEach(() => {
    vi.clearAllMocks()
    fakeEnv.teardown()
  })

  it('calls getTextAreaRef within TextArea', () => {
    render(<CommentArea {...defaultProps()} />)
    expect(getTextAreaRefMock).toHaveBeenCalled()
  })

  describe('with the comment library flag enabled', () => {
    beforeEach(() => {
      fakeEnv.setup({
        assignment_comment_library_feature_enabled: true,
      })
    })

    it('loads the comment library', async () => {
      // Use loading state by setting delay to Infinity
      const mocks = createMockQueries({loading: true})
      const {findByText} = setupWithMocks(mocks, defaultProps())
      expect(await findByText('Loading comment library')).toBeInTheDocument()
    })
  })

  describe('with the comment library flag disabled', () => {
    beforeEach(() => {
      fakeEnv.setup({
        assignment_comment_library_feature_enabled: false,
        context_asset_string: 'course_1',
      })
    })

    it('does not load the comment library', () => {
      const {queryByText} = render(<CommentArea {...defaultProps()} />)
      expect(queryByText('Loading comment library')).not.toBeInTheDocument()
    })
  })

  describe('with comment library v2 enabled', () => {
    let mocks

    beforeEach(() => {
      fakeEnv.setup({
        assignment_comment_library_feature_enabled: true,
      })
      // Create mocks with loaded state
      mocks = createMockQueries({loading: false})
    })

    it('calls handleCommentChange when setComment is invoked from CommentLibraryWrapper', async () => {
      const handleCommentChange = vi.fn()
      const {getByText} = setupWithMocks(mocks, {
        ...defaultProps(),
        handleCommentChange,
      })

      await waitFor(() => {
        expect(getByText('Insert Comment')).toBeInTheDocument()
      })

      fireEvent.click(getByText('Insert Comment'))
      expect(handleCommentChange).toHaveBeenCalledWith('Selected comment text', false)
    })

    it('focuses textarea when setFocusToTextArea is invoked from CommentLibraryWrapper', async () => {
      const mockTextArea = {focus: vi.fn()}
      getTextAreaRefMock.mockImplementation(el => {
        if (el) {
          mockTextArea.focus = vi.fn()
          Object.assign(el, mockTextArea)
        }
      })

      const {getByText} = setupWithMocks(mocks, defaultProps())

      await waitFor(() => {
        expect(getByText('Insert Comment')).toBeInTheDocument()
      })

      // Clicking "Insert Comment" triggers setCommentFromLibrary which calls setFocusToTextArea
      fireEvent.click(getByText('Insert Comment'))

      // Wait for the setTimeout in setCommentFromLibrary to complete
      await new Promise(resolve => setTimeout(resolve, 10))

      expect(mockTextArea.focus).toHaveBeenCalled()
    })

    describe('with RCE Lite enabled', () => {
      it('calls handleCommentChange when inserting comment', async () => {
        const handleCommentChange = vi.fn()

        const {getByText} = setupWithMocks(mocks, {
          ...defaultProps(),
          useRCELite: true,
          handleCommentChange,
        })

        await waitFor(() => {
          expect(getByText('Insert Comment')).toBeInTheDocument()
        })

        fireEvent.click(getByText('Insert Comment'))

        expect(handleCommentChange).toHaveBeenCalledWith('Selected comment text', false)
      })

      it('renders without crashing when useRCELite is true', () => {
        const {container} = setupWithMocks(mocks, {...defaultProps(), useRCELite: true})
        expect(container).toBeInTheDocument()
      })
    })
  })
})
