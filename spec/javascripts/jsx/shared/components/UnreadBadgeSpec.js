/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import UnreadBadge from '@canvas/unread-badge'

QUnit.module('UnreadBadge component')

const defaultProps = () => ({
  unreadCount: 2,
  totalCount: 5,
  unreadLabel: '2 unread replies',
  totalLabel: '5 total replies',
})

test('renders the UnreadBadge component', () => {
  const tree = mount(<UnreadBadge {...defaultProps()} />)
  ok(tree.exists())
})

test('renders the correct unread count', () => {
  const tree = shallow(<UnreadBadge {...defaultProps()} />)
  const node = tree.find('.ic-unread-badge__unread-count')
  equal(node.text(), '2')
})

test('renders the correct total count', () => {
  const tree = shallow(<UnreadBadge {...defaultProps()} />)
  const node = tree.find('.ic-unread-badge__total-count')
  equal(node.text(), '5')
})
