/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import loadingReducer from '../loading-reducer';
import * as Actions from '../../actions/loading-actions';
import * as OtherActions from '../../actions';

function initialState (opts = {}) {
  return {
    ...loadingReducer(undefined, {}),
    ...opts
  };
}

function linkHeader (nextLink) {
  return {
    headers: {
      link: `<${nextLink}>; rel="next"`,
    }
  };
}

function mockItem (id) {
  return { id };
}

it('sets loading to true on START_LOADING_ITEMS', () => {
  const newState = loadingReducer(initialState(), Actions.startLoadingItems());
  expect(newState).toMatchObject({ isLoading: true });
});

it('sets loadingPast to true on GETTING_PAST_ITEMS', () => {
  const newState = loadingReducer(initialState(), Actions.gettingPastItems());
  expect(newState).toMatchObject({ loadingPast: true });
});

it('sets loadingFuture to true on GETTING_FUTURE_ITEMS', () => {
  const newState = loadingReducer(initialState(), Actions.gettingFutureItems());
  expect(newState).toMatchObject({ loadingFuture: true });
});

it('sets loading to false on GOT_DAYS_SUCCESS', () => {
  const state = initialState({isLoading: true});
  const newState = loadingReducer(state, Actions.gotDaysSuccess([]));
  expect(newState).toMatchObject({
    isLoading: false,
    loadingPast: false,
    loadingFuture: false,
    seekingNewActivity: false,
  });
});

it('sets loadingPast to false on GOT_DAYS_SUCCESS', () => {
  const state = initialState({ loadingPast: true });
  const newState = loadingReducer(state, Actions.gotDaysSuccess([]));
  expect(newState).toMatchObject({ loadingPast: false });
});

it('sets only opportunities fields on ALL_OPPORTUNITIES_LOADED', () => {
  const state = initialState({
    isLoading: true,
    loadingFuture: true,
    loadingPast: true,
    loadingOpportunities: true,
    allOpportunitiesLoaded: false,
  });
  const newState = loadingReducer(state, OtherActions.allOpportunitiesLoaded());
  expect(newState).toMatchObject({
    ...state,
    loadingOpportunities: false,
    allOpportunitiesLoaded: true,
  });
});

it('purges complete days from partial days on GOT_DAYS_SUCCESS', () => {
  const state = initialState({
    partialFutureDays: [['2017-12-18', []], ['2017-12-19', []], ['2017-12-20', [{id:1}]]],
    partialPastDays: [['2017-12-17', []], ['2017-12-16', []], ['2017-12-15', [{id:2}]]],
  });
  const newState = loadingReducer(state, Actions.gotDaysSuccess([
    ['2017-12-18', []], ['2017-12-17', []]
  ]));
  expect(newState).toMatchObject({
    partialFutureDays: [['2017-12-20', [{id:1}]]],
    partialPastDays: [['2017-12-15', [{id:2}]]],
  });
});

it('sets only futureNextUrl from response on GOT_PARTIAL_FUTURE_DAYS when loadingFuture', () => {
  const state = initialState({loadingFuture: true, pastNextUrl: 'original'});
  const newState = loadingReducer(state, Actions.gotPartialFutureDays([], {
    ...linkHeader('someurl')
  }));
  expect(newState).toMatchObject({
    futureNextUrl: 'someurl',
    pastNextUrl: 'original',
    allFutureItemsLoaded: false,
  });
});

it('sets only futureNextUrl from response on initial GOT_PARTIAL_FUTURE_DAYS', () => {
  const state = initialState({isLoading: true, futureNextUrl: 'originalFuture', pastNextUrl: 'originalPast'});
  const newState = loadingReducer(state, Actions.gotPartialFutureDays([], {
    ...linkHeader('futureNextUrl'),
  }));
  expect(newState).toMatchObject({
    futureNextUrl: 'futureNextUrl',
    pastNextUrl: 'originalPast',
    allFutureItemsLoaded: false,
  });
});

it('sets pastNextUrl from response on GOT_PARTIAL_PAST_DAYS', () => {
  const state = initialState({loadingPast: true, futureNextUrl: 'original'});
  const newState = loadingReducer(state, Actions.gotPartialPastDays([], {
     ...linkHeader('someurl'),
   }));
  expect(newState).toMatchObject({
    futureNextUrl: 'original',
    pastNextUrl: 'someurl',
    allPastItemsLoaded: false,
  });
});

it('clears future url and sets allAllFutureItemsLoaded when next is not found', () => {
  const state = initialState({
    isLoading: true,
    allFutureItemsLoaded: false,
    futureNextUrl: 'originalFuture',
    allPastItemsLoaded: false,
    pastNextUrl: 'originalPast'
  });
  const newState = loadingReducer(state, Actions.gotPartialFutureDays([]));
  expect(newState).toMatchObject({
    futureNextUrl: null,
    allFutureItemsLoaded: true,
    pastNextUrl: 'originalPast',
    allPastItemsLoaded: false,
  });
});

it('clears past url when not found', () => {
  const state = initialState({
    loadingPast: true,
    futureNextUrl: 'originalFuture',
    pastNextUrl: 'originalPast'
  });
  const newState = loadingReducer(state, Actions.gotPartialPastDays([]));
  expect(newState).toMatchObject({
    futureNextUrl: 'originalFuture',
    allFutureItemsLoaded: false,
    pastNextUrl: null,
    allPastItemsLoaded: true,
  });
});

it('adds to partialPastDays', () => {
  const originalDays = [
    ['2017-12-18', ['original items']],
  ];
  const state = initialState({
    originalState: 'original state',
    partialPastDays: originalDays,
  });
  const newDays = [
    ['2017-12-17', ['prior items']],
    ['2017-12-19', ['future items']],
  ];
  const newState = loadingReducer(state, Actions.gotPartialPastDays(newDays));
  expect(newState).toMatchObject({
    originalState: 'original state',
    partialPastDays: [
      newDays[0],
      ...originalDays,
      newDays[1],
    ]
  });
});

it('adds to partialFutureDays', () => {
  const originalDays = [
    ['2017-12-18', [mockItem(1)]],
  ];
  const state = initialState({
    originalState: 'original state',
    partialFutureDays: originalDays,
  });
  const newDays = [
    ['2017-12-17', [mockItem(2)]],
    ['2017-12-18', [mockItem(3)]],
    ['2017-12-19', [mockItem(4)]],
  ];
  const newState = loadingReducer(state, Actions.gotPartialFutureDays(newDays));
  expect(newState).toMatchObject({
    originalState: 'original state',
    partialFutureDays: [
      newDays[0],
      ['2017-12-18', [...originalDays[0][1], ...newDays[1][1]]],
      newDays[2],
    ]
  });
});

it('adds to partialPastDays', () => {
  const originalDays = [
    ['2017-12-18', [mockItem(1)]],
  ];
  const state = initialState({
    originalState: 'original state',
    partialPastDays: originalDays,
  });
  const newDays = [
    ['2017-12-17', [mockItem(2)]],
    ['2017-12-18', [mockItem(3)]],
    ['2017-12-19', [mockItem(4)]],
  ];
  const newState = loadingReducer(state, Actions.gotPartialPastDays(newDays));
  expect(newState).toMatchObject({
    originalState: 'original state',
    partialPastDays: [
      newDays[0],
      ['2017-12-18', [...originalDays[0][1], ...newDays[1][1]]],
      newDays[2],
    ]
  });
});

it('sets grades loading', () => {
  const state = initialState();
  const nextState = loadingReducer(state, Actions.startLoadingGradesSaga());
  expect(nextState).toMatchObject({loadingGrades: true, gradesLoaded: false});
});

it('sets grades loaded', () => {
  const state = initialState({loadingGrades: true});
  const nextState = loadingReducer(state, Actions.gotGradesSuccess());
  expect(nextState).toMatchObject({loadingGrades: false, gradesLoaded: true});
});

it('sets grades error', () => {
  const state = initialState({loadingGrades: true});
  const nextState = loadingReducer(state, Actions.gotGradesError({message: 'some error'}));
  expect(nextState).toMatchObject({loadingGrades: false, gradesLoaded: false, gradesLoadingError: 'some error'});
});
