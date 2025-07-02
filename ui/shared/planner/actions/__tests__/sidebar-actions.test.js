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

import {http, HttpResponse} from 'msw'
import {mswServer} from '../../../msw/mswServer'
import moment from 'moment-timezone'
import MockDate from 'mockdate'
import {initialize} from '../../utilities/alertUtils'

import * as Actions from '../sidebar-actions'

jest.mock('../../utilities/apiUtils', () => ({
  ...jest.requireActual('../../utilities/apiUtils'),
  transformApiToInternalItem: jest.fn(item => `transformed-${item.uniqueId}`),
}))

const server = mswServer([])

beforeAll(() => {
  const alertSpy = jest.fn()
  initialize({visualErrorCallback: alertSpy})
  server.listen()
})

beforeEach(() => {
  MockDate.set('2018-01-01', 'UTC')
})

afterEach(() => {
  server.resetHandlers()
  MockDate.reset()
  Actions.sidebarLoadNextItems.reset()
  Actions.maybeUpdateTodoSidebar.reset()
})

afterAll(() => {
  server.close()
})

function mockGetState(overrides) {
  const state = {
    sidebar: {
      items: [],
      loading: false,
      nextUrl: null,
      loaded: false,
      ...overrides,
    },
    timeZone: 'UTC',
    courses: [],
    groups: [],
  }
  return () => state
}

function generateItem(opts = {}) {
  return {
    completed: false,
    ...opts,
  }
}

function generateItems(num, opts = {}) {
  return Array(num)
    .fill()
    .map(() => generateItem(opts))
}

describe('load items', () => {
  it('dispatches SIDEBAR_ITEMS_LOADING action initially with target moment range', () => {
    const today = moment.tz().startOf('day')
    const thunk = Actions.sidebarLoadInitialItems(today)
    const fakeDispatch = jest.fn(() => Promise.resolve({data: []}))
    thunk(fakeDispatch, mockGetState())
    const expected = {
      type: 'SIDEBAR_ITEMS_LOADING',
    }
    expect(fakeDispatch).toHaveBeenCalledWith(expect.objectContaining(expected))
    const action = fakeDispatch.mock.calls[0][0]
    expect(action.payload.firstMoment.toISOString()).toBe(
      today.clone().add(-2, 'weeks').toISOString(),
    )
  })

  it('dispatches SIDEBAR_ITEMS_LOADED with the proper payload on success', async () => {
    server.use(
      http.get('*/api/v1/planner/items', () => {
        return new HttpResponse(JSON.stringify([{uniqueId: 1}, {uniqueId: 2}]), {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
            link: '</>; rel="current"',
          },
        })
      }),
    )

    const thunk = Actions.sidebarLoadInitialItems(moment().startOf('day'))
    const fakeDispatch = jest.fn(() => Promise.resolve({data: []}))
    await thunk(fakeDispatch, mockGetState())

    const expected = {
      type: 'SIDEBAR_ITEMS_LOADED',
      payload: {items: ['transformed-1', 'transformed-2'], nextUrl: null},
    }
    expect(fakeDispatch).toHaveBeenCalledWith(expected)
  })

  it('dispatches SIDEBAR_ITEMS_LOADED with the proper url on success', async () => {
    server.use(
      http.get('*/api/v1/planner/items', () => {
        return new HttpResponse(JSON.stringify([{uniqueId: 1}, {uniqueId: 2}]), {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
            link: '</>; rel="next"',
          },
        })
      }),
    )

    const thunk = Actions.sidebarLoadInitialItems(moment().startOf('day'))
    const fakeDispatch = jest.fn(() => Promise.resolve({data: []}))
    await thunk(fakeDispatch, mockGetState())

    const expected = {
      type: 'SIDEBAR_ITEMS_LOADED',
      payload: {items: ['transformed-1', 'transformed-2'], nextUrl: '/'},
    }
    expect(fakeDispatch).toHaveBeenCalledWith(expected)
  })

  it('dispatches SIDEBAR_ENOUGH_ITEMS_LOADED when initial load gets them all', async () => {
    server.use(
      http.get('*/api/v1/planner/items', () => {
        return new HttpResponse(JSON.stringify([{uniqueId: 1}, {uniqueId: 2}]), {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
          },
        })
      }),
    )

    const thunk = Actions.sidebarLoadInitialItems(moment().startOf('day'))
    const fakeDispatch = jest.fn(() => Promise.resolve({data: []}))
    await thunk(fakeDispatch, mockGetState({nextUrl: null}))

    const expected = {
      type: 'SIDEBAR_ITEMS_LOADED',
      payload: {items: ['transformed-1', 'transformed-2'], nextUrl: null},
    }
    expect(fakeDispatch).toHaveBeenCalledWith(expected)
    expect(fakeDispatch).toHaveBeenCalledWith({type: 'SIDEBAR_ENOUGH_ITEMS_LOADED'})
  })

  it('continues to load if there are less than 14 incomplete items loaded', async () => {
    let requestCount = 0
    server.use(
      http.get('*/api/v1/planner/items', () => {
        requestCount++
        return new HttpResponse(JSON.stringify([]), {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
            link: requestCount === 1 ? '</>; rel="next"' : '',
          },
        })
      }),
      http.get('*/', () => {
        return new HttpResponse(JSON.stringify([]), {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
          },
        })
      }),
    )

    const thunk = Actions.sidebarLoadInitialItems(moment().startOf('day'))
    const fakeDispatch = jest.fn(() => Promise.resolve({data: []}))
    await thunk(
      fakeDispatch,
      mockGetState({
        items: [
          {completed: true},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
        ],
      }),
    )

    expect(fakeDispatch).toHaveBeenCalledWith({type: 'SIDEBAR_ENOUGH_ITEMS_LOADED'})
    expect(fakeDispatch).toHaveBeenCalledTimes(6)
    const secondCallThunk = fakeDispatch.mock.calls[5][0]
    expect(secondCallThunk).toBe(Actions.sidebarLoadNextItems)
    fakeDispatch.mockReset()
    await secondCallThunk(
      fakeDispatch,
      mockGetState({
        nextUrl: '/',
        items: [
          {completed: true},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: true},
          {completed: true},
          {completed: true},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: true},
          {completed: true},
        ],
      }),
    )
  })

  it('stops loading when it gets 14 incomplete items', async () => {
    server.use(
      http.get('*/api/v1/planner/items', () => {
        return new HttpResponse(JSON.stringify([]), {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
            link: '</>; rel="next"',
          },
        })
      }),
    )

    const thunk = Actions.sidebarLoadInitialItems(moment().startOf('day'))
    const fakeDispatch = jest.fn(() => Promise.resolve({data: []}))
    await thunk(
      fakeDispatch,
      mockGetState({
        items: [
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
        ],
      }),
    )

    expect(fakeDispatch).not.toHaveBeenCalledWith(Actions.sidebarLoadNextItems)
  })

  it('finishes loading even when there are less then 5 incomplete items', async () => {
    server.use(
      http.get('*/api/v1/planner/items', () => {
        return new HttpResponse(JSON.stringify([]), {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
          },
        })
      }),
    )

    const thunk = Actions.sidebarLoadInitialItems(moment().startOf('day'))
    const fakeDispatch = jest.fn(() => Promise.resolve({data: []}))
    await thunk(
      fakeDispatch,
      mockGetState({
        items: [
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: false},
          {completed: true},
          {completed: true},
        ],
      }),
    )

    expect(fakeDispatch).toHaveBeenCalledWith(
      expect.objectContaining({
        type: 'SIDEBAR_ENOUGH_ITEMS_LOADED',
      }),
    )
  })

  it('dispatches SIDEBAR_ITEMS_LOADING_FAILED on failure', async () => {
    server.use(
      http.get('*/api/v1/planner/items', () => {
        return new HttpResponse(JSON.stringify({error: 'Something terrible'}), {
          status: 500,
          headers: {
            'Content-Type': 'application/json',
          },
        })
      }),
    )

    const thunk = Actions.sidebarLoadInitialItems(moment().startOf('day'))
    const fakeDispatch = jest.fn(() => Promise.resolve({data: []}))
    await thunk(fakeDispatch, mockGetState())

    expect(fakeDispatch).toHaveBeenCalledWith(
      expect.objectContaining({type: 'SIDEBAR_ITEMS_LOADING_FAILED', error: true}),
    )
  })
})

describe('fetch more items', () => {
  it('resumes loading when there are less than the desired number of incomplete items', async () => {
    const mockDispatch = jest.fn()
    const mockGs = mockGetState({nextUrl: '/', items: generateItems(13)})
    const savedItemPromise = new Promise(resolve => resolve({item: {completed: true}}))
    await Actions.maybeUpdateTodoSidebar(savedItemPromise)(mockDispatch, mockGs)
    expect(mockDispatch).toHaveBeenCalledWith(Actions.sidebarLoadNextItems)
  })

  it('will not resume loading if desired number of items is loaded', async () => {
    const mockDispatch = jest.fn()
    const gs = mockGetState({nextUrl: '/', items: generateItems(14)})
    const savedItemPromise = new Promise(resolve => resolve({item: {completed: true}}))
    await Actions.maybeUpdateTodoSidebar(savedItemPromise)(mockDispatch, gs)
    expect(mockDispatch).not.toHaveBeenCalledWith(Actions.sidebarLoadNextItems)
  })

  it('will not resume loading if all items are loaded', async () => {
    const mockDispatch = jest.fn()
    const gs = mockGetState({nextUrl: null})
    const savedItemPromise = new Promise(resolve => resolve({item: {completed: true}}))
    await Actions.maybeUpdateTodoSidebar(savedItemPromise)(mockDispatch, gs)
    expect(mockDispatch).not.toHaveBeenCalledWith(Actions.sidebarLoadNextItems)
  })
})
