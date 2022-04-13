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
      name: 'filter 1',
      payload: {
        conditions: [],
        is_applied: true
      },
      created_at: '2020-01-01T00:00:00Z',
      updated_at: '2020-01-01T00:00:00Z'
    }
  },
  {
    gradebook_filter: {
      id: '432',
      course_id: '1',
      user_id: '1',
      name: 'filter 2',
      payload: {
        conditions: [],
        is_applied: false
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
    fetchMock.get(url, mockResponse.slice(0, 1))
    await store.getState().fetchFilters()
    expect(fetchMock.called(url, 'GET')).toBe(true)
    expect(store.getState().filters).toMatchObject([
      {
        id: '321',
        name: 'filter 1',
        conditions: [],
        is_applied: true,
        created_at: '2020-01-01T00:00:00Z'
      }
    ])
  })

  it('saves staged filter', async () => {
    store.setState({
      stagedFilter: {
        name: 'filter 1',
        conditions: [
          {
            id: '123',
            type: 'student-group',
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
        name: 'filter 1',
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
          name: 'filter 1',
          conditions: [],
          is_applied: true,
          created_at: '2020-01-01T00:00:00Z'
        }
      ]
    })
    const url = `/api/v1/courses/${courseId}/gradebook_filters/321`
    fetchMock.put(url, {
      gradebook_filter: {
        ...mockResponse[0].gradebook_filter,
        name: 'filter 1 (renamed)'
      }
    })
    await store.getState().updateFilter({
      id: '321',
      name: 'filter 1 (renamed)',
      conditions: [],
      is_applied: true,
      created_at: '2020-01-01T00:00:00Z'
    })
    expect(fetchMock.called(url, 'PUT')).toBe(true)
    expect(store.getState().filters).toMatchObject([
      {
        id: '321',
        name: 'filter 1 (renamed)',
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
          name: 'filter 1',
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
      name: 'filter 1 (renamed)',
      conditions: [],
      is_applied: true,
      created_at: '2020-01-01T00:00:00Z'
    })
    expect(fetchMock.called(url, 'DELETE')).toBe(true)
    expect(store.getState().filters).toMatchObject([])
  })

  it('does not derive staged filter from empty gradebook settings', async () => {
    const url = `/api/v1/courses/${courseId}/gradebook_filters`
    fetchMock.post(url, mockResponse[0])
    const initialRowFilterSettings = {
      section_id: null,
      student_group_id: null
    }
    const initialColumnFilterSettings = {
      assignment_group_id: null,
      context_module_id: null,
      grading_period_id: null
    }
    store.getState().initializeStagedFilter(initialRowFilterSettings, initialColumnFilterSettings)
    expect(store.getState().stagedFilter).toBeNull()
  })

  it('derive staged section filter from gradebook settings', async () => {
    const url = `/api/v1/courses/${courseId}/gradebook_filters`
    fetchMock.post(url, mockResponse[0])
    const initialRowFilterSettings = {
      section_id: '1',
      student_group_id: null
    }
    const initialColumnFilterSettings = {
      assignment_group_id: null,
      context_module_id: null,
      grading_period_id: null
    }
    store.getState().initializeStagedFilter(initialRowFilterSettings, initialColumnFilterSettings)
    expect(store.getState().stagedFilter).not.toBeNull()
    expect(store.getState().stagedFilter).toMatchObject({
      name: '',
      conditions: [
        {
          id: expect.any(String),
          type: 'section',
          value: '1'
        }
      ],
      is_applied: true,
      created_at: expect.any(String)
    })
  })

  it('derive staged student group filter from gradebook settings', async () => {
    const url = `/api/v1/courses/${courseId}/gradebook_filters`
    fetchMock.post(url, mockResponse[0])
    const initialRowFilterSettings = {
      section_id: null,
      student_group_id: '1'
    }
    const initialColumnFilterSettings = {
      assignment_group_id: null,
      context_module_id: null,
      grading_period_id: null
    }
    store.getState().initializeStagedFilter(initialRowFilterSettings, initialColumnFilterSettings)
    expect(store.getState().stagedFilter).not.toBeNull()
    expect(store.getState().stagedFilter).toMatchObject({
      name: '',
      conditions: [
        {
          id: expect.any(String),
          type: 'student-group',
          value: '1'
        }
      ],
      is_applied: true,
      created_at: expect.any(String)
    })
  })

  it('derive staged assignment group filter from gradebook settings', async () => {
    const url = `/api/v1/courses/${courseId}/gradebook_filters`
    fetchMock.post(url, mockResponse[0])
    const initialRowFilterSettings = {
      section_id: null,
      student_group_id: null
    }
    const initialColumnFilterSettings = {
      assignment_group_id: '1',
      context_module_id: null,
      grading_period_id: null
    }
    store.getState().initializeStagedFilter(initialRowFilterSettings, initialColumnFilterSettings)
    expect(store.getState().stagedFilter).not.toBeNull()
    expect(store.getState().stagedFilter).toMatchObject({
      name: '',
      conditions: [
        {
          id: expect.any(String),
          type: 'assignment-group',
          value: '1'
        }
      ],
      is_applied: true,
      created_at: expect.any(String)
    })
  })

  it(`does not derive staged assignment group filter from '0'`, async () => {
    const url = `/api/v1/courses/${courseId}/gradebook_filters`
    fetchMock.post(url, mockResponse[0])
    const initialRowFilterSettings = {
      section_id: null,
      student_group_id: null
    }
    const initialColumnFilterSettings = {
      assignment_group_id: '0',
      context_module_id: null,
      grading_period_id: null
    }
    store.getState().initializeStagedFilter(initialRowFilterSettings, initialColumnFilterSettings)
    expect(store.getState().stagedFilter).toBeNull()
  })

  it('derive staged grading period filter from gradebook settings', async () => {
    const url = `/api/v1/courses/${courseId}/gradebook_filters`
    fetchMock.post(url, mockResponse[0])
    const initialRowFilterSettings = {
      section_id: null,
      student_group_id: null
    }
    const initialColumnFilterSettings = {
      assignment_group_id: null,
      context_module_id: null,
      grading_period_id: '1'
    }
    store.getState().initializeStagedFilter(initialRowFilterSettings, initialColumnFilterSettings)
    expect(store.getState().stagedFilter).not.toBeNull()
    expect(store.getState().stagedFilter).toMatchObject({
      name: '',
      conditions: [
        {
          id: expect.any(String),
          type: 'grading-period',
          value: '1'
        }
      ],
      is_applied: true,
      created_at: expect.any(String)
    })
  })

  it('derive staged module filter from gradebook settings', async () => {
    const url = `/api/v1/courses/${courseId}/gradebook_filters`
    fetchMock.post(url, mockResponse[0])
    const initialRowFilterSettings = {
      section_id: null,
      student_group_id: null
    }
    const initialColumnFilterSettings = {
      assignment_group_id: null,
      context_module_id: '1',
      grading_period_id: null
    }
    store.getState().initializeStagedFilter(initialRowFilterSettings, initialColumnFilterSettings)
    expect(store.getState().stagedFilter).not.toBeNull()
    expect(store.getState().stagedFilter).toMatchObject({
      name: '',
      conditions: [
        {
          id: expect.any(String),
          type: 'module',
          value: '1'
        }
      ],
      is_applied: true,
      created_at: expect.any(String)
    })
  })

  it(`does not derive staged module filter from '0'`, async () => {
    const url = `/api/v1/courses/${courseId}/gradebook_filters`
    fetchMock.post(url, mockResponse[0])
    const initialRowFilterSettings = {
      section_id: null,
      student_group_id: null
    }
    const initialColumnFilterSettings = {
      assignment_group_id: null,
      context_module_id: '0',
      grading_period_id: null
    }
    store.getState().initializeStagedFilter(initialRowFilterSettings, initialColumnFilterSettings)
    expect(store.getState().stagedFilter).toBeNull()
  })

  it('disallows multiple filters from being applied', async () => {
    store.setState({
      filters: [
        {
          id: '321',
          name: 'filter 1',
          conditions: [],
          is_applied: false,
          created_at: '2020-01-01T00:00:00Z'
        },
        {
          id: '432',
          name: 'filter 2',
          conditions: [],
          is_applied: true,
          created_at: '2020-01-02T00:00:00Z'
        }
      ]
    })
    fetchMock
      .putOnce(`/api/v1/courses/${courseId}/gradebook_filters/321`, mockResponse[0])
      .putOnce(`/api/v1/courses/${courseId}/gradebook_filters/432`, mockResponse[1], {
        overwriteRoutes: false
      })
    await store.getState().updateFilter({
      id: '321',
      name: 'filter 1',
      conditions: [],
      is_applied: true,
      created_at: '2020-01-01T00:00:00Z'
    })
    expect(store.getState().filters[0]).toMatchObject({
      id: '321',
      name: 'filter 1',
      conditions: [],
      is_applied: true,
      created_at: '2020-01-01T00:00:00Z'
    })
    expect(store.getState().filters[1]).toMatchObject({
      id: '432',
      name: 'filter 2',
      conditions: [],
      is_applied: false,
      created_at: '2020-01-02T00:00:00Z'
    })
  })
})
