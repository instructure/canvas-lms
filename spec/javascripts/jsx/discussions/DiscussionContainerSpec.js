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
import { mount, shallow } from 'enzyme'

import DiscussionContainer from 'jsx/discussions/components/DiscussionContainer'

const defaultProps = () => ({
  title: "discussions",
  closeForComments: () => {},
  permissions: {create: false, manage_content: false, moderate: false},
  togglePin: () => {},
  discussions: [{id: 1, filtered: false, permissions: {delete: true}}],
  discussionsPage: 1,
  isLoadingDiscussions: false,
  hasLoadedDiscussions: false,
  getDiscussions: () => {},
  roles: ["student", "user"],
  renderContainerBackground: () => {},
})

QUnit.module('DiscussionContainer component')

test('renders the component', () => {
  const tree = mount(<DiscussionContainer {...defaultProps()} />)
  const node = tree.find('.discussions-container__wrapper')
  ok(node.exists())
})

test('renders passed in component when renderContainerBackground is present', () => {
  const props = defaultProps()
  props.discussions = []
  props.renderContainerBackground = () => (
    <div className="discussions-v2__test-image">
      <p>testing</p>
    </div>
  )
  const tree = shallow(<DiscussionContainer {...props} />)
  const node = tree.find('.discussions-v2__test-image')
  ok(node.exists())
})

test('renders regular discussion row when user does not have moderate permissions', () => {
  const props = defaultProps()
  const tree = shallow(<DiscussionContainer {...props} />)
  const node = tree.find('DiscussionRow')
  ok(node.exists())
})

test('renders a draggable discussion row when user has moderate permissions', () => {
  const props = defaultProps()
  props.permissions.moderate = true
  const tree = shallow(<DiscussionContainer {...props} />)
  const node = tree.find('DropTarget(DragSource(DiscussionRow))')
  ok(node.exists())
})

test('renders discussion row when discussion is not filtered', () => {
  const props = defaultProps()
  props.discussions = [{id: 1, filtered: false, permissions: {delete: true}}]
  const tree = shallow(<DiscussionContainer {...props} />)
  const node = tree.find('DiscussionRow')
  ok(node.exists())
})

test('does not render a discussion row when discussion is filtered', () => {
  const props = defaultProps()
  props.discussions = [{id: 1, filtered: true}]
  const tree = shallow(<DiscussionContainer {...props} />)
  const node = tree.find('DiscussionRow')
  ok(!node.exists())
})

test('renders background image if all discussions are filtered', () => {
  const props = defaultProps()
  const renderBackgroundSpy = sinon.spy()
  props.discussions = [{id: 1, filtered: true}]
  props.renderContainerBackground = renderBackgroundSpy

  const tree = mount(<DiscussionContainer {...props} />)
  const node = tree.find('DiscussionRow')
  ok(renderBackgroundSpy.calledOnce)
  ok(!node.exists())
})
