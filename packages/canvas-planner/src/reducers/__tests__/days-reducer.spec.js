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
      { id: 'fourth', date: moment.tz('2017-04-29', 'UTC'), dateBucketMoment: moment.tz('2017-04-29', 'UTC'), title: 'aaa' },
      { id: 'second', date: moment.tz('2017-04-28', 'UTC'), dateBucketMoment: moment.tz('2017-04-28', 'UTC'), title: 'aaa' },
      { id: 'first',  date: moment.tz('2017-04-27', 'UTC'), dateBucketMoment: moment.tz('2017-04-27', 'UTC'), title: 'aaa' },
      { id: 'third',  date: moment.tz('2017-04-28', 'UTC'), dateBucketMoment: moment.tz('2017-04-28', 'UTC'), title: 'bbb' },
    ]);

    const newState = daysReducer(initialState, gotDataAction);
    expect(newState).toMatchObject([
      ['2017-04-27', [{id: 'first'}]],
      ['2017-04-28', [{id: 'second'}, {id: 'third'}]],
      ['2017-04-29', [{id: 'fourth'}]],
    ]);

    const nextGotDataAction = gotItemsSuccess([
      {id: 'fifth', date: moment.tz('2017-04-29', 'UTC'), dateBucketMoment: moment.tz('2017-04-29', 'UTC'), title: 'aaa'},
      {id: 'zeroth', date: moment.tz('2017-04-26', 'UTC') , dateBucketMoment: moment.tz('2017-04-26', 'UTC'), title: 'aaa'},
      {id: 'second', with: 'new data',date: moment.tz('2017-04-28', 'UTC'), dateBucketMoment: moment.tz('2017-04-28', 'UTC'), title: 'aaa'}
    ]);
    const mergedState = daysReducer(newState, nextGotDataAction);
    expect(mergedState).toMatchObject([
      ['2017-04-26', [{id: 'zeroth'}]],
      ['2017-04-27',  [{id: 'first'}]],
      ['2017-04-28', [{id: 'second', with: 'new data'}, {id: 'third'}]],
      ['2017-04-29', [{id: 'fourth'}, {id: 'fifth'}]],
    ]);
  });
});

describe('saving planner items', () => {
  it('adds new items to the day', () => {
    const initialState = [
      ['2017-04-27', [{id: '42', date: moment.tz('2017-04-27', 'UTC'), dateBucketMoment: moment.tz('2017-04-27', 'UTC'), title: 'aaa'}]],
    ];
    const newState = daysReducer(initialState, {
      type: 'SAVED_PLANNER_ITEM',
      payload: {item: {id: '43', date: moment.tz('2017-04-27', 'UTC'), dateBucketMoment: moment.tz('2017-04-27', 'UTC'), title: 'aaa'}},
    });
    expect(newState).toMatchObject([
      ['2017-04-27', [
        {id: '42'},
        {id: '43'},
      ],
    ]]);
  });

  it('merges new data into existing items', () => {
    // more than one item to make sure edited item gets merged, not deleted and re-added
    const initialState = [
      ['2017-04-27', [
        {date: moment.tz('2017-04-27', 'UTC'), dateBucketMoment: moment.tz('2017-04-27', 'UTC'), id: '42', title: 'aaa event'},
        {date: moment.tz('2017-04-27', 'UTC'), dateBucketMoment: moment.tz('2017-04-27', 'UTC'), id: '43', title: 'bbb event'},
      ]],
    ];
    const newState = daysReducer(initialState, {
      type: 'SAVED_PLANNER_ITEM',
      payload: {item: {date: moment.tz( '2017-04-27', 'UTC'), dateBucketMoment: moment.tz( '2017-04-27', 'UTC'), id: '42', title: 'ccc event'}},
    });

    expect(newState[0][0]).toEqual('2017-04-27');
    // new title, and resorted
    expect(newState[0][1]).toMatchObject([
      {id: '43', title: 'bbb event'},
      {id: '42', title: 'ccc event'},
    ]);
  });

  it('edits the date of an existing item', () => {
    const initialState = [
      ['2017-04-27', [
        {dateBucketMoment: moment.tz('2017-04-27', 'UTC'), id: '41', title: 'existing event'},
        {dateBucketMoment: moment.tz('2017-04-27', 'UTC'), id: '42', title: 'an event'},
      ]],
    ];
    const newState = daysReducer(initialState, {
      type: 'SAVED_PLANNER_ITEM',
      payload: {item: {dateBucketMoment: moment.tz( '2017-04-28', 'UTC'), id: '42', title: 'an event'}},
    });
    expect(newState).toMatchObject([
      ['2017-04-27', [{id: '41', title: 'existing event'}]],
      ['2017-04-28', [{id: '42', title: 'an event'}]],
    ]);
  });

  it('adds a new date if the date is not loaded', () => {
    const initialState = [
      ['2017-04-27', [{ id: '42'}]],
    ];

    const fakeDateBucketMoment = moment.tz('2017-04-28', 'UTC');
    const newState = daysReducer(initialState, {
      type: 'SAVED_PLANNER_ITEM',
      payload: {item: {dateBucketMoment: fakeDateBucketMoment, id: '43'}},
    });

    const expectedState = [
      ['2017-04-27', [{ id: '42' }]],
      ['2017-04-28', [{ id: '43', dateBucketMoment: fakeDateBucketMoment }]]
    ];
    expect(newState).toEqual(expectedState);
  });

  it('does not add anything if the action is an error', () => {
    const initialState = [
      ['2017-04-27', [{date: '2017-04-27', id: '42'}]],
    ];
    const newState = daysReducer(initialState, {
      type: 'SAVED_PLANNER_ITEM',
      payload: {item: {dateBucketMoment: moment.tz('2017-04-27', 'UTC'), id: '43'}},
      error: true,
    });
    expect(newState).toBe(initialState);
  });
});

describe('deleting planner items', () => {
  it('removes planner items', () => {
    const initialState = [
      ['2017-04-27', [{id: '42'}, {id: '43'}]],
      ['2017-04-28', [{id: '44'}, {id: '45'}, {id: '46'}]],
      ['2017-04-29', [{id: '47'}, {id: '48'}]],
    ];
    const newState = daysReducer(initialState, {
      type: 'DELETED_PLANNER_ITEM',
      payload: {dateBucketMoment: moment.tz('2017-04-28', 'UTC'), id: '45'},
    });
    expect(newState).toMatchObject([
      ['2017-04-27', [{id: '42'}, {id: '43'}]],
      ['2017-04-28', [{id: '44'}, {id: '46'}]],
      ['2017-04-29', [{id: '47'}, {id: '48'}]],
    ]);
  });

  it('does nothing if the deleted item is not loaded', () => {
    const initialState = [
      ['2017-04-27', [{id: '42'}, {id: '43'}]],
      ['2017-04-28', [{id: '44'}, {id: '45'}, {id: '46'}]],
      ['2017-04-29', [{id: '47'}, {id: '48'}]],
    ];
    const newState = daysReducer(initialState, {
      type: 'DELETED_PLANNER_ITEM',
      payload: {dateBucketMoment: moment.tz('2017-05-01', 'UTC'), id: '52'},
    });
    expect(newState).toBe(initialState);
  });

  it('does nothing if the deleted action fails', () => {
    const initialState = [
      ['2017-04-28', [{id: '44'}, {id: '45'}, {id: '46'}]],
    ];
    const newState = daysReducer(initialState, {
      type: 'DELETED_PLANNER_ITEM',
      payload: {dateBucketMoment: moment.tz('2017-04-28T00:00:00', 'UTC'), id: '45'},
      error: true,
    });
    expect(newState).toBe(initialState);
  });

  it('removes the day if it winds up empty', () => {
    const initialState = [
      ['2017-04-27', [{id: '42'}, {id: '43'}]],
      ['2017-04-28', [{id: '44'}]],
      ['2017-04-29', [{id: '47'}, {id: '48'}]],
    ];
    const newState = daysReducer(initialState, {
      type: 'DELETED_PLANNER_ITEM',
      payload: {dateBucketMoment: moment.tz('2017-04-28', 'UTC'), id: '44'},
    });
    expect(newState).toMatchObject([
      ['2017-04-27', [{id: '42'}, {id: '43'}]],
      ['2017-04-29', [{id: '47'}, {id: '48'}]],
    ]);
  });

});
