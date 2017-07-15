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

import HistoryApi from 'jsx/gradebook-history/api/HistoryApi';
import axios from 'axios';

const mockData = {
  events: [
    { 1: 'some', 2: 'data' },
    { 3: 'more', 4: 'data' }
  ],
  linked: {
    assignments: [],
    courses: [1, 2, 3],
    page_views: []
  },
  links: {}
};

const mockTimeFrame = {
  from: '2017-05-22T00:00:00-05:00',
  to: '2017-05-22T00:00:00-05:00'
};

function mockOutParams (id, timeFrame = {from: '', to: ''}) {
  return {
    params: {
      id,
      start_time: timeFrame.from,
      end_time: timeFrame.to,
      per_page: 20
    }
  };
}

QUnit.module('HistoryApi', {
  setup () {
    this.getStub = this.stub(axios, 'get')
      .returns(Promise.resolve({
        status: 200,
        response: { data: mockData }
      }));
  }
});

test('getByAssignment without a timeFrame', function () {
  const assignmentId = 1;
  const url = encodeURI(`/api/v1/audit/grade_change/assignments/${assignmentId}`);
  const mockParams = mockOutParams(assignmentId);
  const promise = HistoryApi.getByAssignment(1);

  return promise.then(() => {
    equal(this.getStub.callCount, 1);
    equal(this.getStub.getCall(0).args[0], url);
    deepEqual(this.getStub.getCall(0).args[1], mockParams);
  });
});

test('getByAssignment with a timeFrame', function () {
  const assignmentId = 1;
  const url = encodeURI(`/api/v1/audit/grade_change/assignments/${assignmentId}`);
  const mockParams = mockOutParams(assignmentId, mockTimeFrame);
  const promise = HistoryApi.getByAssignment(1, mockTimeFrame);

  return promise.then(() => {
    equal(this.getStub.callCount, 1);
    equal(this.getStub.getCall(0).args[0], url);
    deepEqual(this.getStub.getCall(0).args[1], mockParams);
  });
});

test('getByGrader without a timeFrame', function () {
  const graderId = 1;
  const url = encodeURI(`/api/v1/audit/grade_change/graders/${graderId}`);
  const mockParams = mockOutParams(graderId);
  const promise = HistoryApi.getByGrader(1);

  return promise.then(() => {
    equal(this.getStub.callCount, 1);
    equal(this.getStub.getCall(0).args[0], url);
    deepEqual(this.getStub.getCall(0).args[1], mockParams);
  });
});

test('getByGrader with a timeFrame', function () {
  const graderId = 1;
  const url = encodeURI(`/api/v1/audit/grade_change/graders/${graderId}`);
  const mockParams = mockOutParams(graderId, mockTimeFrame);
  const promise = HistoryApi.getByGrader(1, mockTimeFrame);

  return promise.then(() => {
    equal(this.getStub.callCount, 1);
    equal(this.getStub.getCall(0).args[0], url);
    deepEqual(this.getStub.getCall(0).args[1], mockParams);
  });
});

test('getByStudent without a timeFrame', function () {
  const studentId = 1;
  const url = encodeURI(`/api/v1/audit/grade_change/students/${studentId}`);
  const mockParams = mockOutParams(studentId);
  const promise = HistoryApi.getByStudent(1);

  return promise.then(() => {
    equal(this.getStub.callCount, 1);
    equal(this.getStub.getCall(0).args[0], url);
    deepEqual(this.getStub.getCall(0).args[1], mockParams);
  });
});

test('getByStudent with a timeFrame', function () {
  const studentId = 1;
  const url = encodeURI(`/api/v1/audit/grade_change/students/${studentId}`);
  const mockParams = mockOutParams(studentId, mockTimeFrame);
  const promise = HistoryApi.getByStudent(1, mockTimeFrame);

  return promise.then(() => {
    equal(this.getStub.callCount, 1);
    equal(this.getStub.getCall(0).args[0], url);
    deepEqual(this.getStub.getCall(0).args[1], mockParams);
  });
});
