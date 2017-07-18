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

import Fixtures from 'spec/jsx/gradebook-history/Fixtures';
import GradebookHistoryStore from 'jsx/gradebook-history/store/GradebookHistoryStore';
import HistoryActions from 'jsx/gradebook-history/actions/HistoryActions';
import HistoryApi from 'jsx/gradebook-history/api/HistoryApi';
import SearchFormActions, {
  FETCH_USERS_BY_NAME_START,
  FETCH_USERS_BY_NAME_SUCCESS,
  FETCH_USERS_BY_NAME_FAILURE,
  FETCH_USERS_NEXT_PAGE_START,
  FETCH_USERS_NEXT_PAGE_SUCCESS,
  FETCH_USERS_NEXT_PAGE_FAILURE
} from 'jsx/gradebook-history/actions/SearchFormActions';
import UserApi from 'jsx/gradebook-history/api/UserApi';

QUnit.module('SearchFormActions', function () {
  const response = {
    data: Fixtures.userArray(),
    headers: {
      link: '<http://fake.url/3?&page=first>; rel="current",<http://fake.url/3?&page=bookmark:asdf>; rel="next"'
    }
  };

  test('fetchUsersByNameStarted creates an action with type FETCH_USERS_BY_NAME_START', function () {
    const userType = 'graders';
    const expectedValue = {
      type: FETCH_USERS_BY_NAME_START,
      payload: { userType }
    };

    deepEqual(SearchFormActions.fetchUsersByNameStarted(userType), expectedValue);
  });

  test('fetchUsersByNameSuccess creates an action with type FETCH_USERS_BY_NAME_SUCCESS', function () {
    const userType = 'graders';
    const expectedValue = {
      type: FETCH_USERS_BY_NAME_SUCCESS,
      payload: { userType, data: response.data, link: response.headers.link }
    };

    deepEqual(SearchFormActions.fetchUsersByNameSuccess(response, userType), expectedValue);
  });

  test('fetchUsersByNameFailure creates an action with type FETCH_USERS_BY_NAME_FAILURE', function () {
    const userType = 'graders';
    const expectedValue = {
      type: FETCH_USERS_BY_NAME_FAILURE,
      payload: { userType }
    };

    deepEqual(SearchFormActions.fetchUsersByNameFailure(userType), expectedValue);
  });

  test('fetchUsersNextPageStart creates an action with type FETCH_USERS_NEXT_PAGE_START', function () {
    const userType = 'graders';
    const expectedValue = {
      type: FETCH_USERS_NEXT_PAGE_START,
      payload: { userType }
    };

    deepEqual(SearchFormActions.fetchUsersNextPageStart(userType), expectedValue);
  });

  test('fetchUsersNextPageSuccess creates an action with type FETCH_USERS_NEXT_PAGE_SUCCESS', function () {
    const userType = 'graders';
    const expectedValue = {
      type: FETCH_USERS_NEXT_PAGE_SUCCESS,
      payload: { userType, data: response.data, link: response.headers.link }
    };

    deepEqual(SearchFormActions.fetchUsersNextPageSuccess(response, userType), expectedValue);
  });

  test('fetchUsersNextPageFailure creates an action with type FETCH_USERS_NEXT_PAGE_FAILURE', function () {
    const userType = 'graders';
    const expectedValue = {
      type: FETCH_USERS_NEXT_PAGE_FAILURE,
      payload: { userType }
    };

    deepEqual(SearchFormActions.fetchUsersNextPageFailure(userType), expectedValue);
  });
});

QUnit.module('SearchFormActions getHistoryByAssignment', {
  setup () {
    this.response = Fixtures.response();
    this.getByAssignmentStub = this.stub(HistoryApi, 'getByAssignment')
      .returns(Promise.resolve(this.response));

    this.dispatchSpy = this.spy(GradebookHistoryStore, 'dispatch');
  }
});

test('dispatches fetchHistoryStarted', function () {
  const fetchSpy = this.spy(HistoryActions, 'fetchHistoryStarted');
  const promise = this.dispatchSpy(SearchFormActions.getHistoryByAssignment(1));
  return promise.then(() => {
    equal(fetchSpy.callCount, 1);
  });
});

test('dispatches fetchHistorySuccess on success', function () {
  const fetchSpy = this.spy(HistoryActions, 'fetchHistorySuccess');
  const promise = this.dispatchSpy(SearchFormActions.getHistoryByAssignment(1));
  return promise.then(() => {
    equal(fetchSpy.callCount, 1);
  });
});

test('dispatches fetchHistoryFailure on failure', function () {
  this.getByAssignmentStub.returns(Promise.reject(new Error('FAIL')));
  const fetchStub = this.stub(HistoryActions, 'fetchHistoryFailure');
  const promise = this.dispatchSpy(SearchFormActions.getHistoryByAssignment(1));
  return promise.catch(() => {
    equal(fetchStub.callCount, 1);
  });
});

QUnit.module('SearchFormActions getHistoryByDate', function (hooks) {
  hooks.beforeEach(function () {
    this.response = Fixtures.response();
    this.timeFrame = Fixtures.timeFrame();
    this.getByDateStub = sinon.stub(HistoryApi, 'getByDate')
      .returns(Promise.resolve(this.response));

    this.dispatchSpy = sinon.spy(GradebookHistoryStore, 'dispatch');
  });

  hooks.afterEach(function () {
    this.getByDateStub.restore();
    this.dispatchSpy.restore();
  });

  test('dispatches fetchHistoryStarted', function (assert) {
    const done = assert.async();
    const fetchSpy = sinon.spy(HistoryActions, 'fetchHistoryStarted');
    const promise = this.dispatchSpy(SearchFormActions.getHistoryByDate(this.timeFrame));

    promise.then(() => {
      strictEqual(fetchSpy.callCount, 1);
      fetchSpy.restore();
      done();
    });
  });

  test('dispatches fetchHistorySuccess on success', function (assert) {
    const done = assert.async();
    const fetchSpy = sinon.spy(HistoryActions, 'fetchHistorySuccess');
    const promise = this.dispatchSpy(SearchFormActions.getHistoryByDate(this.timeFrame));

    promise.then(() => {
      strictEqual(fetchSpy.callCount, 1);
      fetchSpy.restore();
      done();
    });
  });

  test('dispatches fetchHistoryFailure on failure', function (assert) {
    this.getByDateStub.returns(Promise.reject(new Error('FAIL')));
    const done = assert.async();
    const fetchStub = sinon.stub(HistoryActions, 'fetchHistoryFailure');
    const promise = this.dispatchSpy(SearchFormActions.getHistoryByDate(this.timeFrame));

    promise.catch(() => {
      strictEqual(fetchStub.callCount, 1);
      fetchStub.restore();
      done();
    });
  });
});

QUnit.module('SearchFormActions getHistoryByGrader', {
  setup () {
    this.response = Fixtures.response();
    this.getByGraderStub = this.stub(HistoryApi, 'getByGrader')
      .returns(Promise.resolve(this.response));

    this.dispatchSpy = this.spy(GradebookHistoryStore, 'dispatch');
  }
});

test('dispatches fetchHistoryStarted', function () {
  const fetchSpy = this.spy(HistoryActions, 'fetchHistoryStarted');
  const promise = this.dispatchSpy(SearchFormActions.getHistoryByGrader(1));
  return promise.then(() => {
    equal(fetchSpy.callCount, 1);
  });
});

test('dispatches fetchHistorySuccess on success', function () {
  const fetchSpy = this.spy(HistoryActions, 'fetchHistorySuccess');
  const promise = this.dispatchSpy(SearchFormActions.getHistoryByGrader(1));
  return promise.then(() => {
    equal(fetchSpy.callCount, 1);
  });
});

test('dispatches fetchHistoryFailure on failure', function () {
  this.getByGraderStub.returns(Promise.reject(new Error('FAIL')));
  const fetchStub = this.stub(HistoryActions, 'fetchHistoryFailure');
  const promise = this.dispatchSpy(SearchFormActions.getHistoryByGrader(1));
  return promise.catch(() => {
    equal(fetchStub.callCount, 1);
  });
});

QUnit.module('SearchFormActions getHistoryByStudent', {
  setup () {
    this.response = Fixtures.response();
    this.getByStudentStub = this.stub(HistoryApi, 'getByStudent')
      .returns(Promise.resolve(this.response));

    this.dispatchSpy = this.spy(GradebookHistoryStore, 'dispatch');
  }
});

test('dispatches fetchHistoryStarted', function () {
  const fetchSpy = this.spy(HistoryActions, 'fetchHistoryStarted');
  const promise = this.dispatchSpy(SearchFormActions.getHistoryByStudent(1));
  return promise.then(() => {
    equal(fetchSpy.callCount, 1);
  });
});

test('dispatches fetchHistorySuccess on success', function () {
  const fetchSpy = this.spy(HistoryActions, 'fetchHistorySuccess');
  const promise = this.dispatchSpy(SearchFormActions.getHistoryByStudent(1));
  return promise.then(() => {
    equal(fetchSpy.callCount, 1);
  });
});

test('dispatches fetchHistoryFailure on failure', function () {
  this.getByStudentStub.returns(Promise.reject(new Error('FAIL')));
  const fetchStub = this.stub(HistoryActions, 'fetchHistoryFailure');
  const promise = this.dispatchSpy(SearchFormActions.getHistoryByStudent(1));
  return promise.catch(() => {
    equal(fetchStub.callCount, 1);
  });
});

QUnit.module('SearchFormActions getNameOptions', {
  setup () {
    const userResponse = {
      response: {
        data: Fixtures.userArray()
      }
    }
    this.getUsersByNameStub = this.stub(UserApi, 'getUsersByName')
      .returns(Promise.resolve(userResponse));

    this.dispatchSpy = this.spy(GradebookHistoryStore, 'dispatch');
  }
});

test('dispatches fetchUsersByNameStarted', function () {
  const fetchSpy = this.spy(SearchFormActions, 'fetchUsersByNameStarted');
  const promise = this.dispatchSpy(SearchFormActions.getNameOptions('graders', 'Norval'));
  return promise.then(() => {
    strictEqual(fetchSpy.callCount, 1);
  });
});

test('dispatches fetchUsersByNameSuccess on success', function () {
  const fetchSpy = this.spy(SearchFormActions, 'fetchUsersByNameSuccess');
  const promise = this.dispatchSpy(SearchFormActions.getNameOptions('graders', 'Norval'));
  return promise.then(() => {
    strictEqual(fetchSpy.callCount, 1);
  });
});

test('dispatches fetchUsersByNameFailure on failure', function () {
  this.getUsersByNameStub.returns(Promise.reject(new Error('FAIL')));
  const fetchStub = this.stub(SearchFormActions, 'fetchUsersByNameFailure');
  const promise = this.dispatchSpy(SearchFormActions.getNameOptions('graders', 'Norval'));
  return promise.catch(() => {
    strictEqual(fetchStub.callCount, 1);
  });
});

QUnit.module('SearchFormActions getNameOptionsNextPage', function (hooks) {
  hooks.beforeEach(function () {
    const userResponse = {
      response: {
        data: Fixtures.userArray()
      }
    }
    this.getUsersNextPageStub = sinon.stub(UserApi, 'getUsersNextPage')
      .returns(Promise.resolve(userResponse));

    this.dispatchSpy = sinon.spy(GradebookHistoryStore, 'dispatch');
  });

  hooks.afterEach(function () {
    this.getUsersNextPageStub.restore();
    this.dispatchSpy.restore();
  });

  test('dispatches fetchUsersNextPageStart', function () {
    const fetchSpy = sinon.spy(SearchFormActions, 'fetchUsersNextPageStart');
    const promise = this.dispatchSpy(SearchFormActions.getNameOptionsNextPage('graders', 'https://fake.url'));
    return promise.then(() => {
      strictEqual(fetchSpy.callCount, 1);
      fetchSpy.restore();
    });
  });

  test('dispatches fetchUsersNextPageSuccess on success', function () {
    const fetchSpy = sinon.spy(SearchFormActions, 'fetchUsersNextPageSuccess');
    const promise = this.dispatchSpy(SearchFormActions.getNameOptionsNextPage('graders', 'https://fake.url'));
    return promise.then(() => {
      strictEqual(fetchSpy.callCount, 1);
      fetchSpy.restore();
    });
  });

  test('dispatches fetchUsersNextPageFailure on failure', function () {
    this.getUsersNextPageStub.returns(Promise.reject(new Error('FAIL')));
    const fetchStub = sinon.stub(SearchFormActions, 'fetchUsersNextPageFailure');
    const promise = this.dispatchSpy(SearchFormActions.getNameOptionsNextPage('graders', 'https://fake.url'));
    return promise.catch(() => {
      strictEqual(fetchStub.callCount, 1);
      fetchStub.restore();
    });
  });
});
