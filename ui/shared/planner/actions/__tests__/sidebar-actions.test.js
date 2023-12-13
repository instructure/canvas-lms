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

/* eslint-disable promise/catch-or-return */
/* eslint-disable promise/no-callback-in-promise */

import moxios from 'moxios'
import moment from 'moment-timezone'
import MockDate from 'mockdate'
import {moxiosRespond} from '@canvas/jest-moxios-utils'
import {initialize} from '../../utilities/alertUtils'

import * as Actions from '../sidebar-actions'

jest.mock('../../utilities/apiUtils', () => ({
  ...jest.requireActual('../../utilities/apiUtils'),
  transformApiToInternalItem: jest.fn(item => `transformed-${item.uniqueId}`),
}))

beforeAll(() => {
  const alertSpy = jest.fn()
  initialize({visualErrorCallback: alertSpy})
})

beforeEach(() => {
  moxios.install()
  MockDate.set('2018-01-01', 'UTC')
})

afterEach(() => {
  moxios.uninstall()
  MockDate.reset()
  Actions.sidebarLoadNextItems.reset()
  Actions.maybeUpdateTodoSidebar.reset()
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
      today.clone().add(-2, 'weeks').toISOString()
    )
  })

  it('dispatches SIDEBAR_ITEMS_LOADED with the proper payload on success', done => {
    expect.hasAssertions()
    const thunk = Actions.sidebarLoadInitialItems(moment().startOf('day'))
    const fakeDispatch = jest.fn(() => Promise.resolve({data: []}))
    thunk(fakeDispatch, mockGetState())
    moxios.wait(() => {
      const request = moxios.requests.mostRecent()
      request
        .respondWith({
          status: 200,
          headers: {
            link: '</>; rel="current"',
          },
          response: [{uniqueId: 1}, {uniqueId: 2}],
        })
        .then(() => {
          const expected = {
            type: 'SIDEBAR_ITEMS_LOADED',
            payload: {items: ['transformed-1', 'transformed-2'], nextUrl: null},
          }
          expect(fakeDispatch).toHaveBeenCalledWith(expected)
          done()
        })
    })
  })

  it('dispatches SIDEBAR_ITEMS_LOADED with the proper url on success', done => {
    expect.hasAssertions()
    const thunk = Actions.sidebarLoadInitialItems(moment().startOf('day'))
    const fakeDispatch = jest.fn(() => Promise.resolve({data: []}))
    thunk(fakeDispatch, mockGetState())
    moxios.wait(() => {
      const request = moxios.requests.mostRecent()
      request
        .respondWith({
          status: 200,
          headers: {
            link: '</>; rel="next"',
          },
          response: [{uniqueId: 1}, {uniqueId: 2}],
        })
        .then(() => {
          const expected = {
            type: 'SIDEBAR_ITEMS_LOADED',
            payload: {items: ['transformed-1', 'transformed-2'], nextUrl: '/'},
          }
          expect(fakeDispatch).toHaveBeenCalledWith(expected)
          done()
        })
    })
  })

  it('dispatches SIDEBAR_ENOUGH_ITEMS_LOADED when initial load gets them all', done => {
    expect.hasAssertions()
    const thunk = Actions.sidebarLoadInitialItems(moment().startOf('day'))
    const fakeDispatch = jest.fn(() => Promise.resolve({data: []}))
    thunk(fakeDispatch, mockGetState({nextUrl: null}))
    moxios.wait(() => {
      const request = moxios.requests.mostRecent()
      request
        .respondWith({
          status: 200,
          headers: {}, // no link header means we got them all
          response: [{uniqueId: 1}, {uniqueId: 2}],
        })
        .then(() => {
          const expected = {
            type: 'SIDEBAR_ITEMS_LOADED',
            payload: {items: ['transformed-1', 'transformed-2'], nextUrl: null},
          }
          expect(fakeDispatch).toHaveBeenCalledWith(expected)
          expect(fakeDispatch).toHaveBeenCalledWith({type: 'SIDEBAR_ENOUGH_ITEMS_LOADED'})
          done()
        })
    })
  })

  it('continues to load if there are less than 14 incomplete items loaded', done => {
    expect.hasAssertions()
    const thunk = Actions.sidebarLoadInitialItems(moment().startOf('day'))
    const fakeDispatch = jest.fn(() => Promise.resolve({data: []}))
    const fetchPromise = thunk(
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
      })
    )
    moxiosRespond([], fetchPromise, {headers: {link: '</>; rel="next"'}}).then(_response => {
      expect(fakeDispatch).toHaveBeenCalledWith({type: 'SIDEBAR_ENOUGH_ITEMS_LOADED'})
      expect(fakeDispatch).toHaveBeenCalledTimes(6)
      const secondCallThunk = fakeDispatch.mock.calls[5][0]
      expect(secondCallThunk).toBe(Actions.sidebarLoadNextItems)
      fakeDispatch.mockReset()
      const secondFetchPromise = secondCallThunk(
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
        })
      )
      return moxiosRespond([], secondFetchPromise).then(__response => {
        // make sure we got here because another load happened.
        // test times out if we don't get here.
        done()
      })
    })
  })

  it('stops loading when it gets 14 incomplete items', () => {
    expect.hasAssertions()
    const thunk = Actions.sidebarLoadInitialItems(moment().startOf('day'))
    const fakeDispatch = jest.fn(() => Promise.resolve({data: []}))
    const fetchPromise = thunk(
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
      })
    )
    return moxiosRespond([], fetchPromise, {headers: {link: '</>; rel="next"'}}).then(_response => {
      expect(fakeDispatch).not.toHaveBeenCalledWith(Actions.sidebarLoadNextItems)
    })
  })

  it('finishes loading even when there are less then 5 incomplete items', () => {
    expect.hasAssertions()
    const thunk = Actions.sidebarLoadInitialItems(moment().startOf('day'))
    const fakeDispatch = jest.fn(() => Promise.resolve({data: []}))
    const fetchPromise = thunk(
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
      })
    )
    return moxiosRespond([], fetchPromise).then(_response => {
      expect(fakeDispatch).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'SIDEBAR_ENOUGH_ITEMS_LOADED',
        })
      )
    })
  })

  it('dispatches SIDEBAR_ITEMS_LOADING_FAILED on failure', done => {
    expect.hasAssertions()
    const thunk = Actions.sidebarLoadInitialItems(moment().startOf('day'))
    const fakeDispatch = jest.fn(() => Promise.resolve({data: []}))
    thunk(fakeDispatch, mockGetState())
    moxios.wait(() => {
      const request = moxios.requests.mostRecent()
      request
        .respondWith({
          status: 500,
          response: {error: 'Something terrible'},
        })
        .then(() => {
          expect(fakeDispatch).toHaveBeenCalledWith(
            expect.objectContaining({type: 'SIDEBAR_ITEMS_LOADING_FAILED', error: true})
          )
          done()
        })
    })
  })
})

describe('fetch more items', () => {
  it('resumes loading when there are less than the desired number of incomplete items', () => {
    expect.hasAssertions()
    const mockDispatch = jest.fn()
    const mockGs = mockGetState({nextUrl: '/', items: generateItems(13)})
    const savedItemPromise = new Promise(resolve => resolve({item: {completed: true}}))
    return Actions.maybeUpdateTodoSidebar(savedItemPromise)(mockDispatch, mockGs).then(() => {
      expect(mockDispatch).toHaveBeenCalledWith(Actions.sidebarLoadNextItems)
    })
  })

  it('will not resume loading if desired number of items is loaded', () => {
    expect.hasAssertions()
    const mockDispatch = jest.fn()
    const gs = mockGetState({nextUrl: '/', items: generateItems(14)})
    const savedItemPromise = new Promise(resolve => resolve({item: {completed: true}}))
    return Actions.maybeUpdateTodoSidebar(savedItemPromise)(mockDispatch, gs).then(() => {
      expect(mockDispatch).not.toHaveBeenCalledWith(Actions.sidebarLoadNextItems)
    })
  })

  it('will not resume loading if all items are loaded', () => {
    expect.hasAssertions()
    const mockDispatch = jest.fn()
    const gs = mockGetState({nextUrl: null})
    const savedItemPromise = new Promise(resolve => resolve({item: {completed: true}}))
    return Actions.maybeUpdateTodoSidebar(savedItemPromise)(mockDispatch, gs).then(() => {
      expect(mockDispatch).not.toHaveBeenCalledWith(Actions.sidebarLoadNextItems)
    })
  })
})
