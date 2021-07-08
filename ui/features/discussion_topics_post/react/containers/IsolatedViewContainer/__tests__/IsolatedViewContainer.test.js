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
import {fireEvent, render} from '@testing-library/react'
import {graphql} from 'msw'
import {handlers} from '../../../../graphql/mswHandlers'
import {IsolatedViewContainer} from '../IsolatedViewContainer'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../../shared/msw/mswServer'
import {PageInfo} from '../../../../graphql/PageInfo'
import React from 'react'

describe('IsolatedViewContainer', () => {
  const server = mswServer(handlers)
  const setOnFailure = jest.fn()
  const setOnSuccess = jest.fn()
  const onOpenIsolatedView = jest.fn()

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
    onOpenIsolatedView.mockClear()
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

  const defaultProps = overrides => ({
    discussionEntryId: '1',
    open: true,
    onClose: () => {},
    onOpenIsolatedView,
    ...overrides
  })

  it('should render', () => {
    const {container} = setup(defaultProps())
    expect(container).toBeTruthy()
  })

  it('should render a back button', async () => {
    const {findByTestId} = setup(defaultProps())

    const backButton = await findByTestId('back-button')
    expect(backButton).toBeInTheDocument()

    fireEvent.click(backButton)

    expect(onOpenIsolatedView).toHaveBeenCalledWith('77', false)
  })

  it('should go to root reply when clicking Go To Parent', async () => {
    server.use(
      graphql.query('GetDiscussionSubentriesQuery', (req, res, ctx) => {
        return res.once(
          ctx.data({
            legacyNode: DiscussionEntry.mock({
              discussionSubentriesConnection: {
                nodes: [
                  DiscussionEntry.mock({
                    _id: '50',
                    id: '50',
                    message: '<p>This is the child reply</p>',
                    rootEntry: DiscussionEntry.mock({id: '70'})
                  })
                ],
                pageInfo: PageInfo.mock(),
                __typename: 'DiscussionSubentriesConnection'
              }
            })
          })
        )
      })
    )

    const {findAllByTestId, findByText} = setup(defaultProps())

    const threadActionsMenus = await findAllByTestId('thread-actions-menu')
    expect(threadActionsMenus[1]).toBeInTheDocument()
    fireEvent.click(threadActionsMenus[1])

    const goToParentButton = await findByText('Go To Parent')
    expect(goToParentButton).toBeInTheDocument()
    fireEvent.click(goToParentButton)

    expect(onOpenIsolatedView).toHaveBeenCalledWith('70', false)
  })

  it('should not render a back button', async () => {
    server.use(
      graphql.query('GetDiscussionSubentriesQuery', (req, res, ctx) => {
        return res.once(
          ctx.data({
            legacyNode: DiscussionEntry.mock({parent: null})
          })
        )
      })
    )
    const {findByText, queryByTestId} = setup(defaultProps())
    expect(await findByText('This is the parent reply')).toBeInTheDocument()
    expect(queryByTestId('back-button')).toBeNull()
  })

  it('allows fetching more discussion entries', async () => {
    const {findByText, queryByText} = setup(defaultProps())

    const showOlderRepliesButton = await findByText('Show older replies')
    expect(showOlderRepliesButton).toBeInTheDocument()
    expect(queryByText('Get riggity riggity wrecked son')).toBe(null)

    server.use(
      graphql.query('GetDiscussionSubentriesQuery', (req, res, ctx) => {
        return res.once(
          ctx.data({
            legacyNode: DiscussionEntry.mock({
              discussionSubentriesConnection: {
                nodes: [
                  DiscussionEntry.mock({
                    id: '1337',
                    _id: '1337',
                    message: '<p>Get riggity riggity wrecked son</p>'
                  })
                ],
                pageInfo: PageInfo.mock(),
                __typename: 'DiscussionSubentriesConnection'
              }
            })
          })
        )
      })
    )

    fireEvent.click(showOlderRepliesButton)

    expect(await findByText('Get riggity riggity wrecked son')).toBeInTheDocument()
  })

  it('calls the onOpenIsolatedView callback when clicking View Replies', async () => {
    const {findByText} = setup(defaultProps())

    const viewRepliesButton = await findByText('View Replies')
    fireEvent.click(viewRepliesButton)

    expect(onOpenIsolatedView).toHaveBeenCalledWith('50', false)
  })

  it('calls the onOpenIsolatedView callback when clicking reply', async () => {
    const {findAllByText} = setup(defaultProps())

    const replyButton = await findAllByText('Reply')
    fireEvent.click(replyButton[1])

    expect(onOpenIsolatedView).toHaveBeenCalledWith('50', true)
  })

  describe('replying', () => {
    describe('RCE is open', () => {
      const props = defaultProps({RCEOpen: true})

      it('should not display children', () => {
        const {queryByTestId} = setup(props)
        expect(queryByTestId('isolated-view-children')).toBeFalsy()
      })
    })

    describe('RCE is closed', () => {
      const props = defaultProps({RCEOpen: false})

      it('should display children', async () => {
        const {findByTestId} = setup(props)
        expect(await findByTestId('isolated-view-children')).toBeTruthy()
      })
    })
  })

  it('disables the reply and enables the expand buttons if the RCE is open', async () => {
    const setRCEOpen = jest.fn()
    const {findByTestId} = setup(defaultProps({RCEOpen: true, setRCEOpen}))

    expect(await findByTestId('DiscussionEdit-container')).toBeInTheDocument()
    expect(await findByTestId('threading-toolbar-reply')).toBeDisabled()
    expect(await findByTestId('expand-button')).toBeEnabled()
  })

  it('disables the expand and enables the reply buttons if the RCE is closed', async () => {
    const setRCEOpen = jest.fn()
    const {findAllByTestId, queryByTestId} = setup(defaultProps({RCEOpen: false, setRCEOpen}))

    const replyButtons = await findAllByTestId('threading-toolbar-reply')
    expect(replyButtons[0]).toBeEnabled()
    const expandButtons = await findAllByTestId('expand-button')
    expect(expandButtons[0]).toBeDisabled()
    expect(queryByTestId('DiscussionEdit-container')).toBe(null)
  })

  it('calls the setRCEOpen callback with false when clicking the expand button', async () => {
    const setRCEOpen = jest.fn()
    const {findByTestId} = setup(defaultProps({RCEOpen: true, setRCEOpen}))

    fireEvent.click(await findByTestId('expand-button'))
    expect(setRCEOpen).toHaveBeenCalledWith(false)
  })

  it('calls the setRCEOpen callback with true when clicking the reply button', async () => {
    const setRCEOpen = jest.fn()
    const {findAllByTestId} = setup(defaultProps({RCEOpen: false, setRCEOpen}))

    const replyButtons = await findAllByTestId('threading-toolbar-reply')
    fireEvent.click(replyButtons[0])
    expect(setRCEOpen).toHaveBeenCalledWith(true)
  })
})
