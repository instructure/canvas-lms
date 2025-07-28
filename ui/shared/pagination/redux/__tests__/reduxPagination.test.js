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

import {
  createPaginatedReducer,
  createPaginationActions,
  selectPaginationState,
  LoadStates,
} from '../actions'

const createMockStore = state => ({
  subs: [],
  subscribe(cb) {
    this.subs.push(cb)
  },
  getState: () => state,
  dispatch: jest.fn(),
  mockStateChange() {
    this.subs.forEach(sub => sub())
  },
})

describe('Redux Pagination', () => {
  describe('createPaginationActions', () => {
    it('creates proper actionTypes', () => {
      const {actionTypes} = createPaginationActions('things')
      expect(actionTypes).toEqual([
        'SELECT_THINGS_PAGE',
        'GET_THINGS_START',
        'GET_THINGS_SUCCESS',
        'GET_THINGS_FAIL',
        'CLEAR_THINGS_PAGE',
      ])
    })

    it('creates get action creator', () => {
      const {actionCreators} = createPaginationActions('things')
      expect(typeof actionCreators.getThings).toBe('function')
    })

    it('creates get action creator from thunk that calls start with current page', done => {
      const mockStore = createMockStore({
        things: {
          currentPage: 3,
          pages: {3: {item: [], loadState: LoadStates.NOT_LOADED}},
        },
      })
      const thunk = () => resolve => resolve({data: []})
      const {actionCreators} = createPaginationActions('things', thunk)
      actionCreators.getThings()(mockStore.dispatch, mockStore.getState)

      setTimeout(() => {
        expect(mockStore.dispatch).toHaveBeenCalledTimes(2)
        expect(mockStore.dispatch).toHaveBeenCalledWith({
          type: 'GET_THINGS_START',
          payload: {page: 3},
        })
        done()
      })
    })

    it('creates get action creator from thunk that calls start with a payload page', done => {
      const mockStore = createMockStore({
        things: {
          currentPage: 1,
          pages: {1: {item: [], loadState: LoadStates.NOT_LOADED}},
        },
      })
      const thunk = () => resolve => resolve({data: []})
      const {actionCreators} = createPaginationActions('things', thunk)
      actionCreators.getThings({page: 5})(mockStore.dispatch, mockStore.getState)

      setTimeout(() => {
        expect(mockStore.dispatch).toHaveBeenCalledTimes(2)
        expect(mockStore.dispatch).toHaveBeenCalledWith({
          type: 'GET_THINGS_START',
          payload: {page: 5},
        })
        done()
      })
    })

    it('creates get action creator from thunk that calls success', done => {
      const mockStore = createMockStore({
        things: {
          currentPage: 1,
          pages: {1: {item: [], loadState: LoadStates.NOT_LOADED}},
        },
      })
      const thunk = () => resolve => resolve({data: ['item1']})
      const {actionCreators} = createPaginationActions('things', thunk)
      actionCreators.getThings({page: 5})(mockStore.dispatch, mockStore.getState)

      setTimeout(() => {
        expect(mockStore.dispatch).toHaveBeenCalledTimes(2)
        expect(mockStore.dispatch).toHaveBeenLastCalledWith({
          type: 'GET_THINGS_SUCCESS',
          payload: {page: 5, data: ['item1']},
        })
        done()
      })
    })

    it('creates get action creator from thunk that calls success with lastPage from response link header', done => {
      const mockStore = createMockStore({
        things: {
          currentPage: 1,
          pages: {1: {item: [], loadState: LoadStates.NOT_LOADED}},
        },
      })
      const thunk = () => resolve =>
        resolve({
          data: ['item1'],
          headers: {
            link: '<http://canvas.example.com/api/v1/someendpoint&page=5&per_page=50>; rel="last"',
          },
        })
      const {actionCreators} = createPaginationActions('things', thunk)
      actionCreators.getThings()(mockStore.dispatch, mockStore.getState)

      setTimeout(() => {
        expect(mockStore.dispatch).toHaveBeenCalledTimes(2)
        expect(mockStore.dispatch).toHaveBeenLastCalledWith({
          type: 'GET_THINGS_SUCCESS',
          payload: {page: 1, data: ['item1'], lastPage: 5},
        })
        done()
      })
    })

    it('creates get action creator from thunk that calls fail', done => {
      const mockStore = createMockStore({
        things: {
          currentPage: 1,
          pages: {1: {item: [], loadState: LoadStates.NOT_LOADED}},
        },
      })
      const thunk = () => (_, reject) => reject({message: 'oops error'})
      const {actionCreators} = createPaginationActions('things', thunk)
      actionCreators.getThings({page: 5})(mockStore.dispatch, mockStore.getState)

      setTimeout(() => {
        expect(mockStore.dispatch).toHaveBeenCalledTimes(2)
        expect(mockStore.dispatch).toHaveBeenLastCalledWith({
          type: 'GET_THINGS_FAIL',
          payload: {page: 5, message: 'oops error'},
        })
        done()
      })
    })

    it('creates get action creator from thunk that does not call thunk if page is already loaded', done => {
      const mockStore = createMockStore({
        things: {
          currentPage: 1,
          pages: {1: {item: [], loadState: LoadStates.LOADED}},
        },
      })
      const thunk = () => resolve => resolve({data: ['item1']})
      const {actionCreators} = createPaginationActions('things', thunk)
      actionCreators.getThings()(mockStore.dispatch, mockStore.getState)

      setTimeout(() => {
        expect(mockStore.dispatch).not.toHaveBeenCalled()
        done()
      })
    })

    it('creates get action creator from thunk that calls thunk if page is loaded and forceGet is true', done => {
      const mockStore = createMockStore({
        things: {
          currentPage: 1,
          pages: {1: {item: [], loadState: LoadStates.LOADED}},
        },
      })
      const thunk = () => resolve => resolve({data: ['item1']})
      const {actionCreators} = createPaginationActions('things', thunk)
      actionCreators.getThings({forceGet: true})(mockStore.dispatch, mockStore.getState)

      setTimeout(() => {
        expect(mockStore.dispatch).toHaveBeenCalledTimes(2)
        expect(mockStore.dispatch).toHaveBeenLastCalledWith({
          type: 'GET_THINGS_SUCCESS',
          payload: {page: 1, data: ['item1']},
        })
        done()
      })
    })

    it('creates get action creator from thunk that selects the page if select is true', done => {
      const mockStore = createMockStore({
        things: {
          currentPage: 1,
          pages: {1: {item: [], loadState: LoadStates.LOADED}},
        },
      })
      const thunk = () => resolve => resolve({data: ['item1']})
      const {actionCreators} = createPaginationActions('things', thunk)
      actionCreators.getThings({select: true, page: 5})(mockStore.dispatch, mockStore.getState)

      setTimeout(() => {
        expect(mockStore.dispatch).toHaveBeenCalledTimes(3)
        expect(mockStore.dispatch).toHaveBeenCalledWith({
          type: 'SELECT_THINGS_PAGE',
          payload: {page: 5},
        })
        done()
      })
    })

    it('can get all pagination results under a single set of dispatches', done => {
      const mockStore = createMockStore({
        things: {
          currentPage: 1,
          pages: {1: {item: [], loadState: LoadStates.NOT_LOADED}},
        },
      })
      const mockResult = {
        data: ['item1'],
        headers: {
          link: '<http://canvas.example.com/api/v1/someendpoint&page=5&per_page=50>; rel="last"',
        },
      }
      const thunk = () => Promise.resolve(mockResult)
      const {actionCreators} = createPaginationActions('things', thunk, {
        totalCount: 250,
        fetchAll: true,
      })
      actionCreators.getThings()(mockStore.dispatch, mockStore.getState)

      setTimeout(() => {
        expect(mockStore.dispatch).toHaveBeenCalledTimes(2)
        expect(mockStore.dispatch).toHaveBeenCalledWith({
          type: 'GET_THINGS_START',
          payload: {page: 1},
        })
        const expectedResults = {
          type: 'GET_THINGS_SUCCESS',
          payload: {
            data: ['item1', 'item1', 'item1', 'item1', 'item1'],
            lastPage: 1,
            page: 1,
          },
        }
        expect(mockStore.dispatch).toHaveBeenLastCalledWith(expectedResults)
        done()
      }, 750)
    })
  })

  describe('createPaginatedReducer', () => {
    it('sets current page on SELECT_PAGE', () => {
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
      const action = {type: 'SELECT_THINGS_PAGE', payload: {page: 5}}
      const newState = reduce(state, action)
      expect(newState.currentPage).toBe(5)
    })

    it('sets last page on GET_SUCCESS', () => {
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
      const action = {type: 'GET_THINGS_SUCCESS', payload: {lastPage: 5, page: 1, data: ['item1']}}
      const newState = reduce(state, action)
      expect(newState.lastPage).toBe(5)
    })

    it('sets items for page on GET_SUCCESS', () => {
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
      const action = {type: 'GET_THINGS_SUCCESS', payload: {page: 1, data: ['item1']}}
      const newState = reduce(state, action)
      expect(newState.pages[1].items).toEqual(['item1'])
    })

    it('resets items for page on CLEAR_PAGE', () => {
      const state = {
        currentPage: 1,
        pages: {
          1: {
            items: [{id: 1, title: 'some title'}],
            loadState: LoadStates.LOADED,
          },
        },
      }
      const reduce = createPaginatedReducer('things')
      const action = {type: 'CLEAR_THINGS_PAGE', payload: {page: 1}}
      const newState = reduce(state, action)
      expect(newState.pages[1].items).toEqual([])
    })

    it('resets items for multiple pages on CLEAR_PAGE', () => {
      const state = {
        currentPage: 1,
        pages: {
          1: {
            items: [{id: 1, title: 'some title'}],
            loadState: LoadStates.LOADED,
          },
          2: {
            items: [{id: 1, title: 'some title'}],
            loadState: LoadStates.LOADED,
          },
          3: {
            items: [{id: 1, title: 'some title'}],
            loadState: LoadStates.LOADED,
          },
        },
      }
      const reduce = createPaginatedReducer('things')
      const action = {type: 'CLEAR_THINGS_PAGE', payload: {pages: [2, 3]}}
      const newState = reduce(state, action)
      expect(newState.pages[1].items).toEqual([{id: 1, title: 'some title'}])
      expect(newState.pages[2].items).toEqual([])
      expect(newState.pages[3].items).toEqual([])
    })

    it('sets loadState for page to LOADING on GET_START', () => {
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
      const action = {type: 'GET_THINGS_START', payload: {page: 1}}
      const newState = reduce(state, action)
      expect(newState.pages[1].loadState).toBe(LoadStates.LOADING)
    })

    it('sets loadState for page to LOADED on GET_SUCCESS', () => {
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
      const action = {type: 'GET_THINGS_SUCCESS', payload: {page: 1, data: []}}
      const newState = reduce(state, action)
      expect(newState.pages[1].loadState).toBe(LoadStates.LOADED)
    })

    it('sets loadState for page to ERRORED on GET_FAIL', () => {
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
      const action = {type: 'GET_THINGS_FAIL', payload: {page: 1, message: 'oops error'}}
      const newState = reduce(state, action)
      expect(newState.pages[1].loadState).toBe(LoadStates.ERRORED)
    })

    it('sets loadState for page to NOT_LOADED on CLEAR_PAGE', () => {
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
      const action = {type: 'CLEAR_THINGS_PAGE', payload: {page: 1}}
      const newState = reduce(state, action)
      expect(newState.pages[1].loadState).toBe(LoadStates.NOT_LOADED)
    })

    it('sets loadState for multiple pages to NOT_LOADED on CLEAR_PAGE', () => {
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
      const action = {type: 'CLEAR_THINGS_PAGE', payload: {pages: [2, 3]}}
      const newState = reduce(state, action)
      expect(newState.pages[1].loadState).toBe(LoadStates.LOADED)
      expect(newState.pages[2].loadState).toBe(LoadStates.NOT_LOADED)
      expect(newState.pages[3].loadState).toBe(LoadStates.NOT_LOADED)
    })
  })

  describe('selectPaginationState', () => {
    it('derives state for existing page', () => {
      const state = {
        things: {
          currentPage: 1,
          pages: {
            1: {
              items: ['item1'],
              loadState: LoadStates.LOADING,
            },
          },
        },
      }
      const derivedState = selectPaginationState(state, 'things')
      expect(derivedState.things).toEqual(['item1'])
      expect(derivedState.thingsPage).toBe(1)
      expect(derivedState.isLoadingThings).toBe(true)
      expect(derivedState.hasLoadedThings).toBe(false)
    })

    it('derives state for not yet existing page', () => {
      const state = {
        things: {
          currentPage: 5,
          pages: {
            1: {
              items: ['item1'],
              loadState: LoadStates.LOADING,
            },
          },
        },
      }
      const derivedState = selectPaginationState(state, 'things')
      expect(derivedState.things).toEqual([])
      expect(derivedState.thingsPage).toBe(5)
      expect(derivedState.isLoadingThings).toBe(false)
      expect(derivedState.hasLoadedThings).toBe(false)
    })
  })
})
