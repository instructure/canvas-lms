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

import '@instructure/canvas-theme'
import React from 'react'
import {shallow} from 'enzyme'
import IndexHeader from '../IndexHeader'

const hasText = text => node => node.text() === text
const defaultPermissions = () => ({
  create: false,
  manage_course_content_edit: false,
  manage_course_content_delete: false,
  moderate: false,
})

const defaultProps = () => ({
  contextType: 'course',
  contextId: 'c1',
  isBusy: false,
  selectedCount: 0,
  isToggleLocking: false,
  permissions: defaultPermissions(),
  atomFeedUrl: null,
  searchAnnouncements: () => Promise.reject(new Error('Not Implemented')),
  toggleSelectedAnnouncementsLock: () => Promise.reject(new Error('Not Implemented')),
  deleteSelectedAnnouncements: () => Promise.reject(new Error('Not Implemented')),
  searchInputRef: null,
  announcementsLocked: false,
})

test('renders', () => {
  const tree = shallow(<IndexHeader {...defaultProps()} />)
  expect(tree.exists()).toBe(true)
})

test('lets me add an announcement when I have the permission', () => {
  const tree = shallow(
    <IndexHeader {...defaultProps()} permissions={{...defaultPermissions(), create: true}} />
  )

  expect(tree.findWhere(hasText('Add announcement'))).toHaveLength(2)
})

test('lets me delete an announcement when I have the permission', () => {
  const tree = shallow(
    <IndexHeader
      {...defaultProps()}
      permissions={{...defaultPermissions(), manage_course_content_delete: true}}
    />
  )

  expect(tree.findWhere(hasText('Delete Selected Announcements'))).toHaveLength(2)
})
