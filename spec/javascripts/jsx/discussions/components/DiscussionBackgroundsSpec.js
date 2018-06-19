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


import {shallow} from 'enzyme'
import {
  pinnedDiscussionBackground,
  unpinnedDiscussionsBackground,
  closedDiscussionBackground
} from 'jsx/discussions/components/DiscussionBackgrounds'

import SVGWrapper from 'jsx/shared/SVGWrapper'

const defaultProps = () => ({
  permissions: {
    create: true,
    manage_content: true,
    moderate: true
  },
  courseID: 12,
  contextType: "Course"
})

QUnit.module('DiscussionBackgrounds components')

test('renders the pinnedDiscussionBackground decorative component', () => {
  const tree = shallow(pinnedDiscussionBackground(defaultProps()))
  const node = tree.find(SVGWrapper)
  ok(node.exists())
})

test('renders the unpinnedDiscussionsBackground decorative component', () => {
  const tree = shallow(unpinnedDiscussionsBackground(defaultProps()))
  const node = tree.find(SVGWrapper)
  ok(node.exists())
})

test('renders the closedDiscussionBackground decorative component', () => {
  const tree = shallow(closedDiscussionBackground(defaultProps()))
  const node = tree.find(SVGWrapper)
  ok(node.exists())
})

test('renders correct student view for the pinnedDiscussionBackground ', () => {
  const props = defaultProps()
  props.permissions.manage_content = false
  const tree = shallow(pinnedDiscussionBackground(props))
  const node = tree.find('Text')
  equal(node.length, '1')
})

test('renders correct student view for the unpinnedDiscussionsBackground decorative component', () => {
  const props = defaultProps()
  props.permissions.create = false
  const tree = shallow(unpinnedDiscussionsBackground(props))
  const node = tree.find('Link')
  equal(node.length, '0')
})

test('renders correct student view for the closedDiscussionBackground decorative component', () => {
  const props = defaultProps()
  props.permissions.manage_content = false
  const tree = shallow(closedDiscussionBackground(props))
  const node = tree.find('Text')
  equal(node.length, '1')
})
