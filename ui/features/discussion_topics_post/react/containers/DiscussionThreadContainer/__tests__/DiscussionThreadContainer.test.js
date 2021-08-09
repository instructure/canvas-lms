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
import {DiscussionEntryPermissions} from '../../../../graphql/DiscussionEntryPermissions'
import {DiscussionPermissions} from '../../../../graphql/DiscussionPermissions'
import {DiscussionThreadContainer} from '../DiscussionThreadContainer'
import {fireEvent, render} from '@testing-library/react'
import {getSpeedGraderUrl} from '../../../utils'
import {handlers} from '../../../../graphql/mswHandlers'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../../shared/msw/mswServer'
import React from 'react'
import {waitFor} from '@testing-library/dom'
import {graphql} from 'msw'
import {User} from '../../../../graphql/User'

jest.mock('../../../utils', () => ({
  ...jest.requireActual('../../../utils'),
  responsiveQuerySizes: () => ({desktop: {maxWidth: '1024px'}})
}))

describe('DiscussionThreadContainer', () => {
  const server = mswServer(handlers)
  const onFailureStub = jest.fn()
  const onSuccessStub = jest.fn()
  const openMock = jest.fn()
  beforeAll(() => {
    delete window.location
    window.open = openMock
    window.ENV = {
      course_id: '1'
    }

    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn()
      }
    })

    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()
  })

  afterEach(() => {
    server.resetHandlers()
    onFailureStub.mockClear()
    onSuccessStub.mockClear()
    openMock.mockClear()
  })

  afterAll(() => {
    server.close()
    // eslint-disable-next-line no-undef
    fetchMock.enableMocks()
  })

  const defaultProps = ({
    discussionEntryOverrides = {},
    discussionOverrides = {},
    propOverrides = {}
  } = {}) => ({
    discussionTopic: Discussion.mock(discussionOverrides),
    discussionEntry: DiscussionEntry.mock(discussionEntryOverrides),
    ...propOverrides
  })

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
    const {queryByTestId} = setup(
      defaultProps({
        discussionEntryOverrides: {permissions: DiscussionEntryPermissions.mock({reply: false})}
      })
    )
    expect(queryByTestId('threading-toolbar-reply')).toBeFalsy()
  })

  it('should render reply button if reply permission is true', () => {
    const {queryByTestId} = setup(defaultProps())
    expect(queryByTestId('threading-toolbar-reply')).toBeTruthy()
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

  describe('Roles', () => {
    it('does not display author role if not the author', async () => {
      const {queryByTestId} = setup(defaultProps())
      expect(queryByTestId('pill-Author')).toBeFalsy()
    })

    it('displays author role if the post is from the author', async () => {
      const new_prop = defaultProps({
        discussionOverrides: {author: User.mock({_id: '3', displayName: 'Charles Xavier'})},
        discussionEntryOverrides: {author: User.mock({_id: '3', displayName: 'Charles Xavier'})}
      })
      const {queryByTestId} = setup(new_prop)

      expect(queryByTestId('pill-Author')).toBeTruthy()
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
    it('Should be able to open SpeedGrader when speedGrader permission is true', async () => {
      const {getByTestId} = setup(defaultProps())

      fireEvent.click(getByTestId('thread-actions-menu'))
      fireEvent.click(getByTestId('inSpeedGrader'))

      await waitFor(() => {
        expect(openMock).toHaveBeenCalledWith(getSpeedGraderUrl('1', '1', '2'), `_blank`)
      })
    })

    it('Should not be able to open SpeedGrader if is speedGrader permission is false', () => {
      const {getByTestId, queryByTestId} = setup(
        defaultProps({
          discussionOverrides: {permissions: DiscussionPermissions.mock({speedGrader: false})}
        })
      )

      fireEvent.click(getByTestId('thread-actions-menu'))
      expect(queryByTestId('inSpeedGrader')).toBeNull()
    })
  })

  describe('Go to Buttons', () => {
    it('Should call scrollTo when go to topic is pressed', async () => {
      const goToTopic = jest.fn()
      const {getByTestId} = setup(defaultProps({propOverrides: {goToTopic}}))

      fireEvent.click(getByTestId('thread-actions-menu'))
      fireEvent.click(getByTestId('toTopic'))

      await waitFor(() => {
        expect(goToTopic.mock.calls.length).toBe(1)
      })
    })
  })

  describe('Expand-Button', () => {
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

    it('pluralizes reply message correctly when there is only a single reply', async () => {
      const {getAllByText} = setup(defaultProps())
      expect(getAllByText('1 reply, 1 unread').length).toBe(2)
    })

    it('pluralizes replies message correctly when there are multiple replies', async () => {
      const {getAllByText} = setup(
        defaultProps({
          discussionEntryOverrides: {rootEntryParticipantCounts: {unreadCount: 1, repliesCount: 2}}
        })
      )
      expect(getAllByText('2 replies, 1 unread')).toBeTruthy()
    })

    it('does not display unread count if it is 0', async () => {
      const {queryAllByText} = setup(
        defaultProps({
          discussionEntryOverrides: {rootEntryParticipantCounts: {unreadCount: 0, repliesCount: 2}}
        })
      )
      expect(queryAllByText('2 replies, 0 unread').length).toBe(0)
      expect(queryAllByText('2 replies').length).toBe(2)
    })
  })
})
