/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {fireEvent, render, waitFor} from '@testing-library/react'
import EnhancedSmartSearch from '../EnhancedSmartSearch'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'

const props = {
  courseId: '1',
}

const results = [
  {
    content_id: '1',
    content_type: 'Page',
    readable_type: 'page',
    title: 'Apple Pie',
    body: 'Apple pie is delicious.',
    html_url: '/courses/1/pages/syllabus',
    distance: 0.9,
    relevance: 0.99,
  },
  {
    content_id: '3',
    content_type: 'Page',
    readable_type: 'page',
    title: 'Growing fruit trees',
    body: 'Trees need water and sunlight to grow.',
    html_url: '/courses/1/pages/3',
    distance: 0.9,
    relevance: 0.2,
  },
]

describe('EnhancedSmartSearch', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  it('should render progress bar when indexing', async () => {
    fetchMock.get(`/api/v1/courses/${props.courseId}/smartsearch/index_status`, {
      status: 'indexing',
      progress: 75,
    })
    const {getByTestId, queryByText, getByText} = render(<EnhancedSmartSearch {...props} />)

    expect(queryByText('Similar Results')).toBeNull()
    expect(queryByText('Best Matches')).toBeNull()
    await waitFor(() => {
      expect(getByTestId('indexing_progress')).toBeInTheDocument()
      expect(getByText(/wait a moment while we get Smart Search ready/)).toBeInTheDocument()
    })
  })

  it('should render nothing when no search has been made', async () => {
    fetchMock.get(`/api/v1/courses/${props.courseId}/smartsearch/index_status`, {
      status: 'complete',
      progress: 100,
    })
    const {getByTestId, queryByTestId, queryByText} = render(<EnhancedSmartSearch {...props} />)

    expect(getByTestId('search-input')).toBeInTheDocument()

    expect(queryByText('Similar Results')).toBeNull()
    expect(queryByText('Best Matches')).toBeNull()
    expect(queryByTestId('indexing_progress')).toBeNull()
    expect(queryByText(/wait a moment while we get Smart Search ready/)).toBeNull()
  })

  it('should render results after a search has been made', async () => {
    const user = userEvent.setup()
    const searchTerm = 'apple'
    fetchMock.get(`/api/v1/courses/${props.courseId}/smartsearch/index_status`, {
      status: 'complete',
      progress: 100,
    })
    fetchMock.get(`/api/v1/courses/${props.courseId}/smartsearch?q=${searchTerm}&per_page=25`, {
      results: results,
    })
    const {getByTestId, getByText} = render(<EnhancedSmartSearch {...props} />)

    const searchInput = getByTestId('search-input')
    fireEvent.change(searchInput, {
      target: {value: searchTerm},
    })
    user.click(getByTestId('search-button'))

    await waitFor(() => {
      expect(getByText('Similar Results')).toBeInTheDocument()
      expect(getByText('Best Matches')).toBeInTheDocument()
      expect(getByText(results[0].title)).toBeInTheDocument()
      expect(getByText(results[1].title)).toBeInTheDocument()
    })
  })

  it('should render error message after failing to get results', async () => {
    const user = userEvent.setup()
    const searchTerm = 'apple'
    fetchMock.get(`/api/v1/courses/${props.courseId}/smartsearch/index_status`, {
      status: 'complete',
      progress: 100,
    })
    fetchMock.get(`/api/v1/courses/${props.courseId}/smartsearch?q=${searchTerm}&per_page=25`, 404)
    const {getByTestId, getByText} = render(<EnhancedSmartSearch {...props} />)

    const searchInput = getByTestId('search-input')
    fireEvent.change(searchInput, {
      target: {value: searchTerm},
    })
    user.click(getByTestId('search-button'))

    await waitFor(() => {
      expect(getByText(/Failed to execute search/)).toBeInTheDocument()
    })
  })
})
