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

import '@instructure/canvas-theme'
import React from 'react'
import {mount, shallow} from 'enzyme'
import ExternalFeedsTray from '../ExternalFeedsTray'
import {ConnectedRSSFeedList} from '../RSSFeedList'

const defaultProps = () => ({
  atomFeedUrl: 'www.test.com',
  permissions: {
    create: false,
    manage_course_content_edit: false,
    manage_course_content_delete: false,
    moderate: false,
  },
})

test('renders the ExternalFeedsTray component', () => {
  const tree = mount(<ExternalFeedsTray {...defaultProps()} />)
  expect(tree.exists()).toBe(true)
})

test('renders the AddExternalFeed component when user has permissions', () => {
  const props = defaultProps()
  props.permissions = {
    create: true,
    manage_course_content_edit: false,
    manage_course_content_delete: false,
    moderate: false,
  }
  const tree = shallow(<ExternalFeedsTray {...props} />)
  const node = tree.find('.announcements-tray__add-rss-root')
  expect(node).toHaveLength(1)
})

test('does not render the AddExternalFeed component when user is student', () => {
  const props = defaultProps()
  props.permissions = {
    create: false,
    manage_course_content_edit: false,
    manage_course_content_delete: false,
    moderate: false,
  }
  const tree = shallow(<ExternalFeedsTray {...props} />)
  const node = tree.find('.announcements-tray__add-rss-root')
  expect(node).toHaveLength(0)
})

test('does not render the RSSFeedList component when user is student', () => {
  const props = defaultProps()
  props.permissions = {
    create: false,
    manage_course_content_edit: false,
    manage_course_content_delete: false,
    moderate: false,
  }
  const tree = shallow(<ExternalFeedsTray {...props} />)
  const node = tree.find(ConnectedRSSFeedList)
  expect(node).toHaveLength(0)
})

test('renders the external feeds link', () => {
  const tree = mount(<ExternalFeedsTray {...defaultProps()} />)
  const node = tree.find('Link').first()
  expect(node.text()).toBe('External Feeds')
})

test('renders the RSS feed link', () => {
  const tree = shallow(<ExternalFeedsTray {...defaultProps()} />)
  expect(tree.find('#rss-feed-link').prop('children')).toMatch('RSS Feed')
})
