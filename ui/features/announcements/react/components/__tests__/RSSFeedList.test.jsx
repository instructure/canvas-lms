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
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event';
import RSSFeedList from '../RSSFeedList'

const defaultFeeds = () => [
  {
    display_name: 'felix',
    id: '22',
    external_feed_entries_count: 10,
    url: 'donotcare.com',
  },
  {
    display_name: 'steven',
    id: '24',
    external_feed_entries_count: 12,
    url: 'donotcare.com',
  },
  {
    display_name: 'landon',
    id: '67',
    external_feed_entries_count: 0,
    url: 'donotcare.com',
  },
  {
    display_name: 'aaron',
    id: '32',
    external_feed_entries_count: 4,
    url: 'donotcare.com',
  },
  {
    display_name: 'venk',
    id: '55',
    external_feed_entries_count: 5,
    url: 'donotcare.com',
  },
]

const renderComponent = (props = {}) => {
  const defaultProps = {
    feeds: [],
    hasLoadedFeed: false,
    getExternalFeeds: () => {},
    deleteExternalFeed: () => {},
    focusLastElement: () => {},
  }
  return render(<RSSFeedList {...defaultProps} {...props} />)
}

test('renders the RSSFeedList component', () => {
  const feeds = defaultFeeds()
  const tree = renderComponent({ hasLoadedFeed: true, feeds })
  expect(tree.getByText(feeds[0].display_name)).toBeInTheDocument()
})

test('renders the RSSFeedList component loading indicator when loading', () => {
  const tree = renderComponent({ hasLoadedFeed: false })
  expect(tree.getByText('Adding RSS Feed')).toBeInTheDocument()
})

test('renders the RSSFeedList component with 5 rows for 5 feeds', () => {
  const feeds = defaultFeeds()
  const tree = renderComponent({ hasLoadedFeed: true, feeds })
  feeds.forEach(feed => {
    expect(tree.getByText(feed.display_name)).toBeInTheDocument()
  })
  expect(tree.getAllByRole('button').length).toBe(5)
})

test('calls getExternalFeeds when feed has not been loaded', () => {
  const mockGetExternalFeeds = jest.fn()
  renderComponent({
    hasLoadedFeed: false,
    getExternalFeeds: mockGetExternalFeeds
  })

  expect(mockGetExternalFeeds).toHaveBeenCalledTimes(1)
})

test('does not call getExternalFeeds when feed has been loaded', () => {
  const mockGetExternalFeeds = jest.fn()
  renderComponent({
    hasLoadedFeed: true,
    getExternalFeeds: mockGetExternalFeeds
  })

  expect(mockGetExternalFeeds).not.toHaveBeenCalled()
})

test('calls deleteExternalFeed with correct feed ID when deleting feed', async () => {
  const mockDeleteExternalFeed = jest.fn()
  const feeds = [
    {
      display_name: 'felix',
      id: '22',
      external_feed_entries_count: 10,
      url: 'donotcare.com',
    },
    {
      display_name: 'steven',
      id: '24',
      external_feed_entries_count: 12,
      url: 'donotcare.com',
    },
    {
      display_name: 'aaron',
      id: '32',
      external_feed_entries_count: 4,
      url: 'donotcare.com',
    },
  ]
  const tree = renderComponent({
    feeds,
    hasLoadedFeed: true,
    deleteExternalFeed: mockDeleteExternalFeed,
  })
  await userEvent.click(tree.getByRole('button', {name: 'Delete felix'}))

  expect(mockDeleteExternalFeed).toHaveBeenCalledTimes(1)
  expect(mockDeleteExternalFeed).toHaveBeenCalledWith({feedId: '22'})
})
