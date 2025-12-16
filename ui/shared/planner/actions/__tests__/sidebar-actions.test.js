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
import {setupServer} from 'msw/node'
import moment from 'moment-timezone'
import MockDate from 'mockdate'
import {initialize} from '../../utilities/alertUtils'

import * as Actions from '../sidebar-actions'

jest.mock('../../utilities/apiUtils', () => ({
  ...jest.requireActual('../../utilities/apiUtils'),
  transformApiToInternalItem: jest.fn(item => `transformed-${item.uniqueId}`),
}))

const server = setupServer(
  http.get('*/api/v1/planner/items', () => {
    return new HttpResponse(JSON.stringify([]), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
      },
    })
  }),
)

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

  it('loads items with per_page parameter', async () => {
    let requestUrl = ''
    server.use(
      http.get('*/api/v1/planner/items', req => {
        requestUrl = req.request.url
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
    await thunk(fakeDispatch, mockGetState())
    expect(fakeDispatch).toHaveBeenCalledWith({type: 'SIDEBAR_ENOUGH_ITEMS_LOADED'})
    expect(requestUrl).toContain('per_page=14')
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

  it('uses incomplete_items filter in API requests', async () => {
    let requestUrl = ''
    server.use(
      http.get('*/api/v1/planner/items', req => {
        requestUrl = req.request.url
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
    await thunk(fakeDispatch, mockGetState())
    expect(requestUrl).toContain('filter=incomplete_items')
  })
})
