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
  discussions: [{id: 1}],
  discussionsPage: 1,
  isLoadingDiscussions: false,
  hasLoadedDiscussions: false,
  getDiscussions: () => {},
  roles: ["student", "user"],
})

QUnit.module('DiscussionContainer component')

test('renders the component', () => {
  const tree = mount(<DiscussionContainer {...defaultProps()} />)
  const node = tree.find('.discussions-container__wrapper')
  ok(node.exists())
})

test('renders placeholder when no discussions are present', () => {
  const props = defaultProps()
  props.discussions = []
  const tree = shallow(<DiscussionContainer {...props} />)
  const node = tree.find('.discussions-v2__placeholder')
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
  const node = tree.find('DragSource(DiscussionRow)')
  ok(node.exists())
})

