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
import {DiscussionEntry} from '../../../../graphql/DiscussionEntry'
import {fireEvent, render} from '@testing-library/react'
import {getSpeedGraderUrl} from '../../../utils'
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
  const assignMock = jest.fn()
  beforeAll(() => {
    delete window.location
    window.location = {assign: assignMock}
    window.ENV = {
      course_id: '1'
    }

    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()
  })

  afterEach(() => {
    server.resetHandlers()
    onFailureStub.mockClear()
    onSuccessStub.mockClear()
    assignMock.mockClear()
  })

  afterAll(() => {
    server.close()
    // eslint-disable-next-line no-undef
    fetchMock.enableMocks()
  })

  const defaultProps = ({discussionEntryOverrides = {}, assignment = undefined} = {}) => {
    return {
      discussionEntry: {
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
          update: true,
          viewRating: true
        },
        ...discussionEntryOverrides
      },
      assignment
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

  it('should not render reply button if reply permission is false', () => {
    const {queryByTestId} = setup({
      discussionEntry: DiscussionEntry.mock({permissions: {reply: false}})
    })
    expect(queryByTestId('threading-toolbar-reply')).toBeFalsy()
  })

  it('should render reply button if reply permission is true', () => {
    const {queryByTestId} = setup(defaultProps())
    expect(queryByTestId('threading-toolbar-reply')).toBeTruthy()
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

  describe('delete permission', () => {
    it('removed when false', async () => {
      const new_prop = defaultProps()
      new_prop.discussionEntry.permissions.delete = false
      const {getByTestId, queryAllByText} = setup(new_prop)
      fireEvent.click(getByTestId('thread-actions-menu'))

      expect(queryAllByText('Delete').length).toBe(0)
    })

    it('present when true', async () => {
      const {getByTestId, queryAllByText} = setup(defaultProps())
      fireEvent.click(getByTestId('thread-actions-menu'))

      const deletes = queryAllByText('Delete')
      expect(deletes.length).toBe(1)
    })
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

  describe('SpeedGrader', () => {
    it('Should be able to open SpeedGrader', async () => {
      const {getByTestId} = setup(
        defaultProps({
          assignment: {
            _id: '1337',
            dueAt: '2021-04-05T13:40:50Z',
            pointsPossible: 5
          }
        })
      )

      fireEvent.click(getByTestId('thread-actions-menu'))
      fireEvent.click(getByTestId('inSpeedGrader'))

      await waitFor(() => {
        expect(assignMock).toHaveBeenCalledWith(getSpeedGraderUrl('1', '1337', '1'))
      })
    })

    it('Should not be able to open SpeedGrader if is not an assignment', () => {
      const {getByTestId, queryByTestId} = setup(
        defaultProps({
          assignment: null
        })
      )

      fireEvent.click(getByTestId('thread-actions-menu'))
      expect(queryByTestId('inSpeedGrader')).toBeNull()
    })
  })
})
