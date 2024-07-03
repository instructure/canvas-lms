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

import Fixtures from '@canvas/grading/Fixtures'
import parseLinkHeader from 'link-header-parsing/parseLinkHeader'
import reducer from '../SearchFormReducer'
import {
  CLEAR_RECORDS,
  FETCH_RECORDS_START,
  FETCH_RECORDS_SUCCESS,
  FETCH_RECORDS_FAILURE,
  FETCH_RECORDS_NEXT_PAGE_START,
  FETCH_RECORDS_NEXT_PAGE_SUCCESS,
  FETCH_RECORDS_NEXT_PAGE_FAILURE,
} from '../../actions/SearchFormActions'

const defaultState = () => ({
  records: {
    assignments: {
      fetchStatus: null,
      items: [],
      nextPage: null,
    },
    graders: {
      fetchStatus: null,
      items: [],
      nextPage: null,
    },
    students: {
      fetchStatus: null,
      items: [],
      nextPage: null,
    },
  },
})

describe('SearchFormReducer', () => {
  test('returns the current state by default', () => {
    const currState = defaultState()
    expect(reducer(currState, {})).toEqual(currState)
  })

  test('handles FETCH_RECORDS_START for given record type', () => {
    const defaults = defaultState()
    const initialState = {
      ...defaults,
      records: {
        ...defaults.records,
        assignments: {
          ...defaults.records.assignments,
          fetchStatus: null,
        },
      },
    }
    const newState = {
      ...initialState,
      records: {
        ...initialState.records,
        assignments: {
          ...initialState.records.assignments,
          fetchStatus: 'started',
        },
      },
    }
    const action = {
      type: FETCH_RECORDS_START,
      payload: {
        recordType: 'assignments',
      },
    }
    expect(reducer(initialState, action)).toEqual(newState)
  })

  test('handles FETCH_RECORDS_SUCCESS on success for given record type', () => {
    const payload = {
      recordType: 'graders',
      data: Fixtures.userArray(),
      link: '<http://example.com/3?&page=first>; rel="current",<http://example.com/3?&page=bookmark:asdf>; rel="next"',
    }
    const initialState = defaultState()
    const newState = {
      ...initialState,
      records: {
        ...initialState.records,
        graders: {
          fetchStatus: 'success',
          items: payload.data,
          nextPage: parseLinkHeader(payload.link).next,
        },
      },
    }
    const action = {
      type: FETCH_RECORDS_SUCCESS,
      payload,
    }
    expect(reducer(initialState, action)).toEqual(newState)
  })

  test('handles FETCH_RECORDS_FAILURE on failure for given record type', () => {
    const defaults = defaultState()
    const initialState = {
      ...defaults,
      records: {
        ...defaults.records,
        students: {
          fetchStatus: 'started',
          items: Fixtures.userArray(),
          nextPage: null,
        },
      },
    }
    const newState = {
      ...initialState,
      records: {
        ...initialState.records,
        students: {
          fetchStatus: 'failure',
          items: [],
          nextPage: null,
        },
      },
    }
    const action = {
      type: FETCH_RECORDS_FAILURE,
      payload: {recordType: 'students'},
    }
    expect(reducer(initialState, action)).toEqual(newState)
  })

  test('handles FETCH_RECORDS_NEXT_PAGE_START on start for given record type', () => {
    const defaults = defaultState()
    const initialState = {
      ...defaults,
      records: {
        ...defaults.records,
        students: {
          fetchStatus: null,
          items: Fixtures.userArray(),
          nextPage: 'https://example.com',
        },
      },
    }
    const newState = {
      ...initialState,
      records: {
        ...initialState.records,
        students: {
          ...initialState.records.students,
          fetchStatus: 'started',
          nextPage: null,
        },
      },
    }
    const action = {
      type: FETCH_RECORDS_NEXT_PAGE_START,
      payload: {recordType: 'students'},
    }
    expect(reducer(initialState, action)).toEqual(newState)
  })

  test('handles FETCH_RECORDS_NEXT_PAGE_SUCCESS for given record type', () => {
    const defaults = defaultState()
    const payload = {
      recordType: 'graders',
      data: Fixtures.userArray(),
      link: '<http://example.com/3?&page=first>; rel="current",<http://example.com/3?&page=bookmark:asdf>; rel="next"',
    }
    const initialState = {
      ...defaults,
      records: {
        ...defaults.records,
        graders: {
          fetchStatus: 'started',
          items: Fixtures.userArray(),
          nextPage: null,
        },
      },
    }
    const newState = {
      ...initialState,
      records: {
        ...initialState.records,
        graders: {
          ...initialState.records.graders,
          fetchStatus: 'success',
          items: initialState.records.graders.items.concat(payload.data),
          nextPage: parseLinkHeader(payload.link).next,
        },
      },
    }
    const action = {
      type: FETCH_RECORDS_NEXT_PAGE_SUCCESS,
      payload,
    }
    expect(reducer(initialState, action)).toEqual(newState)
  })

  test('handles FETCH_RECORDS_NEXT_PAGE_FAILURE for given record type', () => {
    const defaults = defaultState()
    const initialState = {
      ...defaults,
      records: {
        ...defaults.records,
        students: {
          fetchStatus: 'started',
          items: Fixtures.userArray(),
          nextPage: 'https://example.com',
        },
      },
    }
    const newState = {
      ...initialState,
      records: {
        ...initialState.records,
        students: {
          ...initialState.records.students,
          fetchStatus: 'failure',
          nextPage: null,
        },
      },
    }
    const action = {
      type: FETCH_RECORDS_NEXT_PAGE_FAILURE,
      payload: {recordType: 'students'},
    }
    expect(reducer(initialState, action)).toEqual(newState)
  })

  test('handles CLEAR_RECORDS for given record type', () => {
    const defaults = defaultState()
    const initialState = {
      ...defaults,
      records: {
        ...defaults.records,
        students: {
          fetchStatus: 'success',
          items: Fixtures.userArray(),
          nextPage: 'https://example.com',
        },
      },
    }
    const newState = {
      ...initialState,
      records: {
        ...initialState.records,
        students: {
          fetchStatus: null,
          items: [],
          nextPage: null,
        },
      },
    }
    const action = {
      type: CLEAR_RECORDS,
      payload: {recordType: 'students'},
    }
    expect(reducer(initialState, action)).toEqual(newState)
  })
})
