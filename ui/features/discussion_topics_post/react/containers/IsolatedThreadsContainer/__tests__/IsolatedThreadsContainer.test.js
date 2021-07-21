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
import {DiscussionEntry} from '../../../../graphql/DiscussionEntry'
import {PageInfo} from '../../../../graphql/PageInfo'
import {render} from '@testing-library/react'
import {handlers} from '../../../../graphql/mswHandlers'
import {IsolatedThreadsContainer} from '../IsolatedThreadsContainer'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../../shared/msw/mswServer'
import React from 'react'

describe('IsolatedThreadsContainer', () => {
  const server = mswServer(handlers)
  const setOnFailure = jest.fn()
  const setOnSuccess = jest.fn()

  beforeAll(() => {
    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()

    window.ENV = {
      discussion_topic_id: '1',
      manual_mark_as_read: false,
      current_user: {
        id: 'PLACEHOLDER',
        display_name: 'Omar Soto-Fortuño',
        avatar_image_url: 'www.avatar.com'
      },
      course_id: '1'
    }
  })

  afterEach(() => {
    server.resetHandlers()
    setOnFailure.mockClear()
    setOnSuccess.mockClear()
  })

  afterAll(() => {
    server.close()
    // eslint-disable-next-line no-undef
    fetchMock.enableMocks()
  })

  const defaultProps = () => ({
    discussionEntry: DiscussionEntry.mock({
      discussionSubentriesConnection: {
        nodes: [
          DiscussionEntry.mock({
            _id: '50',
            id: '50',
            message: '<p>This is the child reply</P>'
          })
        ],
        pageInfo: PageInfo.mock(),
        __typename: 'DiscussionSubentriesConnection'
      }
    })
  })

  const setup = props => {
    return render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <IsolatedThreadsContainer {...props} />
        </AlertManagerContext.Provider>
      </ApolloProvider>
    )
  }

  it('should render', () => {
    const container = setup(defaultProps())
    expect(container).toBeTruthy()
  })

  it('should render sub-entries in the correct order', async () => {
    const container = setup(defaultProps())
    expect(await container.findByText('This is the child reply')).toBeInTheDocument()
  })
})
