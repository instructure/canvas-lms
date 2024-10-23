/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render as testingLibraryRender} from '@testing-library/react'
import HistoryList from '../HistoryList'
import {QueryProvider, queryClient} from '@canvas/query'

const render = (children: unknown) =>
  testingLibraryRender(<QueryProvider>{children}</QueryProvider>)

describe('HistoryList', () => {
  const historyPage1 = [
    {
      asset_code: 'discussion_topic_1',
      asset_icon: 'icon-discussion',
      asset_name: 'Longitude vs Latitude',
      asset_readable_category: 'Discussion',
      context_id: 1,
      context_name: 'Geography 100',
      context_type: 'Course',
      visited_at: '2024-10-01T16:12:39Z',
      visited_url: 'http://localhost:3000/courses/1/discussion_topics/1',
    },
    {
      asset_code: 'assignment_1',
      asset_icon: 'icon-assignment',
      asset_name: 'A0: Compass Rose',
      asset_readable_category: 'Assignment',
      context_id: 2,
      context_name: 'Cartography 100',
      context_type: 'Course',
      visited_at: '2024-04-01T16:12:39Z',
      visited_url: 'http://localhost:3000/courses/2/assignments/1',
    },
  ]

  const historyPage2 = [
    {
      asset_code: 'discussion_topic_1',
      asset_icon: 'icon-discussion',
      asset_name: 'Longitude vs Latitude',
      asset_readable_category: 'Discussion',
      context_id: 1,
      context_name: 'Geography 100',
      context_type: 'Course',
      visited_at: '2022-10-01T16:12:39Z',
      visited_url: 'http://localhost:3000/courses/1/discussion_topics/1',
    },
  ]

  // infinite query inserts queryFn output into an array of pages
  const historyQuery = {
    pages: [
      {
        json: historyPage1,
      },
      {
        json: historyPage2,
      },
    ],
  }

  beforeAll(() => {
    queryClient.setQueryData(['history'], historyQuery)
  })

  it('renders a history item with the link', () => {
    const {getByText} = render(<HistoryList />)
    const discussionLink = getByText('Longitude vs Latitude')
    expect(discussionLink).toHaveAttribute('href', historyPage1[0].visited_url)
  })

  it('renders context', () => {
    const {getByText} = render(<HistoryList />)
    expect(getByText('Cartography 100')).toBeInTheDocument()
  })

  it('renders most recent visited between duplicates', () => {
    const {getAllByText, getByTestId} = render(<HistoryList />)
    const discussions = getAllByText('Longitude vs Latitude')
    const dates = getByTestId('discussion_topic_1_time_ago')
    // time ago is formatted according to 'time from current date'
    // to keep tests consistent, check data-timestamp attr instead
    expect(dates).toHaveAttribute('data-timestamp', historyPage1[0].visited_at)
    expect(discussions).toHaveLength(1)
  })
})
