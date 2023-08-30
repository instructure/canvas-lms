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

import {mount} from 'enzyme'
import {
  pinnedDiscussionBackground,
  unpinnedDiscussionsBackground,
  closedDiscussionBackground,
} from 'ui/features/discussion_topics_index/react/components/DiscussionBackgrounds'

const defaultProps = () => ({
  permissions: {
    create: true,
    manage_content: true,
    moderate: true,
  },
  courseID: 12,
  contextType: 'Course',
})

QUnit.module('DiscussionBackgrounds components')

test('renders correct student view for the pinnedDiscussionBackground ', () => {
  const props = defaultProps()
  props.permissions.manage_content = false
  const tree = mount(pinnedDiscussionBackground(props))
  const node = tree.find('Text')
  equal(node.length, '2')
  tree.unmount()
})

test('renders correct student view for the unpinnedDiscussionsBackground decorative component', () => {
  const props = defaultProps()
  props.permissions.create = false
  const tree = mount(unpinnedDiscussionsBackground(props))
  const node = tree.find('Link')
  equal(node.length, '0')
  tree.unmount()
})

test('renders correct student view for the closedDiscussionBackground decorative component', () => {
  const props = defaultProps()
  props.permissions.manage_content = false
  const tree = mount(closedDiscussionBackground(props))
  const node = tree.find('Text')
  equal(node.length, '2')
  tree.unmount()
})
