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

import {fireEvent, render, waitFor, within} from '@testing-library/react'
import SmartSearch from '../SmartSearch'
import {BrowserRouter, Routes, Route} from 'react-router-dom'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'

const props = {
  courseId: '1',
}

const modules1 = [
  {
    id: 1,
    name: 'Module 1',
    position: 0,
    prerequisite_module_ids: [],
    published: true,
    items_url: '',
  },
]

const modules2 = [
  {
    id: 2,
    name: 'Module 2',
    position: 0,
    prerequisite_module_ids: [],
    published: true,
    items_url: '',
  },
]

const results = [
  {
    content_id: '1',
    content_type: 'Page',
    readable_type: 'page',
    title: 'Apple Pie',
    body: 'Apple pie is delicious.',
    html_url: '/courses/1/pages/syllabus',
    distance: 0.9,
    relevance: 80,
    modules: modules1,
    published: false,
    due_date: null,
  },
  {
    content_id: '2',
    content_type: 'Assignment',
    readable_type: 'assignment',
    title: 'Growing fruit trees',
    body: 'Trees need water and sunlight to grow.',
    html_url: '/courses/1/assignments/2',
    distance: 0.9,
    relevance: 20,
    modules: modules2,
    published: true,
    due_date: '2025-05-09T05:00:00Z',
  },
]

const SEARCH_TERM = 'apple'

const INDEX_URL = `/api/v1/courses/${props.courseId}/smartsearch/index_status`
const SEARCH_URL = encodeURI(
  `/api/v1/courses/${props.courseId}/smartsearch?q=${SEARCH_TERM}&per_page=25&include[]=modules&include[]=status`,
)

describe('SmartSearch', () => {
  const renderSearch = (overrides = {}) => {
    return render(
      <BrowserRouter basename="">
        <Routes>
          <Route path="/" element={<SmartSearch {...props} {...overrides} />} />
        </Routes>
      </BrowserRouter>,
    )
  }

  afterEach(() => {
    fetchMock.restore()
  })

  it('should render progress bar when indexing', async () => {
    fetchMock.get(INDEX_URL, {
      status: 'indexing',
      progress: 75,
    })
    fetchMock.get(SEARCH_URL, {results: []})
    const {getByTestId, queryByText, getByText} = renderSearch()

    expect(queryByText('You may also be interested in')).toBeNull()
    expect(queryByText('No results')).toBeNull()
    await waitFor(() => {
      expect(getByTestId('indexing_progress')).toBeInTheDocument()
      expect(getByText(/wait a moment while we get IgniteAI Search ready/)).toBeInTheDocument()
    })
  })

  it('should render nothing when no search has been made', async () => {
    fetchMock.get(INDEX_URL, {
      status: 'complete',
      progress: 100,
    })
    fetchMock.get(SEARCH_URL, {results: []})
    const {getByTestId, queryByTestId, queryByText} = renderSearch()

    expect(getByTestId('search-input')).toBeInTheDocument()

    expect(queryByText('You may also be interested in')).toBeNull()
    expect(queryByText('No results')).toBeNull()
    expect(queryByTestId('indexing_progress')).toBeNull()
    expect(queryByText(/wait a moment while we get IgniteAI Search ready/)).toBeNull()
  })

  describe('after a successful search', () => {
    beforeEach(() => {
      fetchMock.get(INDEX_URL, {
        status: 'complete',
        progress: 100,
      })
      fetchMock.get(SEARCH_URL, {
        results: results,
      })
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('renders results', async () => {
      const user = userEvent.setup()
      const {getByTestId, getByText} = renderSearch()

      const searchInput = getByTestId('search-input')
      await user.click(searchInput)
      fireEvent.change(searchInput, {target: {value: SEARCH_TERM}})
      user.click(getByTestId('search-button'))

      await waitFor(() => {
        expect(getByText('You may also be interested in')).toBeInTheDocument()
        expect(getByText('1 result')).toBeInTheDocument()
        expect(getByText(results[0].title)).toBeInTheDocument()
        expect(getByText(results[1].title)).toBeInTheDocument()
      })
    })

    it('renders modules for each result', async () => {
      const user = userEvent.setup()
      const {getByTestId, getAllByTestId} = renderSearch()

      const searchInput = getByTestId('search-input')
      await user.click(searchInput)
      fireEvent.change(searchInput, {
        target: {value: SEARCH_TERM},
      })
      await user.click(getByTestId('search-button'))

      await waitFor(() => {
        expect(getAllByTestId('search-result')).toHaveLength(2)
      })
      const resultCards = getAllByTestId('search-result')
      const firstCard = resultCards[0]
      const secondCard = resultCards[1]
      expect(within(firstCard).getByText('Module 1')).toBeInTheDocument()
      expect(within(secondCard).queryByText('Module 1')).not.toBeInTheDocument()
      expect(within(secondCard).getByText('Module 2')).toBeInTheDocument()
      expect(within(firstCard).queryByText('Module 2')).not.toBeInTheDocument()
    })

    it('renders pills for each result', async () => {
      const user = userEvent.setup()
      const {getByTestId, getAllByTestId} = renderSearch()

      const searchInput = getByTestId('search-input')
      await user.click(searchInput)
      fireEvent.change(searchInput, {
        target: {value: SEARCH_TERM},
      })
      await user.click(getByTestId('search-button'))

      await waitFor(() => {
        expect(getAllByTestId('search-result')).toHaveLength(2)
      })
      const resultCards = getAllByTestId('search-result')
      const firstCard = resultCards[0]
      const secondCard = resultCards[1]
      expect(
        within(firstCard).queryByTestId(`${results[0].content_id}-${results[0].content_type}-due`),
      ).toBeNull()
      expect(within(firstCard).getByText('Unpublished')).toBeInTheDocument()
      expect(
        within(secondCard).queryByTestId(
          `${results[0].content_id}-${results[1].content_type}-publish`,
        ),
      ).toBeNull()
      expect(
        within(secondCard).getByTestId(`${results[1].content_id}-${results[1].content_type}-due`),
      ).toBeInTheDocument()
    })

    it('applies filters to search results', async () => {
      const FILTER_URL = encodeURI(
        `/api/v1/courses/${props.courseId}/smartsearch?q=${SEARCH_TERM}&per_page=25&filter[]=announcements&filter[]=pages&include[]=modules&include[]=status`,
      )
      const FILTER_URL2 = encodeURI(
        `/api/v1/courses/${props.courseId}/smartsearch?q=${SEARCH_TERM}&per_page=25&filter[]=pages&include[]=modules&include[]=status`,
      )
      fetchMock.get(FILTER_URL, {
        results: [results[0]], // only the first result matches the filters
      })
      fetchMock.get(FILTER_URL2, {
        results: [], // only the first result matches the filters
      })

      const user = userEvent.setup()
      const {getByTestId, getAllByTestId, queryByTestId, queryAllByTestId} = renderSearch()

      const searchInput = getByTestId('search-input')
      await user.click(searchInput)
      fireEvent.change(searchInput, {
        target: {value: SEARCH_TERM},
      })

      // Perform initial search before applying filters
      await user.click(getByTestId('search-button'))
      await waitFor(() => {
        expect(getAllByTestId('search-result')).toHaveLength(2)
      })

      await user.click(getByTestId('filter-button'))
      await user.click(getByTestId('discussion-topics-checkbox'))
      await user.click(getByTestId('assignments-checkbox'))
      await user.click(getByTestId('apply-filters-button'))

      await waitFor(() => {
        expect(getAllByTestId('search-result')).toHaveLength(1)
        expect(getByTestId('filter-pill-announcements')).toBeInTheDocument()
        expect(getByTestId('filter-pill-pages')).toBeInTheDocument()
        expect(queryByTestId('filter-pill-assignments')).toBeNull()
        expect(queryByTestId('filter-pill-discussion-topics')).toBeNull()
      })

      await user.click(getByTestId('filter-pill-announcements'))
      await waitFor(() => {
        expect(queryAllByTestId('search-result')).toHaveLength(0)
        expect(getByTestId('filter-pill-pages')).toBeInTheDocument()
        expect(queryByTestId('filter-pill-announcements')).toBeNull()
      })
    })
  })

  it('renders error message after failing to get results', async () => {
    const user = userEvent.setup()
    fetchMock.get(INDEX_URL, {
      status: 'complete',
      progress: 100,
    })
    fetchMock.get(SEARCH_URL, 404)
    const {getByTestId, getByText} = renderSearch()

    const searchInput = getByTestId('search-input')
    await user.click(searchInput)
    fireEvent.change(searchInput, {
      target: {value: SEARCH_TERM},
    })
    await user.click(getByTestId('search-button'))

    await waitFor(() => {
      expect(getByText(/Failed to execute search/)).toBeInTheDocument()
    })
  })
})
