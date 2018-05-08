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
import {gotItemsSuccess} from '../../actions/loading-actions';
import daysReducer from '../days-reducer';
import moment from 'moment-timezone';

describe('getting new items', () => {
  it('adds and replaces items on GOT_DAYS_SUCCESS', () => {
    const initialState = [];

    const gotDataAction = gotItemsSuccess([
      { uniqueId: 'fourth', date: moment.tz('2017-04-29', 'UTC'), dateBucketMoment: moment.tz('2017-04-29', 'UTC'), title: 'aaa' },
      { uniqueId: 'third',  date: moment.tz('2017-04-28', 'UTC'), dateBucketMoment: moment.tz('2017-04-28', 'UTC'), title: 'bbb' },
      { uniqueId: 'first',  date: moment.tz('2017-04-27', 'UTC'), dateBucketMoment: moment.tz('2017-04-27', 'UTC'), title: 'aaa' },
      { uniqueId: 'second', date: moment.tz('2017-04-28', 'UTC'), dateBucketMoment: moment.tz('2017-04-28', 'UTC'), title: 'aaa' },
    ]);

    const newState = daysReducer(initialState, gotDataAction);
    expect(newState).toMatchObject([
      ['2017-04-27', [{uniqueId: 'first'}]],
      ['2017-04-28', [{uniqueId: 'second'}, {uniqueId: 'third'}]],
      ['2017-04-29', [{uniqueId: 'fourth'}]],
    ]);

    const nextGotDataAction = gotItemsSuccess([
      {uniqueId: 'fifth', date: moment.tz('2017-04-29', 'UTC'), dateBucketMoment: moment.tz('2017-04-29', 'UTC'), title: 'aaa'},
      {uniqueId: 'zeroth', date: moment.tz('2017-04-26', 'UTC') , dateBucketMoment: moment.tz('2017-04-26', 'UTC'), title: 'aaa'},
      {uniqueId: 'second', with: 'new data',date: moment.tz('2017-04-28', 'UTC'), dateBucketMoment: moment.tz('2017-04-28', 'UTC'), title: 'aaa'}
    ]);
    const mergedState = daysReducer(newState, nextGotDataAction);
    expect(mergedState).toMatchObject([
      ['2017-04-26', [{uniqueId: 'zeroth'}]],
      ['2017-04-27',  [{uniqueId: 'first'}]],
      ['2017-04-28', [{uniqueId: 'second', with: 'new data'}, {uniqueId: 'third'}]],
      ['2017-04-29', [{uniqueId: 'fourth'}, {uniqueId: 'fifth'}]],
    ]);
  });
});

describe('deleting planner items', () => {
  it('removes planner items', () => {
    const initialState = [
      ['2017-04-27', [{uniqueId: '42'}, {uniqueId: '43'}]],
      ['2017-04-28', [{uniqueId: '44'}, {uniqueId: '45'}, {uniqueId: '46'}]],
      ['2017-04-29', [{uniqueId: '47'}, {uniqueId: '48'}]],
    ];
    const newState = daysReducer(initialState, {
      type: 'DELETED_PLANNER_ITEM',
      payload: {dateBucketMoment: moment.tz('2017-04-28', 'UTC'), uniqueId: '45'},
    });
    expect(newState).toMatchObject([
      ['2017-04-27', [{uniqueId: '42'}, {uniqueId: '43'}]],
      ['2017-04-28', [{uniqueId: '44'}, {uniqueId: '46'}]],
      ['2017-04-29', [{uniqueId: '47'}, {uniqueId: '48'}]],
    ]);
  });

  it('does nothing if the deleted item is not loaded', () => {
    const initialState = [
      ['2017-04-27', [{uniqueId: '42'}, {uniqueId: '43'}]],
      ['2017-04-28', [{uniqueId: '44'}, {uniqueId: '45'}, {uniqueId: '46'}]],
      ['2017-04-29', [{uniqueId: '47'}, {uniqueId: '48'}]],
    ];
    const newState = daysReducer(initialState, {
      type: 'DELETED_PLANNER_ITEM',
      payload: {dateBucketMoment: moment.tz('2017-05-01', 'UTC'), uniqueId: '52'},
    });
    expect(newState).toBe(initialState);
  });

  it('does nothing if the deleted action fails', () => {
    const initialState = [
      ['2017-04-28', [{uniqueId: '44'}, {uniqueId: '45'}, {uniqueId: '46'}]],
    ];
    const newState = daysReducer(initialState, {
      type: 'DELETED_PLANNER_ITEM',
      payload: {dateBucketMoment: moment.tz('2017-04-28T00:00:00', 'UTC'), uniqueId: '45'},
      error: true,
    });
    expect(newState).toBe(initialState);
  });

  it('removes the day if it winds up empty', () => {
    const initialState = [
      ['2017-04-27', [{uniqueId: '42'}, {uniqueId: '43'}]],
      ['2017-04-28', [{uniqueId: '44'}]],
      ['2017-04-29', [{uniqueId: '47'}, {uniqueId: '48'}]],
    ];
    const newState = daysReducer(initialState, {
      type: 'DELETED_PLANNER_ITEM',
      payload: {dateBucketMoment: moment.tz('2017-04-28', 'UTC'), uniqueId: '44'},
    });
    expect(newState).toMatchObject([
      ['2017-04-27', [{uniqueId: '42'}, {uniqueId: '43'}]],
      ['2017-04-29', [{uniqueId: '47'}, {uniqueId: '48'}]],
    ]);
  });

});
