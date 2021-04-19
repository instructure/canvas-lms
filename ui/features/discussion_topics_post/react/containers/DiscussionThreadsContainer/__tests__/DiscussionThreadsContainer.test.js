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
import {DiscussionThreadsContainer} from '../DiscussionThreadsContainer'
import {fireEvent, render} from '@testing-library/react'
import {handlers} from '../../../../graphql/mswHandlers'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../../shared/msw/mswServer'
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
      threads: [
        {
          _id: '49',
          id: '49',
          createdAt: '2021-04-05T13:40:50-06:00',
          updatedAt: '2021-04-05T13:40:50-06:00',
          deleted: false,
          message: '<p>This is the parent reply</p>',
          ratingCount: null,
          ratingSum: null,
          rating: false,
          read: true,
          subentriesCount: 1,
          rootEntryParticipantCounts: {
            unreadCount: 1,
            repliesCount: 1
          },
          author: {
            _id: '1',
            id: 'VXNlci0x',
            avatarUrl: 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==',
            name: 'Matthew Lemon'
          },
          editor: null,
          lastReply: {
            createdAt: '2021-04-05T13:41:42-06:00'
          }
        }
      ]
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
    const {container} = setup()
    expect(container).toBeTruthy()
  })

  it('should render when threads are empty', () => {
    const {container} = setup({
      threads: []
    })
    expect(container).toBeTruthy()
  })

  it('should render when threads are null', () => {
    const {container} = setup({
      threads: null
    })
    expect(container).toBeTruthy()
  })

  it('renders discussion entries', async () => {
    const {queryByText, getByTestId, findByText} = setup(defaultProps())
    expect(await findByText('This is the parent reply')).toBeTruthy()
    expect(queryByText('This is the child reply')).toBe(null)

    const expandButton = getByTestId('expand-button')
    fireEvent.click(expandButton)

    expect(await findByText('This is the child reply')).toBeTruthy()
  })
})
