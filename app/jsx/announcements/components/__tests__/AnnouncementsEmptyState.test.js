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

import '@instructure/ui-themes/lib/canvas'
import React from 'react'
import { mount } from 'enzyme'
import AnnouncementEmptyState from '../AnnouncementEmptyState'

const defaultProps = () => ({
  canCreate: true
})

test('renders the AnnouncementsEmptyState component', () => {
  const tree = mount(<AnnouncementEmptyState {...defaultProps()} />)
  expect(tree.exists()).toBe(true)
})

test('renders the AnnouncementsEmptyState component when teacher', () => {
  const props = defaultProps()
  props.canCreate = true
  const tree = mount(<AnnouncementEmptyState {...defaultProps()} />)
  const node = tree.find('Text')
  expect(node.text()).toBe('Create announcements above')
})

test('renders the AnnouncementsEmptyState component when student', () => {
  const props = defaultProps()
  props.canCreate = false
  const tree = mount(<AnnouncementEmptyState {...props} />)
  const node = tree.find('Text')
  expect(node.text()).toBe('Check back later')
})
