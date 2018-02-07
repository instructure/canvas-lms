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

import DiscussionsIndex from 'jsx/discussions/components/DiscussionsIndex'

const defaultProps = () => ({

  closeForComments: () => {},
  permissions: {create: false, manage_content: false, moderate: false},
  togglePin: () => {},
  discussions: [],
  discussionsPage: 1,
  isLoadingDiscussions: false,
  hasLoadedDiscussions: false,
  getDiscussions: () => {},
  roles: ["student", "user"],
})

QUnit.module('DiscussionsIndex component')

test('renders the component', () => {
  const tree = mount(<DiscussionsIndex {...defaultProps()} />)
  const node = tree.find('DiscussionsIndex')
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
  mount(<DiscussionsIndex {...props} />)
  equal(props.getDiscussions.callCount, 1)
})

test('renders two discussion containers when student', () => {
  const props = defaultProps()
  const tree = shallow(<DiscussionsIndex {...props} />)
  const node = tree.find('DiscussionsContainer')
  equal(node.length, 2)
})

test('does not render droppable container when student', () => {
  const props = defaultProps()
  const tree = shallow(<DiscussionsIndex {...props} />)
  const node = tree.find('DroppableDiscussionsContainer')
  equal(node.length, 0)
})

test('renders three containers for teachers', () => {
  const props = defaultProps()
  props.roles = ['teacher', 'ta', 'admin']
  const tree = shallow(<DiscussionsIndex {...props} />)
  equal(tree.find('.closed-for-comments-discussions-v2__wrapper').length, 1)
  equal(tree.find('.unpinned-discussions-v2__wrapper').length, 1)
  equal(tree.find('.pinned-discussions-v2__wrapper').length, 1)
})
