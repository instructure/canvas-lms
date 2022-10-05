/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {mount, shallow} from 'enzyme'
import moment from 'moment'

import {
  DiscussionsContainer,
  mapState,
  discussionTarget,
} from 'ui/features/discussion_topics_index/react/components/DiscussionContainer'

const defaultProps = () => ({
  title: 'discussions',
  closeForComments: () => {},
  permissions: {create: false, manage_content: false, moderate: false},
  discussions: [{id: 1, filtered: false, permissions: {delete: true}}],
  discussionsPage: 1,
  isLoadingDiscussions: false,
  hasLoadedDiscussions: false,
  getDiscussions: () => {},
  roles: ['student', 'user'],
  renderContainerBackground: () => {},
})

QUnit.module('DiscussionsContainer component')

test('renders the component', () => {
  const tree = shallow(<DiscussionsContainer {...defaultProps()} />)
  const node = tree.find('.discussions-container__wrapper')
  ok(node.exists())
})

QUnit.module('for pinned discussions', () => {
  test('renders the component Ordered by Recent Activity text when not pinned', () => {
    const props = defaultProps()
    props.discussions = []
    props.pinned = undefined
    const tree = mount(<DiscussionsContainer {...props} />)
    const node = tree.find('.recent-activity-text-container')
    ok(node.exists())
  })

  test('will not render the component Ordered by Recent Activity text when pinned', () => {
    const props = defaultProps()
    props.discussions = []
    props.pinned = true
    const tree = mount(<DiscussionsContainer {...props} />)
    const node = tree.find('.recent-activity-text-container')
    notOk(node.exists())
  })
})

test('renders passed in component when renderContainerBackground is present', () => {
  const props = defaultProps()
  props.discussions = []
  props.renderContainerBackground = () => (
    <div className="discussions-v2__test-image">
      <p>testing</p>
    </div>
  )
  const tree = shallow(<DiscussionsContainer {...props} />)
  const node = tree.find('.discussions-v2__test-image')
  ok(node.exists())
})

test('renders regular discussion row when user does not have moderate permissions', () => {
  const props = defaultProps()
  const tree = shallow(<DiscussionsContainer {...props} />)
  const node = tree.find('Connect(WithDateFormat(DiscussionRow))')
  ok(node.exists())
})

test('renders a draggable discussion row when user has moderate permissions', () => {
  const props = defaultProps()
  props.permissions.moderate = true
  const tree = shallow(<DiscussionsContainer {...props} />)
  const node = tree.find('Connect(DropTarget(DragSource(WithDateFormat(DiscussionRow))))')
  ok(node.exists())
})

test('discussionTarget canDrop returns false if assignment due_at is in the past', () => {
  const assignment = {due_at: '2017-05-13T00:59:59Z'}
  const getItem = function () {
    return {assignment}
  }
  const mockMonitor = {getItem}
  ok(discussionTarget.canDrop({closedState: true}, mockMonitor))
})

test('discussionTarget canDrop returns true if not dragging to closed state', () => {
  const assignment = {due_at: '2018-05-13T00:59:59Z'}
  const getItem = function () {
    return {assignment}
  }
  const mockMonitor = {getItem}
  ok(discussionTarget.canDrop({closedState: false}, mockMonitor))
})

test('discussionTarget canDrop returns true if assignment due_at is in the future', () => {
  const dueAt = moment().add(7, 'days')
  const assignment = {due_at: dueAt.format()}
  const getItem = function () {
    return {assignment}
  }
  const mockMonitor = {getItem}
  ok(!discussionTarget.canDrop({closedState: true}, mockMonitor))
})

test('connected mapStateToProps filters out filtered discussions', () => {
  const state = {}
  const ownProps = {
    discussions: [
      {id: 1, filtered: true},
      {id: 2, filtered: false},
    ],
  }
  const connectedProps = mapState(state, ownProps)
  deepEqual(connectedProps.discussions, [{id: 2, filtered: false}])
})

test('renders background image no discussions are present', () => {
  const props = defaultProps()
  const renderBackgroundSpy = sinon.spy()
  props.discussions = []
  props.renderContainerBackground = renderBackgroundSpy

  const tree = mount(<DiscussionsContainer {...props} />)
  const node = tree.find('Connect(DiscussionRow)')
  ok(renderBackgroundSpy.calledOnce)
  ok(!node.exists())
})
