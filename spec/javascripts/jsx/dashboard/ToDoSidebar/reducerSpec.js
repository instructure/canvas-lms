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

import reducer from 'jsx/dashboard/ToDoSidebar/reducer'

QUnit.module('ToDoSidebar reducer')

const getInitialState = overrides => ({
  items: [],
  loading: false,
  loaded: false,
  nextUrl: null,
  ...overrides
})

test('adds items to the state on ITEMS_LOADED', () => {
  const actual = reducer(getInitialState(), {
    type: 'ITEMS_LOADED',
    payload: {
      items: [{id: 1}, {id: 2}],
      nextUrl: null
    }
  })
  const expected = {
    items: [{id: 1}, {id: 2}],
    loading: false,
    loaded: false,
    nextUrl: null
  }
  deepEqual(actual, expected)
})

test('sets nextUrl to the correct state on ITEMS_LOADED', () => {
  const actual = reducer(getInitialState(), {
    type: 'ITEMS_LOADED',
    payload: {
      items: [{id: 1}, {id: 2}],
      nextUrl: '/'
    }
  })
  const expected = {
    items: [{id: 1}, {id: 2}],
    loading: false,
    loaded: false,
    nextUrl: '/'
  }
  deepEqual(actual, expected)
})

test('sets loading to false on ITEMS_LOADED', () => {
  const initialState = getInitialState({
    loading: true
  })
  const actual = reducer(initialState, {
    type: 'ITEMS_LOADED',
    payload: {
      items: [],
      nextUrl: null
    }
  })
  const expected = {
    items: [],
    loading: false,
    loaded: false,
    nextUrl: null
  }
  deepEqual(actual, expected)
})

test('sets loading to true on ITEMS_LOADING', () => {
  const initialState = getInitialState({
    loading: false
  })
  const actual = reducer(initialState, {
    type: 'ITEMS_LOADING',
    payload: []
  })
  const expected = {
    items: [],
    loading: true,
    loaded: false,
    nextUrl: null
  }
  deepEqual(actual, expected)
})

test('sets loaded to true on ALL_ITEMS_LOADED', () => {
  const initialState = getInitialState({
    loaded: false
  })
  const actual = reducer(initialState, {
    type: 'ALL_ITEMS_LOADED'
  })
  const expected = {
    items: [],
    loading: false,
    loaded: true,
    nextUrl: null
  }
  deepEqual(actual, expected)
})

test('sets loading to false on ITEMS_LOADING_FAILED', () => {
  const initialState = getInitialState({
    loading: true
  })
  const actual = reducer(initialState, {
    type: 'ITEMS_LOADING_FAILED',
    payload: []
  })
  const expected = {
    items: [],
    loading: false,
    loaded: false,
    nextUrl: null
  }
  deepEqual(actual, expected)
})

test('updates planner_override property of a given item on ITEM_SAVED', () => {
  const initialState = getInitialState({
    items: [
      {
        plannable_id: '1',
        plannable_type: 'assignment'
      },
      {
        plannable_id: '1',
        plannable_type: 'planner_note'
      }
    ]
  })

  const actual = reducer(initialState, {
    type: 'ITEM_SAVED',
    payload: {
      plannable_id: '1',
      plannable_type: 'planner_note',
      marked_complete: true
    }
  })

  const expected = {
    items: [
      {
        plannable_id: '1',
        plannable_type: 'assignment'
      },
      {
        plannable_id: '1',
        plannable_type: 'planner_note',
        planner_override: {
          plannable_id: '1',
          plannable_type: 'planner_note',
          marked_complete: true
        }
      }
    ],
    loading: false,
    loaded: false,
    nextUrl: null
  }

  deepEqual(actual, expected)
})
