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

import SearchActions from 'jsx/gradebook-history/actions/SearchActions';
import HistoryApi from 'jsx/gradebook-history/api/HistoryApi';
import GradebookHistoryStore from 'jsx/gradebook-history/store/GradebookHistoryStore';
import {
  fetchHistoryStarted,
  fetchHistorySuccess,
  fetchHistoryFailure
} from 'jsx/gradebook-history/actions/HistoryActions';
import { fetchUsersSuccess } from 'jsx/gradebook-history/actions/UserActions';

const mockUsers = [
  { id: 1, name: 'user' },
  { id: 2, name: 'jackie chan' }
];

const mockEvents = [
  { id: 'string-id', created_at: 'date-time', grade_before: '100', grade_after: '1' },
  { id: 'there', created_at: 'are', grade_before: 'more', grade_after: 'fields' },
  { id: 'but', created_at: 'you', grade_before: 'get', grade_after: 'the idea' }
];

const mockData = {
  events: mockEvents,
  linked: {
    users: mockUsers
  }
};

QUnit.module('SearchActions getHistoryByAssignment', {
  setup () {
    this.getByAssignmentStub = this.stub(HistoryApi, 'getByAssignment')
      .returns(Promise.resolve({
        data: mockData
      }));

    this.dispatchSpy = this.spy(GradebookHistoryStore, 'dispatch');
  }
});

test('dispatches fetchHistoryStarted', function () {
  const fn = SearchActions.getHistoryByAssignment(1);
  fn(this.dispatchSpy);
  ok(this.dispatchSpy.callCount > 0);
  deepEqual(this.dispatchSpy.getCall(0).args[0], fetchHistoryStarted());
});

test('dispatches fetchUsersSuccess on success', function () {
  const fn = SearchActions.getHistoryByAssignment(1);
  const promise = fn(this.dispatchSpy);
  return promise.then(() => {
    ok(this.dispatchSpy.callCount > 1);
    deepEqual(this.dispatchSpy.getCall(1).args[0], fetchUsersSuccess(mockUsers));
  });
});

test('dispatches fetchHistorySuccess on success', function () {
  const fn = SearchActions.getHistoryByAssignment(1);
  const promise = fn(this.dispatchSpy);
  return promise.then(() => {
    ok(this.dispatchSpy.callCount > 2);
    deepEqual(this.dispatchSpy.getCall(2).args[0], fetchHistorySuccess(mockEvents));
  });
});

test('dispatches fetchHistoryFailure on failure', function () {
  this.getByAssignmentStub.returns(Promise.reject(new Error('FAIL')));
  const fn = SearchActions.getHistoryByAssignment(1);
  const promise = fn(this.dispatchSpy);
  return promise.then(() => {
    ok(this.dispatchSpy.callCount > 1);
    deepEqual(this.dispatchSpy.getCall(1).args[0], fetchHistoryFailure());
  });
});

QUnit.module('SearchActions getHistoryByGrader', {
  setup () {
    this.getByGraderStub = this.stub(HistoryApi, 'getByGrader')
      .returns(Promise.resolve({
        data: mockData
      }));

    this.dispatchSpy = this.spy(GradebookHistoryStore, 'dispatch');
  }
});

test('dispatches fetchHistoryStarted', function () {
  const fn = SearchActions.getHistoryByGrader(1);
  fn(this.dispatchSpy);
  ok(this.dispatchSpy.callCount > 0);
  deepEqual(this.dispatchSpy.getCall(0).args[0], fetchHistoryStarted());
});

test('dispatches fetchUsersSuccess on success', function () {
  const fn = SearchActions.getHistoryByGrader(1);
  const promise = fn(this.dispatchSpy);
  return promise.then(() => {
    ok(this.dispatchSpy.callCount > 1);
    deepEqual(this.dispatchSpy.getCall(1).args[0], fetchUsersSuccess(mockUsers));
  });
});

test('dispatches fetchHistorySuccess on success', function () {
  const fn = SearchActions.getHistoryByGrader(1);
  const promise = fn(this.dispatchSpy);
  return promise.then(() => {
    ok(this.dispatchSpy.callCount > 2);
    deepEqual(this.dispatchSpy.getCall(2).args[0], fetchHistorySuccess(mockEvents));
  });
});

test('dispatches fetchHistoryFailure on failure', function () {
  this.getByGraderStub.returns(Promise.reject(new Error('FAIL')));
  const fn = SearchActions.getHistoryByGrader(1);
  const promise = fn(this.dispatchSpy);
  return promise.then(() => {
    ok(this.dispatchSpy.callCount > 1);
    deepEqual(this.dispatchSpy.getCall(1).args[0], fetchHistoryFailure());
  });
});

QUnit.module('SearchActions getHistoryByStudent', {
  setup () {
    this.getByStudentStub = this.stub(HistoryApi, 'getByStudent')
      .returns(Promise.resolve({
        data: mockData
      }));

    this.dispatchSpy = this.spy(GradebookHistoryStore, 'dispatch');
  }
});

test('dispatches fetchHistoryStarted', function () {
  const fn = SearchActions.getHistoryByStudent(1);
  fn(this.dispatchSpy);
  ok(this.dispatchSpy.callCount > 0);
  deepEqual(this.dispatchSpy.getCall(0).args[0], fetchHistoryStarted());
});

test('dispatches fetchUsersSuccess on success', function () {
  const fn = SearchActions.getHistoryByStudent(1);
  const promise = fn(this.dispatchSpy);
  return promise.then(() => {
    ok(this.dispatchSpy.callCount > 1);
    deepEqual(this.dispatchSpy.getCall(1).args[0], fetchUsersSuccess(mockUsers));
  });
});

test('dispatches fetchHistorySuccess on success', function () {
  const fn = SearchActions.getHistoryByStudent(1);
  const promise = fn(this.dispatchSpy);
  return promise.then(() => {
    ok(this.dispatchSpy.callCount > 2);
    deepEqual(this.dispatchSpy.getCall(2).args[0], fetchHistorySuccess(mockEvents));
  });
});

test('dispatches fetchHistoryFailure on failure', function () {
  this.getByStudentStub.returns(Promise.reject(new Error('FAIL')));
  const fn = SearchActions.getHistoryByStudent(1);
  const promise = fn(this.dispatchSpy);
  return promise.then(() => {
    ok(this.dispatchSpy.callCount > 1);
    deepEqual(this.dispatchSpy.getCall(1).args[0], fetchHistoryFailure());
  });
});
