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

import axios from 'axios';
import constants from 'jsx/gradebook-history/constants';
import Fixtures from 'spec/jsx/gradebook-history/Fixtures';
import HistoryApi from 'jsx/gradebook-history/api/HistoryApi';

function mockOutParams (id, timeFrame = {from: '', to: ''}) {
  return {
    params: {
      id,
      start_time: timeFrame.from,
      end_time: timeFrame.to,
      per_page: 10
    }
  };
}

QUnit.module('HistoryApi', {
  setup () {
    this.getStub = this.stub(axios, 'get')
      .returns(Promise.resolve({
        status: 200,
        response: Fixtures.response()
      }));
  }
});

test('getByAssignment without a timeFrame', function () {
  const assignmentId = 1;
  const url = encodeURI(`/api/v1/audit/grade_change/assignments/${assignmentId}`);
  const params = mockOutParams(assignmentId);
  const promise = HistoryApi.getByAssignment(1);

  return promise.then(() => {
    equal(this.getStub.callCount, 1);
    equal(this.getStub.firstCall.args[0], url);
    deepEqual(this.getStub.firstCall.args[1], params);
  });
});

test('getByAssignment with a timeFrame', function () {
  const assignmentId = 1;
  const url = encodeURI(`/api/v1/audit/grade_change/assignments/${assignmentId}`);
  const params = mockOutParams(assignmentId, Fixtures.timeFrame());
  const promise = HistoryApi.getByAssignment(1, Fixtures.timeFrame());

  return promise.then(() => {
    equal(this.getStub.callCount, 1);
    equal(this.getStub.firstCall.args[0], url);
    deepEqual(this.getStub.firstCall.args[1], params);
  });
});

test('getByDate', function (assert) {
  const done = assert.async();
  const timeFrame = Fixtures.timeFrame();
  const url = encodeURI(`/api/v1/audit/grade_change/courses/${constants.courseId()}`);
  const params = {
    params: { start_time: timeFrame.from, end_time: timeFrame.to }
  };
  const promise = HistoryApi.getByDate(timeFrame);

  promise.then(() => {
    strictEqual(this.getStub.callCount, 1);
    strictEqual(this.getStub.firstCall.args[0], url);
    deepEqual(this.getStub.firstCall.args[1], params);
    done();
  });
});

test('getByGrader without a timeFrame', function () {
  const graderId = 1;
  const url = encodeURI(`/api/v1/audit/grade_change/graders/${graderId}`);
  const params = mockOutParams(graderId);
  const promise = HistoryApi.getByGrader(1);

  return promise.then(() => {
    equal(this.getStub.callCount, 1);
    equal(this.getStub.firstCall.args[0], url);
    deepEqual(this.getStub.firstCall.args[1], params);
  });
});

test('getByGrader with a timeFrame', function () {
  const graderId = 1;
  const url = encodeURI(`/api/v1/audit/grade_change/graders/${graderId}`);
  const params = mockOutParams(graderId, Fixtures.timeFrame());
  const promise = HistoryApi.getByGrader(1, Fixtures.timeFrame());

  return promise.then(() => {
    equal(this.getStub.callCount, 1);
    equal(this.getStub.firstCall.args[0], url);
    deepEqual(this.getStub.firstCall.args[1], params);
  });
});

test('getByStudent without a timeFrame', function () {
  const studentId = 1;
  const url = encodeURI(`/api/v1/audit/grade_change/students/${studentId}`);
  const params = mockOutParams(studentId);
  const promise = HistoryApi.getByStudent(1);

  return promise.then(() => {
    equal(this.getStub.callCount, 1);
    equal(this.getStub.firstCall.args[0], url);
    deepEqual(this.getStub.firstCall.args[1], params);
  });
});

test('getByStudent with a timeFrame', function () {
  const studentId = 1;
  const url = encodeURI(`/api/v1/audit/grade_change/students/${studentId}`);
  const params = mockOutParams(studentId, Fixtures.timeFrame());
  const promise = HistoryApi.getByStudent(1, Fixtures.timeFrame());

  return promise.then(() => {
    equal(this.getStub.callCount, 1);
    equal(this.getStub.firstCall.args[0], url);
    deepEqual(this.getStub.firstCall.args[1], params);
  });
});
