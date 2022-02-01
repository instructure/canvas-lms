/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import store from '../index'
import fetchMock from 'fetch-mock'
import type {GradebookFilterApiResponse} from '../../gradebook.d'

const originalState = store.getState()

const mockResponse: GradebookFilterApiResponse[] = [
  {
    gradebook_filter: {
      id: '321',
      course_id: '1',
      user_id: '1',
      name: 'filter name',
      payload: {
        conditions: [],
        is_applied: true
      },
      created_at: '2020-01-01T00:00:00Z',
      updated_at: '2020-01-01T00:00:00Z'
    }
  }
]

describe('filterState', () => {
  const courseId = store.getState().courseId

  afterEach(() => {
    store.setState(originalState, true)
    fetchMock.restore()
  })

  it('fetches filters', async () => {
    const url = `/api/v1/courses/${courseId}/gradebook_filters`
    fetchMock.get(url, mockResponse)
    await store.getState().fetchFilters()
    expect(fetchMock.called(url, 'GET')).toBe(true)
    expect(store.getState().filters).toMatchObject([
      {
        id: '321',
        name: 'filter name',
        conditions: [],
        is_applied: true,
        created_at: '2020-01-01T00:00:00Z'
      }
    ])
  })

  it('saves staged filter', async () => {
    store.setState({
      stagedFilter: {
        name: 'filter name',
        conditions: [
          {
            id: '123',
            type: 'student_group',
            value: '1',
            created_at: '2022-01-01T00:00:00Z'
          }
        ],
        created_at: '2022-01-01T00:00:00Z',
        is_applied: true
      }
    })
    const url = `/api/v1/courses/${courseId}/gradebook_filters`
    fetchMock.post(url, mockResponse[0])
    await store.getState().saveStagedFilter()
    expect(fetchMock.called(url, 'POST')).toBe(true)
    expect(store.getState().stagedFilter).toBeNull()
    expect(store.getState().filters).toMatchObject([
      {
        id: '321',
        name: 'filter name',
        conditions: [],
        is_applied: true,
        created_at: '2020-01-01T00:00:00Z'
      }
    ])
  })

  it('updates filter', async () => {
    store.setState({
      filters: [
        {
          id: '321',
          name: 'filter name',
          conditions: [],
          is_applied: true,
          created_at: '2020-01-01T00:00:00Z'
        }
      ]
    })
    const url = `/api/v1/courses/${courseId}/gradebook_filters/321`
    fetchMock.put(url, {
      gradebook_filter: {
        ...mockResponse[0],
        name: 'filter name (renamed)'
      }
    })
    await store.getState().updateFilter({
      id: '321',
      name: 'filter name (renamed)',
      conditions: [],
      is_applied: true,
      created_at: '2020-01-01T00:00:00Z'
    })
    expect(fetchMock.called(url, 'PUT')).toBe(true)
    expect(store.getState().filters).toMatchObject([
      {
        id: '321',
        name: 'filter name (renamed)',
        conditions: [],
        is_applied: true,
        created_at: '2020-01-01T00:00:00Z'
      }
    ])
  })

  it('deletes filter', async () => {
    store.setState({
      filters: [
        {
          id: '321',
          name: 'filter name',
          conditions: [],
          is_applied: true,
          created_at: '2020-01-01T00:00:00Z'
        }
      ]
    })
    const url = `/api/v1/courses/${courseId}/gradebook_filters/321`
    fetchMock.delete(url, mockResponse[0])
    await store.getState().deleteFilter({
      id: '321',
      name: 'filter name (renamed)',
      conditions: [],
      is_applied: true,
      created_at: '2020-01-01T00:00:00Z'
    })
    expect(fetchMock.called(url, 'DELETE')).toBe(true)
    expect(store.getState().filters).toMatchObject([])
  })
})
