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
import EnhancedSmartSearch from '../EnhancedSmartSearch'
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
    relevance: 0.99,
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
    relevance: 0.2,
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

describe('EnhancedSmartSearch', () => {
  const renderSearch = (overrides = {}) => {
    return render(
      <BrowserRouter basename="">
        <Routes>
          <Route path="/" element={<EnhancedSmartSearch {...props} {...overrides} />} />
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

    expect(queryByText('Similar Results')).toBeNull()
    expect(queryByText('Best Matches')).toBeNull()
    await waitFor(() => {
      expect(getByTestId('indexing_progress')).toBeInTheDocument()
      expect(getByText(/wait a moment while we get Smart Search ready/)).toBeInTheDocument()
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

    expect(queryByText('Similar Results')).toBeNull()
    expect(queryByText('Best Matches')).toBeNull()
    expect(queryByTestId('indexing_progress')).toBeNull()
    expect(queryByText(/wait a moment while we get Smart Search ready/)).toBeNull()
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

    it('should render results', async () => {
      const user = userEvent.setup()
      const {getByTestId, getByText} = renderSearch()

      const searchInput = getByTestId('search-input')
      await user.click(searchInput)
      fireEvent.change(searchInput, {target: {value: SEARCH_TERM}})
      user.click(getByTestId('search-button'))

      await waitFor(() => {
        expect(getByText('Similar Results')).toBeInTheDocument()
        expect(getByText('Best Matches')).toBeInTheDocument()
        expect(getByText(results[0].title)).toBeInTheDocument()
        expect(getByText(results[1].title)).toBeInTheDocument()
      })
    })

    it('should render modules for each result', async () => {
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

    it('should render pills for each result', async () => {
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
  })

  it('should render error message after failing to get results', async () => {
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
