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
import {DiscussionThreadContainer} from '../DiscussionThreadContainer'
import {fireEvent, render} from '@testing-library/react'
import {handlers} from '../../../../graphql/mswHandlers'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../../shared/msw/mswServer'
import React from 'react'
import {waitFor} from '@testing-library/dom'
import {graphql} from 'msw'

describe('DiscussionThreadContainer', () => {
  const server = mswServer(handlers)
  const onFailureStub = jest.fn()
  const onSuccessStub = jest.fn()
  beforeAll(() => {
    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()
  })

  afterEach(() => {
    server.resetHandlers()
    onFailureStub.mockClear()
    onSuccessStub.mockClear()
  })

  afterAll(() => {
    server.close()
    // eslint-disable-next-line no-undef
    fetchMock.enableMocks()
  })

  const defaultProps = overrides => {
    return {
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
      },
      permissions: {
        attach: true,
        create: true,
        delete: true,
        rate: true,
        read: true,
        reply: true,
        update: true
      },
      ...overrides
    }
  }

  const setup = props => {
    return render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider
          value={{setOnFailure: onFailureStub, setOnSuccess: onSuccessStub}}
        >
          <DiscussionThreadContainer {...props} />
        </AlertManagerContext.Provider>
      </ApolloProvider>
    )
  }

  it('should render', () => {
    const {container} = setup(defaultProps())
    expect(container).toBeTruthy()
  })

  it('should render expand when nested replies are present', () => {
    const {getByTestId} = setup(defaultProps())
    expect(getByTestId('expand-button')).toBeTruthy()
  })

  it('should expand replies when expand button is clicked', () => {
    const {getByTestId} = setup(defaultProps())
    fireEvent.click(getByTestId('expand-button'))
    expect(getByTestId('collapse-replies')).toBeTruthy()
  })

  it('should collapse replies when expand button is clicked', async () => {
    const {getByTestId, queryByTestId} = setup(defaultProps())
    fireEvent.click(getByTestId('expand-button'))
    expect(getByTestId('collapse-replies')).toBeTruthy()

    fireEvent.click(getByTestId('expand-button'))

    expect(queryByTestId('collapse-replies')).toBeNull()
  })

  it('should collapse replies when collapse button is clicked', () => {
    const {getByTestId, queryByTestId} = setup(defaultProps())
    fireEvent.click(getByTestId('expand-button'))
    expect(getByTestId('collapse-replies')).toBeTruthy()

    fireEvent.click(getByTestId('collapse-replies'))

    expect(queryByTestId('collapse-replies')).toBeNull()
  })

  describe('read state', () => {
    it('indicates the update to the user', async () => {
      const {getByTestId} = setup(defaultProps())

      fireEvent.click(getByTestId('thread-actions-menu'))
      fireEvent.click(getByTestId('markAsUnread'))

      await waitFor(() => {
        expect(onSuccessStub.mock.calls.length).toBe(1)
        expect(onFailureStub.mock.calls.length).toBe(0)
      })
    })

    describe('error handling', () => {
      beforeEach(() => {
        server.use(
          graphql.mutation('UpdateDiscussionEntryParticipant', (req, res, ctx) => {
            return res.once(
              ctx.errors([
                {
                  message: 'foobar'
                }
              ])
            )
          })
        )
      })

      it('indicates the failure to the user', async () => {
        const {getByTestId} = setup(defaultProps())

        fireEvent.click(getByTestId('thread-actions-menu'))
        fireEvent.click(getByTestId('markAsUnread'))

        await waitFor(() => {
          expect(onSuccessStub.mock.calls.length).toBe(0)
          expect(onFailureStub.mock.calls.length).toBe(1)
        })
      })
    })
  })

  describe('ratings', () => {
    it('indicates the update to the user', async () => {
      const {getByTestId} = setup(defaultProps())

      fireEvent.click(getByTestId('like-button'))

      await waitFor(() => {
        expect(onSuccessStub.mock.calls.length).toBe(1)
        expect(onFailureStub.mock.calls.length).toBe(0)
      })
    })

    describe('error handling', () => {
      beforeEach(() => {
        server.use(
          graphql.mutation('UpdateDiscussionEntryParticipant', (req, res, ctx) => {
            return res.once(
              ctx.errors([
                {
                  message: 'foobar'
                }
              ])
            )
          })
        )
      })

      it('indicates the failure to the user', async () => {
        const {getByTestId} = setup(defaultProps())

        fireEvent.click(getByTestId('like-button'))

        await waitFor(() => {
          expect(onSuccessStub.mock.calls.length).toBe(0)
          expect(onFailureStub.mock.calls.length).toBe(1)
        })
      })
    })
  })
})
