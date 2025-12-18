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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {Discussion} from '../../../../graphql/Discussion'
import {DiscussionEntry} from '../../../../graphql/DiscussionEntry'
import {DiscussionTopicRepliesContainer} from '../DiscussionTopicRepliesContainer'
import {fireEvent, render, waitFor} from '@testing-library/react'
import {
  getDiscussionEntryAllRootEntriesQueryMock,
  updateDiscussionReadStateMock,
} from '../../../../graphql/Mocks'
import {MockedProvider} from '@apollo/client/testing'
import {PageInfo} from '../../../../graphql/PageInfo'
import React from 'react'
import fakeENV from '@canvas/test-utils/fakeENV'
import {UPDATE_DISCUSSION_ENTRIES_READ_STATE} from '../../../../graphql/Mutations'

vi.mock('../../../utils', async () => ({
  ...(await vi.importActual('../../../utils')),
  responsiveQuerySizes: () => ({desktop: {maxWidth: '1024px'}}),
}))
vi.mock('../../../utils/constants', async () => ({
  ...(await vi.importActual('../../../utils/constants')),
  AUTO_MARK_AS_READ_DELAY: 0,
}))
vi.mock('../../DiscussionThreadContainer/DiscussionThreadContainer', () => ({
  __esModule: true,
  DiscussionThreadContainer: ({markAsRead, discussionEntry}) => {
    return (
      <button
        data-testid={`mark-as-read-${discussionEntry.id}`}
        onClick={() => markAsRead(discussionEntry._id)}
      >
        Mark as read
      </button>
    )
  },
}))

describe('DiscussionTopicRepliesContainer', () => {
  beforeAll(() => {
    fakeENV.setup({
      course_id: '1',
      per_page: 20,
    })

    window.matchMedia = vi.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: vi.fn(),
        removeListener: vi.fn(),
      }
    })
  })

  const defaultProps = () => {
    return {
      discussionTopic: {
        ...Discussion.mock(),
        discussionEntriesConnection: {
          nodes: [
            DiscussionEntry.mock({
              id: '123',
              _id: '456',
              entryParticipant: {read: false, forcedReadState: null, rating: false},
            }),
          ],
          pageInfo: PageInfo.mock(),
          __typename: 'DiscussionEntriesConnection',
        },
      },
      searchTerm: '',
    }
  }

  const setup = (props, mocks, {setOnFailure = vi.fn(), setOnSuccess = vi.fn()} = {}) => {
    return render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <DiscussionTopicRepliesContainer {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>,
    )
  }

  it('should render', () => {
    const {container} = setup(defaultProps())
    expect(container).toBeTruthy()
  })

  it('should render when threads are empty', () => {
    const {container} = setup({
      ...defaultProps(),
      threads: [],
    })
    expect(container).toBeTruthy()
  })

  it('renders the pagination component if there are more than 1 pages', () => {
    const {getByTestId} = setup(defaultProps())
    expect(getByTestId('pagination')).toBeInTheDocument()
  })

  it('does not render the pagination component if there is only 1 page', () => {
    const props = defaultProps()
    props.discussionTopic.entriesTotalPages = 1
    const {queryByTestId} = setup(props)
    expect(queryByTestId('pagination')).toBeNull()
  })

  it('renders an error when UPDATE_DISCUSSION_ENTRIES_READ_STATE encounters an issue', async () => {
    const setOnFailure = vi.fn()
    const props = defaultProps()
    const entry = props.discussionTopic.discussionEntriesConnection.nodes[0]

    const mocks = [
      {
        request: {
          query: UPDATE_DISCUSSION_ENTRIES_READ_STATE,
          variables: {discussionEntryIds: [entry._id], read: true},
        },
        result: {
          errors: [{message: 'A non-network error occurred'}],
        },
      },
    ]

    const {getByTestId} = setup(props, mocks, {setOnFailure})

    fireEvent.click(getByTestId(`mark-as-read-${entry.id}`))

    await waitFor(() => {
      expect(setOnFailure).toHaveBeenCalledWith(
        'There was an unexpected error while marking replies as read',
      )
    })
  })

  it('does not render error when UPDATE_DISCUSSION_ENTRIES_READ_STATE encounters a network issue', async () => {
    const setOnFailure = vi.fn()
    const props = defaultProps()
    const entry = props.discussionTopic.discussionEntriesConnection.nodes[0]

    const mocks = [
      {
        request: {
          query: UPDATE_DISCUSSION_ENTRIES_READ_STATE,
          variables: {discussionEntryIds: [entry._id], read: true},
        },
        error: new Error('A network error occurred'),
      },
    ]

    const {getByTestId} = setup(props, mocks, {setOnFailure})

    fireEvent.click(getByTestId(`mark-as-read-${entry.id}`))

    await new Promise(resolve => setTimeout(resolve, 0))

    expect(setOnFailure).not.toHaveBeenCalled()
  })
})
