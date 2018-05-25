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

import { createPaginatedReducer, createPaginationActions, selectPaginationState, LoadStates } from 'jsx/shared/reduxPagination'

const createMockStore = state => ({
  subs: [],
  subscribe (cb) { this.subs.push(cb) },
  getState: () => state,
  dispatch: () => {},
  mockStateChange () { this.subs.forEach(sub => sub()) },
})

QUnit.module('Redux Pagination')

QUnit.module('createPaginationActions')

test('creates proper actionTypes', () => {
  const { actionTypes } = createPaginationActions('things')
  deepEqual(actionTypes, ['SELECT_THINGS_PAGE',  'GET_THINGS_START', 'GET_THINGS_SUCCESS', 'GET_THINGS_FAIL', 'CLEAR_THINGS_PAGE'])
})

test('creates get action creator', () => {
  const { actionCreators } = createPaginationActions('things')
  equal(typeof actionCreators.getThings, 'function')
})

test('creates get action creator from thunk that calls start with current page', (assert) => {
  const done = assert.async()
  const mockStore = createMockStore({
    things: {
      currentPage: 3,
      pages: { 3: { item: [], loadState: LoadStates.NOT_LOADED } }
    },
  })
  const dispatchSpy = sinon.spy(mockStore, 'dispatch')
  const thunk = () => (resolve, _reject) => resolve({ data: [] })
  const { actionCreators } = createPaginationActions('things', thunk)
  actionCreators.getThings()(mockStore.dispatch, mockStore.getState)
  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    deepEqual(dispatchSpy.firstCall.args, [{ type: 'GET_THINGS_START', payload: { page: 3 } }])
    dispatchSpy.restore()
    done()
  })
})

test('creates get action creator from thunk that calls start with a payload page', (assert) => {
  const done = assert.async()
  const mockStore = createMockStore({
    things: {
      currentPage: 1,
      pages: { 1: { item: [], loadState: LoadStates.NOT_LOADED } }
    },
  })
  const dispatchSpy = sinon.spy(mockStore, 'dispatch')
  const thunk = () => (resolve, _reject) => resolve({ data: [] })
  const { actionCreators } = createPaginationActions('things', thunk)
  actionCreators.getThings({ page: 5 })(mockStore.dispatch, mockStore.getState)
  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    deepEqual(dispatchSpy.firstCall.args, [{ type: 'GET_THINGS_START', payload: { page: 5 } }])
    dispatchSpy.restore()
    done()
  })
})

test('creates get action creator from thunk that calls success', (assert) => {
  const done = assert.async()
  const mockStore = createMockStore({
    things: {
      currentPage: 1,
      pages: { 1: { item: [], loadState: LoadStates.NOT_LOADED } }
    },
  })
  const dispatchSpy = sinon.spy(mockStore, 'dispatch')
  const thunk = () => (resolve, _reject) => resolve({ data: ['item1'] })
  const { actionCreators } = createPaginationActions('things', thunk)
  actionCreators.getThings({ page: 5 })(mockStore.dispatch, mockStore.getState)
  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    deepEqual(dispatchSpy.secondCall.args, [{ type: 'GET_THINGS_SUCCESS', payload: { page: 5, data: ['item1'] } }])
    dispatchSpy.restore()
    done()
  })
})

test('creates get action creator from thunk that calls success with lastPage is provided in response link header', (assert) => {
  const done = assert.async()
  const mockStore = createMockStore({
    things: {
      currentPage: 1,
      pages: { 1: { item: [], loadState: LoadStates.NOT_LOADED } }
    },
  })
  const dispatchSpy = sinon.spy(mockStore, 'dispatch')
  const thunk = () => (resolve, _reject) => resolve({ data: ['item1'], headers: { link: '<http://canvas.example.com/api/v1/someendpoint&page=5&per_page=50>; rel="last"' } })
  const { actionCreators } = createPaginationActions('things', thunk)
  actionCreators.getThings()(mockStore.dispatch, mockStore.getState)
  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    deepEqual(dispatchSpy.secondCall.args, [{ type: 'GET_THINGS_SUCCESS', payload: { page: 1, data: ['item1'], lastPage: 5 } }])
    dispatchSpy.restore()
    done()
  })
})

test('creates get action creator from thunk that calls fail', (assert) => {
  const done = assert.async()
  const mockStore = createMockStore({
    things: {
      currentPage: 1,
      pages: { 1: { item: [], loadState: LoadStates.NOT_LOADED } }
    },
  })
  const dispatchSpy = sinon.spy(mockStore, 'dispatch')
  const thunk = () => (resolve, reject) => reject({ message: 'oops error' })
  const { actionCreators } = createPaginationActions('things', thunk)
  actionCreators.getThings({ page: 5 })(mockStore.dispatch, mockStore.getState)
  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    deepEqual(dispatchSpy.secondCall.args, [{ type: 'GET_THINGS_FAIL', payload: { page: 5, message: 'oops error' } }])
    dispatchSpy.restore()
    done()
  })
})

test('creates get action creator from thunk that does not call thunk if page is already loaded', (assert) => {
  const done = assert.async()
  const mockStore = createMockStore({
    things: {
      currentPage: 1,
      pages: { 1: { item: [], loadState: LoadStates.LOADED } }
    },
  })
  const dispatchSpy = sinon.spy(mockStore, 'dispatch')
  const thunk = () => (resolve, _reject) => resolve({ data: ['item1'] })
  const { actionCreators } = createPaginationActions('things', thunk)
  actionCreators.getThings()(mockStore.dispatch, mockStore.getState)
  setTimeout(() => {
    equal(dispatchSpy.callCount, 0)
    dispatchSpy.restore()
    done()
  })
})

test('creates get action creator from thunk that calls thunk if page is already loaded and forgetGet is true', (assert) => {
  const done = assert.async()
  const mockStore = createMockStore({
    things: {
      currentPage: 1,
      pages: { 1: { item: [], loadState: LoadStates.LOADED } }
    },
  })
  const dispatchSpy = sinon.spy(mockStore, 'dispatch')
  const thunk = () => (resolve, _reject) => resolve({ data: ['item1'] })
  const { actionCreators } = createPaginationActions('things', thunk)
  actionCreators.getThings({ forceGet: true })(mockStore.dispatch, mockStore.getState)
  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    deepEqual(dispatchSpy.secondCall.args, [{ type: 'GET_THINGS_SUCCESS', payload: { page: 1, data: ['item1'] } }])
    dispatchSpy.restore()
    done()
  })
})

test('creates get action creator from thunk that selects the page if select is true', (assert) => {
  const done = assert.async()
  const mockStore = createMockStore({
    things: {
      currentPage: 1,
      pages: { 1: { item: [], loadState: LoadStates.LOADED } }
    },
  })
  const dispatchSpy = sinon.spy(mockStore, 'dispatch')
  const thunk = () => (resolve, _reject) => resolve({ data: ['item1'] })
  const { actionCreators } = createPaginationActions('things', thunk)
  actionCreators.getThings({ select: true, page: 5 })(mockStore.dispatch, mockStore.getState)
  setTimeout(() => {
    equal(dispatchSpy.callCount, 3)
    deepEqual(dispatchSpy.firstCall.args, [{ type: 'SELECT_THINGS_PAGE', payload: { page: 5 } }])
    dispatchSpy.restore()
    done()
  })
})

test('can get all pagination results under a single set of dispatches', (assert) => {
  const done = assert.async()
  const mockStore = createMockStore({
    things: {
      currentPage: 1,
      pages: { 1: { item: [], loadState: LoadStates.NOT_LOADED } }
    },
  })
  const dispatchSpy = sinon.spy(mockStore, 'dispatch')

  const mockResult = {
    data: ['item1'],
    headers: {
      link: '<http://canvas.example.com/api/v1/someendpoint&page=5&per_page=50>; rel="last"'
    }
  }
  const thunk = () => new Promise((resolve, _reject) => resolve(mockResult))
  const { actionCreators } = createPaginationActions('things', thunk, {totalCount: 250, fetchAll: true })
  actionCreators.getThings()(mockStore.dispatch, mockStore.getState)
  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    deepEqual(dispatchSpy.firstCall.args, [{ type: 'GET_THINGS_START', payload: { page: 1 } }])

    // Should have item1 5 times, as the link header indicated there were 5
    // pages that needed to be gathered
    const expectedResults = {
      type: 'GET_THINGS_SUCCESS',
      payload: {
        data: [ "item1", "item1", "item1", "item1", "item1" ],
        lastPage: 1,
        page: 1
      }
    }
    deepEqual(dispatchSpy.secondCall.args, [expectedResults])
    dispatchSpy.restore()
    done()
  }, 750)
})

QUnit.module('createPaginatedReducer')

test('sets current page on SELECT_PAGE', () => {
  const state = {
    currentPage: 1,
    pages: {
      1: {
        items: [],
        loadState: LoadStates.NOT_LOADED,
      },
    },
  }
  const reduce = createPaginatedReducer('things')
  const action = { type: 'SELECT_THINGS_PAGE', payload: { page: 5 } }
  const newState = reduce(state, action)
  equal(newState.currentPage, 5)
})

test('sets last page on GET_SUCCESS', () => {
  const state = {
    currentPage: 1,
    pages: {
      1: {
        items: [],
        loadState: LoadStates.NOT_LOADED,
      },
    },
  }
  const reduce = createPaginatedReducer('things')
  const action = { type: 'GET_THINGS_SUCCESS', payload: { lastPage: 5, page: 1, data: ['item1'] } }
  const newState = reduce(state, action)
  equal(newState.lastPage, 5)
})

test('sets items for page on GET_SUCCESS', () => {
  const state = {
    currentPage: 1,
    pages: {
      1: {
        items: [],
        loadState: LoadStates.NOT_LOADED,
      },
    },
  }
  const reduce = createPaginatedReducer('things')
  const action = { type: 'GET_THINGS_SUCCESS', payload: { page: 1, data: ['item1'] } }
  const newState = reduce(state, action)
  deepEqual(newState.pages[1].items, ['item1'])
})

test('resets items for page on CLEAR_PAGE', () => {
  const state = {
    currentPage: 1,
    pages: {
      1: {
        items: [{ id: 1, title: 'some title' }],
        loadState: LoadStates.LOADED,
      },
    },
  }
  const reduce = createPaginatedReducer('things')
  const action = { type: 'CLEAR_THINGS_PAGE', payload: { page: 1 } }
  const newState = reduce(state, action)
  deepEqual(newState.pages[1].items, [])
})

test('resets items for multiple pages on CLEAR_PAGE', () => {
  const state = {
    currentPage: 1,
    pages: {
      1: {
        items: [{ id: 1, title: 'some title' }],
        loadState: LoadStates.LOADED,
      },
      2: {
        items: [{ id: 1, title: 'some title' }],
        loadState: LoadStates.LOADED,
      },
      3: {
        items: [{ id: 1, title: 'some title' }],
        loadState: LoadStates.LOADED,
      },
    },
  }
  const reduce = createPaginatedReducer('things')
  const action = { type: 'CLEAR_THINGS_PAGE', payload: { pages: [2, 3] } }
  const newState = reduce(state, action)
  deepEqual(newState.pages[1].items, [{ id: 1, title: 'some title' }])
  deepEqual(newState.pages[2].items, [])
  deepEqual(newState.pages[3].items, [])
})

test('sets loadState for page to LOADING on GET_START', () => {
  const state = {
    currentPage: 1,
    pages: {
      1: {
        items: [],
        loadState: LoadStates.NOT_LOADED,
      },
    },
  }
  const reduce = createPaginatedReducer('things')
  const action = { type: 'GET_THINGS_START', payload: { page: 1 } }
  const newState = reduce(state, action)
  equal(newState.pages[1].loadState, LoadStates.LOADING)
})

test('sets loadState for page to LOADED on GET_SUCCESS', () => {
  const state = {
    currentPage: 1,
    pages: {
      1: {
        items: [],
        loadState: LoadStates.LOADING,
      },
    },
  }
  const reduce = createPaginatedReducer('things')
  const action = { type: 'GET_THINGS_SUCCESS', payload: { page: 1, data: [] } }
  const newState = reduce(state, action)
  equal(newState.pages[1].loadState, LoadStates.LOADED)
})

test('sets loadState for page to ERRORED on GET_FAIL', () => {
  const state = {
    currentPage: 1,
    pages: {
      1: {
        items: [],
        loadState: LoadStates.LOADING,
      },
    },
  }
  const reduce = createPaginatedReducer('things')
  const action = { type: 'GET_THINGS_FAIL', payload: { page: 1, message: 'oops error' } }
  const newState = reduce(state, action)
  equal(newState.pages[1].loadState, LoadStates.ERRORED)
})

test('sets loadState for page to NOT_LOADED on CLEAR_PAGE', () => {
  const state = {
    currentPage: 1,
    pages: {
      1: {
        items: [],
        loadState: LoadStates.LOADED,
      },
    },
  }
  const reduce = createPaginatedReducer('things')
  const action = { type: 'CLEAR_THINGS_PAGE', payload: { page: 1 } }
  const newState = reduce(state, action)
  equal(newState.pages[1].loadState, LoadStates.NOT_LOADED)
})

test('sets loadState for multiple pages to NOT_LOADED on CLEAR_PAGE', () => {
  const state = {
    currentPage: 1,
    pages: {
      1: {
        items: [],
        loadState: LoadStates.LOADED,
      },
      2: {
        items: [],
        loadState: LoadStates.LOADED,
      },
      3: {
        items: [],
        loadState: LoadStates.LOADED,
      },
    },
  }
  const reduce = createPaginatedReducer('things')
  const action = { type: 'CLEAR_THINGS_PAGE', payload: { pages: [2, 3] } }
  const newState = reduce(state, action)
  equal(newState.pages[1].loadState, LoadStates.LOADED)
  equal(newState.pages[2].loadState, LoadStates.NOT_LOADED)
  equal(newState.pages[3].loadState, LoadStates.NOT_LOADED)
})

QUnit.module('selectPaginationState')

test('derives state for existing page', () => {
  const state = {
    things: {
      currentPage: 1,
      pages: {
        1: {
          items: ['item1'],
          loadState: LoadStates.LOADING,
        },
      },
    }
  }
  const derivedState = selectPaginationState(state, 'things')
  deepEqual(derivedState.things, ['item1'])
  deepEqual(derivedState.thingsPage, 1)
  deepEqual(derivedState.isLoadingThings, true)
  deepEqual(derivedState.hasLoadedThings, false)
})

test('derives state for not yet existing page', () => {
  const state = {
    things: {
      currentPage: 5,
      pages: {
        1: {
          items: ['item1'],
          loadState: LoadStates.LOADING,
        },
      },
    }
  }
  const derivedState = selectPaginationState(state, 'things')
  deepEqual(derivedState.things, [])
  deepEqual(derivedState.thingsPage, 5)
  deepEqual(derivedState.isLoadingThings, false)
  deepEqual(derivedState.hasLoadedThings, false)
})
