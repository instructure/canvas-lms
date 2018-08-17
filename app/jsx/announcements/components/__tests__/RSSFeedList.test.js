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
import {mount} from 'enzyme'
import RSSFeedList from '../RSSFeedList'

const defaultProps = () => ({
  feeds: [],
  hasLoadedFeed: false,
  getExternalFeeds: () => {},
  deleteExternalFeed: () => {}
})

const defaultFeeds = () => [
  {
    display_name: 'felix',
    id: '22',
    external_feed_entries_count: 10,
    url: 'donotcare.com'
  },
  {
    display_name: 'steven',
    id: '24',
    external_feed_entries_count: 12,
    url: 'donotcare.com'
  },
  {
    display_name: 'landon',
    id: '67',
    external_feed_entries_count: 0,
    url: 'donotcare.com'
  },
  {
    display_name: 'aaron',
    id: '32',
    external_feed_entries_count: 4,
    url: 'donotcare.com'
  },
  {
    display_name: 'venk',
    id: '55',
    external_feed_entries_count: 5,
    url: 'donotcare.com'
  }
]

test('renders the RSSFeedList component', () => {
  const tree = mount(<RSSFeedList {...defaultProps()} />)
  expect(tree.exists()).toBe(true)
})

test('renders the RSSFeedList component loading indicator when not loading', () => {
  const props = defaultProps()
  props.hasLoadedFeed = false
  const tree = mount(<RSSFeedList {...props} />)
  const node = tree.find('Spinner')
  expect(node).toHaveLength(1)
})

test('renders the RSSFeedList component with 5 rows for 5 feeds', () => {
  const props = defaultProps()
  props.hasLoadedFeed = true
  props.feeds = defaultFeeds()
  const tree = mount(<RSSFeedList {...props} />)
  const node = tree.find('Grid')
  expect(node).toHaveLength(5)
})

test('calls getExternalFeeds when feed has not been loaded', () => {
  const props = defaultProps()
  props.hasLoadedFeed = false
  props.getExternalFeeds = jest.fn()
  props.feeds = defaultFeeds()
  mount(<RSSFeedList {...props} />)
  expect(props.getExternalFeeds.mock.calls).toHaveLength(1)
})

test('does not call getExternalFeeds when feed has been loaded', () => {
  const props = defaultProps()
  props.hasLoadedFeed = true
  props.getExternalFeeds = jest.fn()
  props.feeds = defaultFeeds()
  mount(<RSSFeedList {...props} />)
  expect(props.getExternalFeeds.mock.calls).toHaveLength(0)
})

test('calls deleteExternalFeed with correct feed ID when deleting feed', () => {
  const props = defaultProps()
  props.hasLoadedFeed = true
  props.deleteExternalFeed = jest.fn()
  props.feeds = [
    {
      display_name: 'felix',
      id: '22',
      external_feed_entries_count: 10,
      url: 'donotcare.com'
    },
    {
      display_name: 'steven',
      id: '24',
      external_feed_entries_count: 12,
      url: 'donotcare.com'
    },
    {
      display_name: 'aaron',
      id: '32',
      external_feed_entries_count: 4,
      url: 'donotcare.com'
    }
  ]
  const tree = mount(<RSSFeedList {...props} />)
  const instance = tree.instance()
  instance.deleteExternalFeed('22')
  expect(props.deleteExternalFeed.mock.calls).toHaveLength(1)
  expect(props.deleteExternalFeed.mock.calls[0][0]).toEqual({feedId: '22'})
})
