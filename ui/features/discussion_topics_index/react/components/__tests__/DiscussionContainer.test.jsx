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
import {DiscussionsContainer, discussionTarget, mapState} from '../DiscussionContainer'
import {Provider} from 'react-redux'
import {applyMiddleware, createStore} from 'redux'
import {thunk} from 'redux-thunk'
import rootReducer from '../../rootReducer'
import moment from 'moment/moment'

describe('DiscussionsContainer', () => {
  const defaultProps = {
    title: 'discussions',
    closeForComments: () => {},
    permissions: {create: false, manage_content: false, moderate: false},
    discussions: [
      {
        id: '1',
        filtered: false,
        published: false,
        title: 'Hello World',
        can_lock: false,
        permissions: {delete: false, update: false, manage_assign_to: false},
        posted_at: 'January 10, 2019 at 10:00 AM',
        author: {
          id: '5',
          name: 'John Smith',
          display_name: 'John Smith',
          html_url: '',
          avatar_image_url: null,
        },
        read_state: 'unread',
        unread_count: 0,
        user_count: 5,
        subscribed: false,
      },
    ],
    discussionsPage: 1,
    isLoadingDiscussions: false,
    hasLoadedDiscussions: false,
    getDiscussions: () => {},
    roles: ['student', 'user'],
    renderContainerBackground: () => {},
    cleanDiscussionFocus: () => {},
    deleteDiscussion: () => {},
    deleteFocusDone: () => {},
    deleteFocusPending: false,
  }

  const initialState = {
    permissions: {
      publish: false,
      read_as_admin: false,
      manage_content: false,
      moderate: false,
    },
    contextType: '',
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
        <DiscussionsContainer {...props} />
      </Provider>
    )
  }

  function getMockMonitor(dueAt = '2018-05-13T00:59:59Z') {
    return {
      getItem: () => ({
        assignment: {
          due_at: dueAt,
        },
      }),
    }
  }

  it('renders the component', () => {
    expect(() => {
      renderConnectedComponent()
    }).not.toThrow()
  })

  describe('for pinned discussions', () => {
    it('renders the component Ordered by Recent Activity text when not pinned', () => {
      const props = {...defaultProps, discussions: [], pinned: undefined}
      render(<DiscussionsContainer {...props} />)
      expect(screen.getByText('Ordered by Recent Activity')).toBeInTheDocument()
    })

    it('will not render the component Ordered by Recent Activity text when pinned', () => {
      const props = {...defaultProps, discussions: [], pinned: true}
      render(<DiscussionsContainer {...props} />)
      expect(screen.queryByText('Ordered by Recent Activity')).not.toBeInTheDocument()
    })
  })

  it('renders passed in component when renderContainerBackground is present', () => {
    const props = {
      ...defaultProps,
      discussions: [],
      renderContainerBackground: () => (
        <div data-testid="discussions-v2__test-image">
          <p>testing</p>
        </div>
      ),
    }

    render(<DiscussionsContainer {...props} />)
    expect(screen.getByTestId('discussions-v2__test-image')).toBeInTheDocument()
  })

  it('renders regular discussion row when user does not have moderate permissions', () => {
    renderConnectedComponent()
    expect(screen.getByTestId('discussion-row-container')).toBeInTheDocument()
  })

  it('renders a draggable discussion row when user has moderate permissions', () => {
    const propOverrides = {permissions: {...defaultProps.permissions, moderate: true}}
    renderConnectedComponent(propOverrides)
    expect(screen.getByTestId('discussion-draggable-row-container')).toBeInTheDocument()
  })

  it('discussionTarget canDrop returns true if assignment due_at is in the past', () => {
    const mockMonitor = getMockMonitor('2017-05-13T00:59:59Z')
    expect(discussionTarget.canDrop({closedState: true}, mockMonitor)).toBeTruthy()
  })

  it('discussionTarget canDrop returns true if not dragging to closed state', () => {
    const mockMonitor = getMockMonitor('2018-05-13T00:59:59Z')
    expect(discussionTarget.canDrop({closedState: false}, mockMonitor)).toBeTruthy()
  })

  it('discussionTarget canDrop returns false if assignment due_at is in the future', () => {
    const dueAt = moment().add(7, 'days')
    const mockMonitor = getMockMonitor(dueAt.format())
    expect(discussionTarget.canDrop({closedState: true}, mockMonitor)).toBeFalsy()
  })

  it('connected mapStateToProps filters out filtered discussions', () => {
    const state = {}
    const ownProps = {
      discussions: [
        {id: 1, filtered: true},
        {id: 2, filtered: false},
      ],
    }
    const connectedProps = mapState(state, ownProps)
    expect(connectedProps.discussions).toEqual([{id: 2, filtered: false}])
  })

  it('renders background image no discussions are present', () => {
    const renderBackgroundMock = jest.fn()
    const propOverrides = {discussions: [], renderContainerBackground: renderBackgroundMock}

    renderConnectedComponent(propOverrides)
    expect(renderBackgroundMock).toHaveBeenCalled()
    expect(screen.queryByTestId('discussion-row-container')).not.toBeInTheDocument()
    expect(screen.queryByTestId('discussion-draggable-row-container')).not.toBeInTheDocument()
  })
})
