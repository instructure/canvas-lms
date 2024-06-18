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
import {render, screen} from '@testing-library/react'
import {applyMiddleware, createStore} from 'redux'
import {thunk} from 'redux-thunk'
import rootReducer from '../../rootReducer'
import {Provider} from 'react-redux'
import DiscussionsIndex from '../DiscussionsIndex'

describe('DiscussionIndex', () => {
  const defaultProps = {
    contextId: '1',
    contextType: '',
    closeForComments: () => {},
    deleteDiscussion: () => {},
    setCopyToOpen: () => {},
    setSendToOpen: () => {},
    arrangePinnedDiscussions: () => {},
    closedForCommentsDiscussions: [],
    closedForCommentsDiscussionIds: [],
    discussions: [],
    discussionsPage: 1,
    copyToOpen: false,
    sendToOpen: false,
    getDiscussions: () => {},
    hasLoadedDiscussions: false,
    isLoadingDiscussions: false,
    permissions: {create: false, manage_content: false, moderate: false},
    roles: ['student', 'user'],
    togglePin: () => {},
    unpinnedDiscussions: [],
    unpinnedDiscussionIds: [],
    DIRECT_SHARE_ENABLED: false,
    pinnedDiscussions: [],
    pinnedDiscussionIds: [],
  }

  const initialState = {
    contextId: '1',
    contextType: '',
    permissions: {
      create: false,
      manage_content: false,
      moderate: false,
      publish: false,
      read_as_admin: false,
    },
  }

  const oldEnv = window.ENV

  beforeEach(() => {
    window.ENV.FEATURES.selective_release_ui_api = true
  })

  afterEach(() => {
    window.ENV = oldEnv
  })

  function mockStore(initialState) {
    return applyMiddleware(thunk)(createStore)(rootReducer, initialState)
  }

  function renderConnectedComponent(propOverrides = {}, storeState = initialState) {
    const props = {...defaultProps, ...propOverrides}
    return render(
      <Provider store={mockStore(storeState)}>
        <DiscussionsIndex {...props} />
      </Provider>
    )
  }

  it('renders the component', () => {
    expect(() => {
      renderConnectedComponent()
    }).not.toThrow()
  })

  it('renders the IndexHeaderComponent component', () => {
    renderConnectedComponent()
    expect(screen.getByTestId('discussions-index-container')).toBeInTheDocument()
  })

  it('displays spinner when loading discussions', () => {
    const overrideProps = {isLoadingDiscussions: true}
    renderConnectedComponent(overrideProps)
    expect(screen.getByTestId('discussions-index-spinner-container')).toBeInTheDocument()
  })

  it('calls getDiscussions if hasLoadedDiscussions is false', () => {
    const getDiscussionsMock = jest.fn()
    const overrideProps = {getDiscussions: getDiscussionsMock}
    renderConnectedComponent(overrideProps)
    expect(getDiscussionsMock).toHaveBeenCalled()
  })

  it('only renders pinned discussions in studentView if there are pinned discussions', () => {
    const overrideProps = {
      closedForCommentsDiscussions: [],
      pinnedDiscussions: [
        {
          id: '1',
          published: false,
          title: 'foo',
          posted_at: 'January 10, 2019 at 10:00 AM',
          read_state: 'unread',
          unread_count: 1,
          subscribed: false,
          can_lock: true,
          user_count: 5,
          permissions: {delete: true, update: true, manage_assign_to: true},
          author: {id: '1', display_name: 'bar', name: 'bar', html_url: ''},
        },
      ],
    }
    renderConnectedComponent(overrideProps)
    expect(screen.getAllByTestId('discussion-connected-container').length).toBe(3)
  })

  it('does not render pinned discussions in studentView if there are no pinned discussions', () => {
    const overrideProps = {closedForCommentsDiscussions: []}
    renderConnectedComponent(overrideProps)
    expect(screen.getAllByTestId('discussion-connected-container').length).toBe(2)
  })

  it('does not render droppable container when student', () => {
    renderConnectedComponent()
    expect(screen.queryByTestId('discussion-droppable-connected-container')).not.toBeInTheDocument()
  })

  it('renders three containers for teachers', () => {
    const overrideProps = {
      permissions: {...defaultProps.permissions, moderate: true},
      closedForCommentsDiscussions: [],
    }

    renderConnectedComponent(overrideProps)
    expect(screen.getAllByTestId('discussion-droppable-connected-container').length).toBe(3)
  })
})
