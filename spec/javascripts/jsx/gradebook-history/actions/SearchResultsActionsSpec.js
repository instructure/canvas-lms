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

import Fixtures from '../../gradebook-history/Fixtures';
import GradebookHistoryStore from 'jsx/gradebook-history/store/GradebookHistoryStore';
import HistoryActions from 'jsx/gradebook-history/actions/HistoryActions';
import HistoryApi from 'jsx/gradebook-history/api/HistoryApi';
import SearchResultsActions from 'jsx/gradebook-history/actions/SearchResultsActions';

QUnit.module('SearchResultsActionsSpec getHistoryNextPage', {
  setup () {
    this.response = Fixtures.historyResponse();
    this.getNextPageStub = this.stub(HistoryApi, 'getNextPage')
      .returns(Promise.resolve(this.response));

    this.dispatchSpy = this.spy(GradebookHistoryStore, 'dispatch');
  }
});

test('dispatches fetchHistoryNextPageStart', function () {
  const fetchSpy = this.spy(HistoryActions, 'fetchHistoryNextPageStart');
  const promise = this.dispatchSpy(SearchResultsActions.getHistoryNextPage('http://example.com'));
  return promise.then(() => {
    strictEqual(fetchSpy.callCount, 1);
  });
});

test('dispatches fetchHistoryNextPageSuccess with response data and headers on success', function () {
  const fetchSpy = this.spy(HistoryActions, 'fetchHistoryNextPageSuccess');
  const promise = this.dispatchSpy(SearchResultsActions.getHistoryNextPage('http://example.com'));
  return promise.then(() => {
    strictEqual(fetchSpy.callCount, 1);
    deepEqual(fetchSpy.firstCall.args[0], this.response.data);
    deepEqual(fetchSpy.firstCall.args[1], this.response.headers);
  });
});

test('dispatches fetchHistoryNextPageFailure on failure', function () {
  this.getNextPageStub.returns(Promise.reject(new Error('FAIL')));
  const fetchSpy = this.spy(HistoryActions, 'fetchHistoryNextPageFailure');
  const promise = this.dispatchSpy(SearchResultsActions.getHistoryNextPage('http://example.com'));
  return promise.then(() => {
    strictEqual(fetchSpy.callCount, 1);
    fetchSpy.restore();
  });
});
