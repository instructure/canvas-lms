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

import reducer from '../sidebar-reducer';
import {sidebarItemsLoading, savedPlannerItem, deletedPlannerItem} from '../../actions';
import moment from 'moment-timezone';

const getInitialState = (overrides = {}) => ({
  items: [],
  loading: false,
  loaded: true,
  nextUrl: null,
  range: {
    firstMoment: moment.tz('2018-01-01', 'UTC'),
    lastMoment: moment.tz('2018-01-03', 'UTC'),
  },
  ...overrides
});

function makeItem (overrides) {
  return {
    uniqueId: 'a',
    title: 'aaa',
    date: moment.tz('2018-01-01', 'UTC'),
    completed: false,
    ...overrides
  };
}

it('adds items to the state and orders them on SIDEBAR_ITEMS_LOADED', () => {
  const actual = reducer(getInitialState(), {
    type: 'SIDEBAR_ITEMS_LOADED',
    payload: {
      items: [makeItem({ uniqueId: '1', title: 'bbb' }), makeItem({ uniqueId: '2', title: 'aaa' })],
      nextUrl: null
    }
  });
  const expected = {
    items: [{ uniqueId: '2' }, { uniqueId: '1' }],
    nextUrl: null,
  };
  expect(actual).toMatchObject(expected);
});

it('sets nextUrl to the correct state on SIDEBAR_ITEMS_LOADED', () => {
  const actual = reducer(getInitialState(), {
    type: 'SIDEBAR_ITEMS_LOADED',
    payload: {
      items: [makeItem({ uniqueId: '1' }), makeItem({ uniqueId: '2' })],
      nextUrl: '/',
    }
  });
  const expected = {
    nextUrl: '/',
  };
  expect(actual).toMatchObject(expected);
});

it('sets loading to true on SIDEBAR_ITEMS_LOADING', () => {
  const initialState = getInitialState({
    loading: false
  });
  const actual = reducer(initialState, sidebarItemsLoading());
  const expected = {
    loading: true,
  };
  expect(actual).toMatchObject(expected);
});

it('records the loading range on SIDEBAR_ITEMS_LOADING', () => {
  const initialState = getInitialState({range: {}});
  const range = {firstMoment: 'first', lastMoment: 'last'};
  const actual = reducer(initialState, sidebarItemsLoading(range));
  expect(actual.range).toMatchObject(range);
});

it('sets loaded to true and loading to false on SIDEBAR_ENOUGH_ITEMS_LOADED', () => {
  const initialState = getInitialState({
    loading: true,
    loaded: false,
  });
  const actual = reducer(initialState, {
    type: 'SIDEBAR_ENOUGH_ITEMS_LOADED'
  });
  const expected = {
    loading: false,
    loaded: true,
  };
  expect(actual).toMatchObject(expected);
});

it('sets loading to false on SIDEBAR_ITEMS_LOADING_FAILED', () => {
  const initialState = getInitialState({
    loading: true
  });
  const actual = reducer(initialState, {
    type: 'SIDEBAR_ITEMS_LOADING_FAILED',
    payload: []
  });
  const expected = {
    loading: false,
  };
  expect(actual).toMatchObject(expected);
});

it('updates the item on SAVED_PLANNER_ITEM', () => {
  const initialState = getInitialState({items: [
    {uniqueId: '41', completed: false, date: moment.tz('2018-01-01', 'UTC')},
    {uniqueId: '42', completed: false, date: moment.tz('2018-01-02', 'UTC')},
    {uniqueId: '43', completed: false, date: moment.tz('2018-01-03', 'UTC')},
  ]});
  const nextState = reducer(initialState, savedPlannerItem({
    item: {...initialState.items[1], completed: true}}));
  expect(nextState.items).toMatchObject([
    {uniqueId: '41', completed: false},
    {uniqueId: '42', completed: true},
    {uniqueId: '43', completed: false},
  ]);
  expect(nextState).not.toBe(initialState);
});

it('removes a planner item on DELETED_PLANNER_ITEM', () => {
  const initialState = getInitialState({items: [
    {uniqueId: '42', completed: false, date: moment.tz('2018-01-02', 'UTC')},
  ]});
  const nextState = reducer(initialState, deletedPlannerItem({uniqueId: '42'}));
  expect(nextState.items).toHaveLength(0);
});

it('does not bork on DELETED_PLANNER_ITEM if the item is not found', () => {
  const initialState = getInitialState({items: [
    {uniqueId: '41', completed: false, date: moment.tz('2018-01-02', 'UTC')},
  ]});
  const nextState = reducer(initialState, deletedPlannerItem({uniqueId: '42'}));
  expect(nextState.items).toHaveLength(1);
  expect(nextState).toBe(initialState);
});

it('adds a new planner item in order if it is within range', () => {
  const initialState = getInitialState({items: [
    {uniqueId: '41', completed: false, date: moment.tz('2018-01-01', 'UTC')},
    {uniqueId: '42', completed: false, date: moment.tz('2018-01-03', 'UTC')},
  ]});
  const nextState = reducer(initialState, savedPlannerItem({item:
    {uniqueId: '43', completed: false, date: moment.tz('2018-01-02', 'UTC')}
  }));
  expect(nextState.items).toMatchObject([
    {uniqueId: '41'}, {uniqueId: '43'}, {uniqueId: '42'},
  ]);
});

it('does not add a planner item if it is out of range', () => {
  const initialState = getInitialState({items: [
    {uniqueId: '41', completed: false, date: moment.tz('2018-01-01', 'UTC')},
    {uniqueId: '42', completed: false, date: moment.tz('2018-01-03', 'UTC')},
  ]});
  const nextState = reducer(initialState, savedPlannerItem({item:
    {uniqueId: '43', completed: false, date: moment.tz('2018-01-05', 'UTC')}
  }));
  expect(nextState.items).toMatchObject([
    {uniqueId: '41'}, {uniqueId: '42'},
  ]);
});

it('removes a planner item if its new date falls outside of the range', () => {
  const initialState = getInitialState({items: [
    {uniqueId: '41', completed: false, date: moment.tz('2018-01-01', 'UTC')},
    {uniqueId: '42', completed: false, date: moment.tz('2018-01-03', 'UTC')},
  ]});
  const nextState = reducer(initialState, savedPlannerItem({item:
    {uniqueId: '42', date: moment.tz('2018-01-05', 'UTC')}
  }));
  expect(nextState.items).toMatchObject([
    {uniqueId: '41'},
  ]);
});

it('reorders planner items if the date has changed', () => {
  const initialState = getInitialState({items: [
    {uniqueId: '41', completed: false, date: moment.tz('2018-01-01', 'UTC')},
    {uniqueId: '42', completed: false, date: moment.tz('2018-01-02', 'UTC')},
  ]});
  const nextState = reducer(initialState, savedPlannerItem({item:
    {uniqueId: '41', completed: false, date: moment.tz('2018-01-03', 'UTC')},
  }));
  expect(nextState.items).toMatchObject([
    {uniqueId: '42'}, {uniqueId: '41'},
  ]);
});

it('reorders planner items if the title has changed', () => {
  const initialState = getInitialState({items: [
    {uniqueId: '41', title: 'aaa', completed: false, date: moment.tz('2018-01-01', 'UTC')},
    {uniqueId: '42', title: 'bbb', completed: false, date: moment.tz('2018-01-01', 'UTC')},
  ]});
  const nextState = reducer(initialState, savedPlannerItem({item:
    {uniqueId: '41', title: 'ccc', completed: false, date: moment.tz('2018-01-01', 'UTC')},
  }));
  expect(nextState.items).toMatchObject([
    {uniqueId: '42'}, {uniqueId: '41'},
  ]);
});

it('does not save an item if the sidebar is not loaded yet', () => {
  const initialState = getInitialState({loaded: false});
  const nextState = reducer(initialState, savedPlannerItem({item: makeItem({uniqueId: '41'})}));
  expect(initialState).toEqual(getInitialState({loaded: false}));
  expect(nextState).toBe(initialState);
});
