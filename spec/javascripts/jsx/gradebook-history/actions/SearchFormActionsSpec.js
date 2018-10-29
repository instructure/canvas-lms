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

import environment from 'jsx/gradebook-history/environment';
import GradebookHistoryStore from 'jsx/gradebook-history/store/GradebookHistoryStore';
import * as HistoryActions from 'jsx/gradebook-history/actions/HistoryActions';
import HistoryApi from 'jsx/gradebook-history/api/HistoryApi';
import SearchFormActions, {
  CLEAR_RECORDS,
  FETCH_RECORDS_START,
  FETCH_RECORDS_SUCCESS,
  FETCH_RECORDS_FAILURE,
  FETCH_RECORDS_NEXT_PAGE_START,
  FETCH_RECORDS_NEXT_PAGE_SUCCESS,
  FETCH_RECORDS_NEXT_PAGE_FAILURE
} from 'jsx/gradebook-history/actions/SearchFormActions';
import UserApi from 'jsx/gradebook-history/api/UserApi';
import Fixtures from '../../gradebook-history/Fixtures';

QUnit.module('SearchFormActions', function () {
  const response = {
    data: Fixtures.userArray(),
    headers: {
      link: '<http://example.com/3?&page=first>; rel="current",<http://example.com/3?&page=bookmark:asdf>; rel="next"'
    }
  };

  test('fetchRecordsStart creates an action with type FETCH_RECORDS_START', function () {
    const recordType = 'graders';
    const expectedValue = {
      type: FETCH_RECORDS_START,
      payload: { recordType }
    };

    deepEqual(SearchFormActions.fetchRecordsStart(recordType), expectedValue);
  });

  test('fetchRecordsFailure creates an action with type FETCH_RECORDS_SUCCESS', function () {
    const recordType = 'graders';
    const expectedValue = {
      type: FETCH_RECORDS_SUCCESS,
      payload: { recordType, data: response.data, link: response.headers.link }
    };

    deepEqual(SearchFormActions.fetchRecordsSuccess(response, recordType), expectedValue);
  });

  test('fetchRecordsFailure creates an action with type FETCH_RECORDS_FAILURE', function () {
    const recordType = 'graders';
    const expectedValue = {
      type: FETCH_RECORDS_FAILURE,
      payload: { recordType }
    };

    deepEqual(SearchFormActions.fetchRecordsFailure(recordType), expectedValue);
  });

  test('fetchRecordsNextPageStart creates an action with type FETCH_RECORDS_NEXT_PAGE_START', function () {
    const recordType = 'graders';
    const expectedValue = {
      type: FETCH_RECORDS_NEXT_PAGE_START,
      payload: { recordType }
    };

    deepEqual(SearchFormActions.fetchRecordsNextPageStart(recordType), expectedValue);
  });

  test('fetchRecordsNextPageSuccess creates an action with type FETCH_RECORDS_NEXT_PAGE_SUCCESS', function () {
    const recordType = 'graders';
    const expectedValue = {
      type: FETCH_RECORDS_NEXT_PAGE_SUCCESS,
      payload: { recordType, data: response.data, link: response.headers.link }
    };

    deepEqual(SearchFormActions.fetchRecordsNextPageSuccess(response, recordType), expectedValue);
  });

  test('fetchRecordsNextPageFailure creates an action with type FETCH_RECORDS_NEXT_PAGE_FAILURE', function () {
    const recordType = 'graders';
    const expectedValue = {
      type: FETCH_RECORDS_NEXT_PAGE_FAILURE,
      payload: { recordType }
    };

    deepEqual(SearchFormActions.fetchRecordsNextPageFailure(recordType), expectedValue);
  });

  test('clearSearchOptions creates an action with type CLEAR_RECORDS', function () {
    const recordType = 'assignments';
    const expectedValue = {
      type: CLEAR_RECORDS,
      payload: { recordType }
    };

    deepEqual(SearchFormActions.clearSearchOptions(recordType), expectedValue);
  });
});

QUnit.module('SearchFormActions getGradebookHistory', {
  setup () {
    this.response = Fixtures.historyResponse();
    this.getGradebookHistoryStub = sandbox.stub(HistoryApi, 'getGradebookHistory')
      .returns(Promise.resolve(this.response));

    this.dispatchSpy = sandbox.spy(GradebookHistoryStore, 'dispatch');
  }
});

test('dispatches fetchHistoryStart', function () {
  const fetchSpy = sandbox.spy(HistoryActions, 'fetchHistoryStart');
  const promise = this.dispatchSpy(SearchFormActions.getGradebookHistory({}));
  return promise.then(() => {
    strictEqual(fetchSpy.callCount, 1);
  });
});

test('dispatches fetchHistorySuccess on success', function () {
  const fetchSpy = sandbox.spy(HistoryActions, 'fetchHistorySuccess');
  const promise = this.dispatchSpy(SearchFormActions.getGradebookHistory({}));
  return promise.then(() => {
    strictEqual(fetchSpy.callCount, 1);
    deepEqual(fetchSpy.firstCall.args[0], this.response.data);
    deepEqual(fetchSpy.firstCall.args[1], this.response.headers);
  });
});

test('dispatches fetchHistoryFailure on failure', function () {
  this.getGradebookHistoryStub.returns(Promise.reject(new Error('FAIL')));
  const fetchSpy = sandbox.spy(HistoryActions, 'fetchHistoryFailure');
  const promise = this.dispatchSpy(SearchFormActions.getGradebookHistory({}));
  return promise.then(() => {
    strictEqual(fetchSpy.callCount, 1);
  });
});

QUnit.module('SearchFormActions getSearchOptions', {
  setup () {
    this.userResponse = {
      data: Fixtures.userArray(),
      headers: { link: 'http://example.com/link-to-next-page' }
    };

    this.getUsersByNameStub = sandbox.stub(UserApi, 'getUsersByName')
      .returns(Promise.resolve(this.userResponse));
    this.courseIsConcludedStub = sandbox.stub(environment, 'courseIsConcluded');

    this.dispatchSpy = sandbox.spy(GradebookHistoryStore, 'dispatch');
  }
});

test('dispatches fetchRecordsStart', function () {
  const fetchSpy = sandbox.spy(SearchFormActions, 'fetchRecordsStart');
  const promise = this.dispatchSpy(SearchFormActions.getSearchOptions('assignments', '50 Page Essay'));
  return promise.then(() => {
    strictEqual(fetchSpy.callCount, 1);
  });
});

test('dispatches fetchRecordsSuccess on success', function () {
  const fetchSpy = sandbox.spy(SearchFormActions, 'fetchRecordsSuccess');
  const promise = this.dispatchSpy(SearchFormActions.getSearchOptions('graders', 'Norval'));
  return promise.then(() => {
    strictEqual(fetchSpy.callCount, 1);
    deepEqual(fetchSpy.firstCall.args[0], this.userResponse);
    strictEqual(fetchSpy.firstCall.args[1], 'graders');
  });
});

test('dispatches fetchRecordsFailure on failure', function () {
  this.getUsersByNameStub.returns(Promise.reject(new Error('FAIL')));
  const fetchSpy = sandbox.spy(SearchFormActions, 'fetchRecordsFailure');
  const promise = this.dispatchSpy(SearchFormActions.getSearchOptions('students', 'Norval'));
  return promise.then(() => {
    strictEqual(fetchSpy.callCount, 1);
  });
});

test('calls getUsersByName with empty array for enrollmentStates if course is not concluded', function() {
  this.courseIsConcludedStub.returns(false);

  UserApi.getUsersByName.restore();
  const getUsersSpy = sandbox.spy(UserApi, 'getUsersByName');

  const promise = this.dispatchSpy(SearchFormActions.getSearchOptions('students', 'Norval'));
  return promise.then(() => {
    strictEqual(getUsersSpy.callCount, 1);
    deepEqual(getUsersSpy.firstCall.args[3], []);
  });
});

test('calls getUsersByName with enrollmentStates of ["completed"] if course is concluded', function() {
  this.courseIsConcludedStub.returns(true);

  UserApi.getUsersByName.restore();
  const getUsersSpy = sandbox.spy(UserApi, 'getUsersByName');

  const promise = this.dispatchSpy(SearchFormActions.getSearchOptions('students', 'Norval'));
  return promise.then(() => {
    strictEqual(getUsersSpy.callCount, 1);
    deepEqual(getUsersSpy.firstCall.args[3], ['completed']);
  });
});

QUnit.module('SearchFormActions getSearchOptionsNextPage', function (hooks) {
  hooks.beforeEach(function () {
    this.userResponse = {
      data: Fixtures.userArray(),
      headers: { link: 'http://example.com/link-to-next-page' }
    };
    this.getUsersNextPageStub = sinon.stub(UserApi, 'getUsersNextPage')
      .returns(Promise.resolve(this.userResponse));

    this.dispatchSpy = sinon.spy(GradebookHistoryStore, 'dispatch');
  });

  hooks.afterEach(function () {
    this.getUsersNextPageStub.restore();
    this.dispatchSpy.restore();
  });

  test('dispatches fetchRecordsNextPageStart', function () {
    const fetchSpy = sinon.spy(SearchFormActions, 'fetchRecordsNextPageStart');
    const promise = this.dispatchSpy(SearchFormActions.getSearchOptionsNextPage('graders', 'https://example.com'));
    return promise.then(() => {
      strictEqual(fetchSpy.callCount, 1);
      fetchSpy.restore();
    });
  });

  test('dispatches fetchRecordsNextPageSuccess on success', function () {
    const fetchSpy = sinon.spy(SearchFormActions, 'fetchRecordsNextPageSuccess');
    const promise = this.dispatchSpy(SearchFormActions.getSearchOptionsNextPage('graders', 'https://example.com'));
    return promise.then(() => {
      strictEqual(fetchSpy.callCount, 1);
      deepEqual(fetchSpy.firstCall.args[0], this.userResponse);
      strictEqual(fetchSpy.firstCall.args[1], 'graders');
      fetchSpy.restore();
    });
  });

  test('dispatches fetchRecordsNextPageFailure on failure', function () {
    this.getUsersNextPageStub.returns(Promise.reject(new Error('FAIL')));
    const fetchSpy = sinon.spy(SearchFormActions, 'fetchRecordsNextPageFailure');
    const promise = this.dispatchSpy(SearchFormActions.getSearchOptionsNextPage('graders', 'https://example.com'));
    return promise.then(() => {
      strictEqual(fetchSpy.callCount, 1);
      fetchSpy.restore();
    });
  });
});
