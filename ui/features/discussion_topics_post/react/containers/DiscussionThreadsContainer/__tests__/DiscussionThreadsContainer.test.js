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
import {ApolloProvider} from 'react-apollo'
import {Discussion} from '../../../../graphql/Discussion'
import {DiscussionEntry} from '../../../../graphql/DiscussionEntry'
import {DiscussionThreadsContainer} from '../DiscussionThreadsContainer'
import {fireEvent, render} from '@testing-library/react'
import {handlers} from '../../../../graphql/mswHandlers'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../../shared/msw/mswServer'
import {PageInfo} from '../../../../graphql/PageInfo'
import React from 'react'

describe('DiscussionThreadContainer', () => {
  const server = mswServer(handlers)
  beforeAll(() => {
    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
    // eslint-disable-next-line no-undef
    fetchMock.enableMocks()
  })

  const defaultProps = () => {
    return {
      discussionTopic: {
        ...Discussion.mock(),
        discussionEntriesConnection: {
          nodes: [DiscussionEntry.mock({read: false})],
          pageInfo: PageInfo.mock(),
          __typename: 'DiscussionEntriesConnection'
        }
      },
      searchTerm: ''
    }
  }

  const setup = props => {
    return render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <DiscussionThreadsContainer {...props} />
        </AlertManagerContext.Provider>
      </ApolloProvider>
    )
  }

  it('should render', () => {
    const {container} = setup(defaultProps())
    expect(container).toBeTruthy()
  })

  it('should render when threads are empty', () => {
    const {container} = setup({
      ...defaultProps(),
      threads: []
    })
    expect(container).toBeTruthy()
  })

  it('renders discussion entries', async () => {
    const {queryByText, getByTestId, findByText} = setup(defaultProps())
    expect(await findByText('This is the parent reply')).toBeTruthy()
    expect(queryByText('This is the child reply')).toBe(null)

    const expandButton = getByTestId('expand-button')
    fireEvent.click(expandButton)

    expect(await findByText('This is the child reply', {}, {timeout: 4000})).toBeTruthy()
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

  it('updates unread discussion entries read state to read', async () => {
    const container = setup(defaultProps())

    expect(container.getByTestId('is-unread')).toBeInTheDocument()
    expect(container.getByTestId('is-unread').getAttribute('data-isforcedread')).toBe('false')

    window.setTimeout(
      () => expect(container.queryByTestId('is-unread')).not.toBeInTheDocument(),
      3000
    )
  })

  it('unread discussion entry does not update when forceReadState is true', async () => {
    const props = defaultProps()
    props.discussionTopic.discussionEntriesConnection.nodes[0].forcedReadState = true

    const container = setup(props)
    expect(container.getByTestId('is-unread')).toBeInTheDocument()
    expect(container.getByTestId('is-unread').getAttribute('data-isforcedread')).toBe('true')

    window.setTimeout(() => expect(container.queryByTestId('is-unread')).toBeInTheDocument(), 3000)
  })
})
