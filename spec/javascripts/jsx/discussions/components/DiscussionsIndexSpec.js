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
import { Provider } from 'react-redux'
import { mount, shallow } from 'enzyme'

import DiscussionsIndex from 'jsx/discussions/components/DiscussionsIndex'

const defaultProps = () => ({
  closeForComments: () => {},
  closedForCommentsDiscussions: [],
  closedForCommentsDiscussionIds: [],
  discussions: [],
  discussionsPage: 1,
  getDiscussions: () => {},
  hasLoadedDiscussions: false,
  isLoadingDiscussions: false,
  permissions: {create: false, manage_content: false, moderate: false},
  pinnedDiscussions: [],
  pinnedDiscussionIds: [],
  roles: ["student", "user"],
  togglePin: () => {},
  unpinnedDiscussions: [],
  unpinnedDiscussionIds: [],
})

// necessary to mock this because we have a child Container/"Smart" component
// that need to pull their props from the store state
const store = {
  getState: () => ({
    allDiscussions: {},
    closedForCommentsDiscussionIds: [],
    contextId: '1',
    contextType: 'course',
    courseSettings: {collapse_global_nav: false, manual_mark_as_read: false},
    currentUserId: 1,
    discussions: [],
    isSavingSettings: false,
    isSettingsModalOpen: false,
    permissions: {
      create: true,
      manage_content: true,
      moderate: true,
    },
    pinnedDiscussionIds: [],
    roles: ['user', 'teacher'],
    unpinnedDiscussionIds: [],
    userSettings: {collapse_global_nav: false, manual_mark_as_read: false},
  }),
  // we only need to define these functions so that we match the react-redux contextTypes
  // shape for a store otherwise react-redux thinks our store is invalid
  dispatch() {},
  subscribe() {},
}

QUnit.module('DiscussionsIndex component')

test('renders the component', () => {
  const tree = mount(
    <Provider store={store}>
      <DiscussionsIndex {...defaultProps()} />
    </Provider>
  )
  const node = tree.find('DiscussionsIndex')
  ok(node.exists())
})

test('renders the IndexHeaderComponent component', () => {
  const tree = mount(
    <Provider store={store}>
      <DiscussionsIndex {...defaultProps()} />
    </Provider>
  )
  const node = tree.find('IndexHeader')
  ok(node.exists())
})

test('displays spinner when loading discussions', () => {
  const props = defaultProps()
  props.isLoadingDiscussions = true
  const tree = shallow(<DiscussionsIndex {...props} />)
  const node = tree.find('Spinner')
  ok(node.exists())
})

test('calls getDiscussions if hasLoadedDiscussions is false', () => {
  const props = defaultProps()
  props.getDiscussions = sinon.spy()
  mount(
    <Provider store={store}>
      <DiscussionsIndex {...props} />
    </Provider>
  )
  equal(props.getDiscussions.callCount, 1)
})

test('only renders pinned discussions in studentView if there are pinned discussions', () => {
  const props = defaultProps()
  props.pinnedDiscussions = [{id: '1'}]
  props.closedForCommentsDiscussions = []
  const tree = shallow(<DiscussionsIndex {...props} />)
  const node = tree.find('Connect(DiscussionsContainer)')
  equal(node.length, 3)
})

test('does not renders pinned discussions in studentView if there are no pinned discussions', () => {
  const props = defaultProps()
  props.closedForCommentsDiscussions = []
  const tree = shallow(<DiscussionsIndex {...props} />)
  const node = tree.find('Connect(DiscussionsContainer)')
  equal(node.length, 2)
})

test('does not render droppable container when student', () => {
  const props = defaultProps()
  const tree = shallow(<DiscussionsIndex {...props} />)
  const node = tree.find('Connect(DroppableDiscussionsContainer)')
  equal(node.length, 0)
})

test('renders three containers for teachers', () => {
  const props = defaultProps()
  props.permissions.moderate = true
  const tree = shallow(<DiscussionsIndex {...props} />)
  equal(tree.find('.closed-for-comments-discussions-v2__wrapper').length, 1)
  equal(tree.find('.unpinned-discussions-v2__wrapper').length, 1)
  equal(tree.find('.pinned-discussions-v2__wrapper').length, 1)
})
