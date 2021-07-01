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
import {graphql} from 'msw'
import {handlers} from '../../../../graphql/mswHandlers'
import {IsolatedViewContainer} from '../IsolatedViewContainer'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../../shared/msw/mswServer'
import React from 'react'
import {render} from '@testing-library/react'

describe('IsolatedViewContainer', () => {
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
    mswClient.resetStore()
    server.resetHandlers()
    setOnFailure.mockClear()
    setOnSuccess.mockClear()
  })

  afterAll(() => {
    server.close()
    // eslint-disable-next-line no-undef
    fetchMock.enableMocks()
  })

  const setup = props => {
    return render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <IsolatedViewContainer {...props} />
        </AlertManagerContext.Provider>
      </ApolloProvider>
    )
  }

  const defaultProps = () => ({
    discussionEntryId: '1',
    open: true,
    onClose: () => {}
  })

  it('should render', () => {
    const {container} = setup(defaultProps())
    expect(container).toBeTruthy()
  })

  it('should render a back button', async () => {
    const rootEntry = DiscussionEntry.mock({_id: 32})
    const {findByTestId} = setup(defaultProps({discussionEntryOverrides: {rootEntry}}))
    expect(await findByTestId('back-button')).toBeTruthy()
  })

  it('should not render a back button', () => {
    server.use(
      graphql.query('GetDiscussionSubentriesQuery', (req, res, ctx) => {
        return res.once(
          ctx.data({
            legacyNode: DiscussionEntry.mock()
          })
        )
      })
    )
    const {queryByTestId} = setup(defaultProps())
    expect(queryByTestId('back-button')).toBeNull()
  })
})
