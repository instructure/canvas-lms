/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import _ from 'underscore';
import qs from 'qs';
import DataLoader from 'jsx/gradezilla/DataLoader';

QUnit.module('Gradebook Data Loader', function (hooks) {
  let fakeXhr;
  let XHRS;
  let XHR_HANDLERS;
  let handlerIndex;

  const ASSIGNMENT_GROUPS = [{id: 1}, {id: 4}];
  const CONTEXT_MODULES = [{id: 1}, {id: 3}];
  const STUDENT_IDS = ['1101', '1102', '1103'];
  const GRADING_PERIOD_ASSIGNMENTS = { 1401: ['2301'] };
  const STUDENTS_PAGE_1 = [{ id: '1101' }, { id: '1102' }];
  const STUDENTS_PAGE_2 = [{ id: '1103' }];
  const SUBMISSIONS_CHUNK_1 = [{ id: '2501' }];
  const SUBMISSIONS_CHUNK_2 = [{ id: '2502' }, { id: '2503' }];
  const CUSTOM_COLUMNS_PAGE_1 = [{ id: '2401' }, { id: '2402' }];
  const CUSTOM_COLUMNS_PAGE_2 = [{ id: '2403' }];

  hooks.beforeEach(function () {
    this.qunitTimeout = QUnit.config.testTimeout;
    // because the assignment groups request takes a while, limit the timeout to at least 500ms
    QUnit.config.testTimeout = 500;

    XHRS = [];
    XHR_HANDLERS = [];
    handlerIndex = 0;
    fakeXhr = sinon.useFakeXMLHttpRequest();
    fakeXhr.onCreate = (xhr) => {
      XHRS.push(xhr);
      // This setTimeout allows jquery to finish setting up the XHR before we try to handle it.
      setTimeout(() => {
        if (XHR_HANDLERS && typeof XHR_HANDLERS[handlerIndex] === 'function') {
          XHR_HANDLERS[handlerIndex]();
        }
      });
    };
  });

  hooks.afterEach(function () {
    fakeXhr.restore();
    XHR_HANDLERS = [];

    QUnit.config.testTimeout = this.qunitTimeout;
    this.qunitTimeout = null;
  });

  function callLoadGradebookData (options = {}) {
    return DataLoader.loadGradebookData({
      assignmentGroupsParams: { ag_params: 'ok' },
      assignmentGroupsURL: '/ags',
      contextModulesURL: '/context-modules',
      courseId: '1201',
      customColumnDataPageCb () {},
      customColumnDataParams: { custom_column_data_params: '...' },
      customColumnDataURL: '/customcols/:id/data',
      customColumnsURL: '/customcols',
      perPage: 2,
      studentsPageCb () {},
      studentsParams: { student_params: 'whatever' },
      studentsURL: '/students',
      submissionsChunkCb () {},
      submissionsChunkSize: 2,
      submissionsParams: { submission_params: 'blahblahblah' },
      submissionsURL: '/submissions',
      ...options
    });
  }

  function matchParams (request, params) {
    const queryString = request.url.split('?')[1] || '';
    const queryParams = qs.parse(queryString);
    return Object.keys(params).every(key => (
      // ensure the params match, no matter the data type
      qs.stringify({ [key]: queryParams[key] }) === qs.stringify({ [key]: params[key] })
    ));
  }

  function matchRequest (xhrs, url, params) {
    return xhrs.find(request => request.url.match(url) && matchParams(request, params));
  }

  function handleRequest (url, params, status, headers, data) {
    const pendingXhrs = XHRS.filter(x => !x.status);
    const xhr = matchRequest(pendingXhrs, url, params);
    if (xhr) {
      xhr.respond(status, headers, JSON.stringify(data));
      handlerIndex++;
    }
  }

  function respondWith (url, params, status, headers, data) {
    XHR_HANDLERS.push(() => {
      handleRequest(url, params, status, headers, data);
    });
  }

  QUnit.module('Assignment Groups');

  test('resolves promise with data when all groups are loaded', function (assert) {
    respondWith('/ags', { ag_params: 'ok' }, 200, { Link: '' }, ASSIGNMENT_GROUPS);

    const dataLoader = callLoadGradebookData();
    const resolve = assert.async();

    dataLoader.gotAssignmentGroups.then((ags) => {
      ok(_.isEqual(ags, ASSIGNMENT_GROUPS));
      resolve();
    });
  });

  QUnit.module('Context Modules');

  test('resolves promise with data when all modules are loaded', function (assert) {
    respondWith('/context-modules', {}, 200, { Link: '' }, CONTEXT_MODULES);

    const dataLoader = callLoadGradebookData();
    const resolve = assert.async();

    dataLoader.gotContextModules.then((modules) => {
      deepEqual(modules, CONTEXT_MODULES);
      resolve();
    });
  });

  QUnit.module('Students and Submissions');

  test('requests student ids using the given course id', function () {
    respondWith('/courses/1201/gradebook/user_ids', {}, 200, {}, { user_ids: STUDENT_IDS });

    callLoadGradebookData();

    const userIdsRequests = XHRS.filter(xhr => xhr.url.match('/courses/1201/gradebook/user_ids'));
    strictEqual(userIdsRequests.length, 1, 'one request for user ids was made');
  });

  test('resolves gotStudentIds when user ids have loaded', function (assert) {
    respondWith('/courses/1201/gradebook/user_ids', {}, 200, {}, { user_ids: STUDENT_IDS });

    const dataLoader = callLoadGradebookData();
    const resolve = assert.async();

    dataLoader.gotStudentIds.then(() => {
      ok(true, 'gotStudentIds resolved');
      resolve();
    });
  });

  test('requests students using the returned student ids', function (assert) {
    respondWith('/courses/1201/gradebook/user_ids', {}, 200, {}, { user_ids: STUDENT_IDS });

    const dataLoader = callLoadGradebookData({ perPage: 50 });
    const resolve = assert.async();

    dataLoader.gotStudentIds.then(() => {
      const studentRequest = XHRS.find(xhr => xhr.url.match('/students'));
      const params = qs.parse(studentRequest.url.split('?')[1]);
      deepEqual(params.user_ids, STUDENT_IDS);
      resolve();
    });
  });

  test('requests students using only student ids not included in the given "loadedStudentIds"', function (assert) {
    respondWith('/courses/1201/gradebook/user_ids', {}, 200, {}, { user_ids: STUDENT_IDS });

    const dataLoader = callLoadGradebookData({ loadedStudentIds: ['1101', '1103'], perPage: 50 });
    const resolve = assert.async();

    dataLoader.gotStudentIds.then(() => {
      const studentRequest = XHRS.find(xhr => xhr.url.match('/students'));
      const params = qs.parse(studentRequest.url.split('?')[1]);
      deepEqual(params.user_ids, ['1102']);
      resolve();
    });
  });

  test('resolves gotStudents when all students have loaded', function (assert) {
    respondWith('/courses/1201/gradebook/user_ids', {}, 200, {}, { user_ids: STUDENT_IDS });
    respondWith('/students', { user_ids: STUDENT_IDS }, 200, {}, []);

    const dataLoader = callLoadGradebookData({ perPage: 50 });
    const resolve = assert.async();

    dataLoader.gotStudents.then(() => {
      ok(true, 'gotStudents resolved');
      resolve();
    });
  });

  test('resolves gotStudents when multiple pages of students have loaded', function (assert) {
    respondWith('/courses/1201/gradebook/user_ids', {}, 200, {}, { user_ids: STUDENT_IDS });
    respondWith('/students', { user_ids: STUDENT_IDS.slice(0, 2) }, 200, {}, STUDENTS_PAGE_1);
    respondWith('/students', { user_ids: STUDENT_IDS.slice(2, 3) }, 200, {}, STUDENTS_PAGE_2);

    const dataLoader = callLoadGradebookData();
    const resolve = assert.async();

    dataLoader.gotStudents.then(() => {
      const studentRequests = XHRS.filter(xhr => xhr.url.match('/students'));
      strictEqual(studentRequests.length, 2);
      resolve();
    });
  });

  test('calls the students page callback when each students page request resolves', function (assert) {
    respondWith('/courses/1201/gradebook/user_ids', {}, 200, {}, { user_ids: STUDENT_IDS });
    respondWith('/students', { user_ids: STUDENT_IDS.slice(0, 2) }, 200, {}, STUDENTS_PAGE_1);
    respondWith('/students', { user_ids: STUDENT_IDS.slice(2, 3) }, 200, {}, STUDENTS_PAGE_2);

    let callCount = 0;
    function incrementCallCount () {
      callCount++;
    }

    const dataLoader = callLoadGradebookData({ studentsPageCb: incrementCallCount });
    const resolve = assert.async();

    dataLoader.gotStudents.then(() => {
      strictEqual(callCount, 2);
      resolve();
    });
  });

  test('includes the returned students with each students page callback', function (assert) {
    respondWith('/courses/1201/gradebook/user_ids', {}, 200, {}, { user_ids: STUDENT_IDS });
    respondWith('/students', { user_ids: STUDENT_IDS.slice(0, 2) }, 200, {}, STUDENTS_PAGE_1);
    respondWith('/students', { user_ids: STUDENT_IDS.slice(2, 3) }, 200, {}, STUDENTS_PAGE_2);

    const pages = [];
    function saveStudents (students) {
      pages.push(students);
    }

    const dataLoader = callLoadGradebookData({ studentsPageCb: saveStudents });
    const resolve = assert.async();

    dataLoader.gotStudents.then(() => {
      strictEqual(pages.length, 2, 'two pages of students were returned');
      deepEqual(pages[0], STUDENTS_PAGE_1);
      deepEqual(pages[1], STUDENTS_PAGE_2);
      resolve();
    });
  });

  test('includes all returned students when resolving gotStudents', function (assert) {
    respondWith('/courses/1201/gradebook/user_ids', {}, 200, {}, { user_ids: STUDENT_IDS });
    respondWith('/students', { user_ids: STUDENT_IDS.slice(0, 2) }, 200, {}, STUDENTS_PAGE_1);
    respondWith('/students', { user_ids: STUDENT_IDS.slice(2, 3) }, 200, {}, STUDENTS_PAGE_2);
    respondWith('/submissions', { student_ids: STUDENT_IDS.slice(0, 2) }, 200, { Link: '' }, SUBMISSIONS_CHUNK_1);
    respondWith('/submissions', { student_ids: STUDENT_IDS.slice(2, 3) }, 200, { Link: '' }, SUBMISSIONS_CHUNK_2);

    const dataLoader = callLoadGradebookData();
    const resolve = assert.async();

    dataLoader.gotStudents.then((students) => {
      strictEqual(students.length, 3, 'three students were returned in total');
      deepEqual(students.map(student => student.id), ['1101', '1102', '1103']);
      resolve();
    });
  });

  test('requests submissions for each page of students', function (assert) {
    respondWith('/courses/1201/gradebook/user_ids', {}, 200, {}, { user_ids: STUDENT_IDS });
    respondWith('/students', { user_ids: STUDENT_IDS.slice(0, 2) }, 200, {}, STUDENTS_PAGE_1);
    respondWith('/students', { user_ids: STUDENT_IDS.slice(2, 3) }, 200, {}, STUDENTS_PAGE_2);

    const dataLoader = callLoadGradebookData();
    const resolve = assert.async();

    dataLoader.gotStudents.then(() => {
      const submissionsRequests = XHRS.filter(xhr => xhr.url.match('/submissions'));
      strictEqual(submissionsRequests.length, 2, 'two requests for submissions were made');
      resolve();
    });
  });

  test('includes "points_deducted" when requesting submissions', function (assert) {
    respondWith('/courses/1201/gradebook/user_ids', {}, 200, {}, { user_ids: STUDENT_IDS });
    respondWith('/students', { user_ids: STUDENT_IDS.slice(0, 2) }, 200, {}, STUDENTS_PAGE_1);
    respondWith('/students', { user_ids: STUDENT_IDS.slice(2, 3) }, 200, {}, STUDENTS_PAGE_2);

    const dataLoader = callLoadGradebookData();
    const resolve = assert.async();

    dataLoader.gotStudents.then(() => {
      const submissionsRequest = XHRS.find(xhr => xhr.url.match('/submissions'));
      const params = qs.parse(submissionsRequest.url.split('?')[1]);
      ok(params.response_fields.includes('points_deducted'));
      resolve();
    });
  });

  test('includes "cached_due_date" when requesting submissions', function (assert) {
    respondWith('/courses/1201/gradebook/user_ids', {}, 200, {}, { user_ids: STUDENT_IDS });
    respondWith('/students', { user_ids: STUDENT_IDS.slice(0, 2) }, 200, {}, STUDENTS_PAGE_1);
    respondWith('/students', { user_ids: STUDENT_IDS.slice(2, 3) }, 200, {}, STUDENTS_PAGE_2);

    const dataLoader = callLoadGradebookData();
    const resolve = assert.async();

    dataLoader.gotStudents.then(() => {
      const submissionsRequest = XHRS.find(xhr => xhr.url.match('/submissions'));
      const params = qs.parse(submissionsRequest.url.split('?')[1]);
      ok(params.response_fields.includes('cached_due_date'));
      resolve();
    });
  });

  test('includes "late_policy_status" when requesting submissions', function (assert) {
    respondWith('/courses/1201/gradebook/user_ids', {}, 200, {}, { user_ids: STUDENT_IDS });
    respondWith('/students', { user_ids: STUDENT_IDS.slice(0, 2) }, 200, {}, STUDENTS_PAGE_1);
    respondWith('/students', { user_ids: STUDENT_IDS.slice(2, 3) }, 200, {}, STUDENTS_PAGE_2);

    const dataLoader = callLoadGradebookData();
    const resolve = assert.async();

    dataLoader.gotStudents.then(() => {
      const submissionsRequest = XHRS.find(xhr => xhr.url.match('/submissions'));
      const params = qs.parse(submissionsRequest.url.split('?')[1]);
      ok(params.response_fields.includes('late_policy_status'));
      resolve();
    });
  });

  test('resolves gotSubmissions when all pages of submissions have loaded', function (assert) {
    respondWith('/courses/1201/gradebook/user_ids', {}, 200, {}, { user_ids: STUDENT_IDS });
    respondWith('/students', { user_ids: STUDENT_IDS.slice(0, 2) }, 200, {}, STUDENTS_PAGE_1);
    respondWith('/students', { user_ids: STUDENT_IDS.slice(2, 3) }, 200, {}, STUDENTS_PAGE_2);
    respondWith('/submissions', { student_ids: STUDENT_IDS.slice(0, 2) }, 200, { Link: '' }, SUBMISSIONS_CHUNK_1);
    respondWith('/submissions', { student_ids: STUDENT_IDS.slice(2, 3) }, 200, { Link: '' }, SUBMISSIONS_CHUNK_2);

    const dataLoader = callLoadGradebookData();
    const resolve = assert.async();

    dataLoader.gotSubmissions.then(() => {
      ok(true, 'gotSubmissions resolved');
      resolve();
    });
  });

  test('includes the returned submissions with each students page callback', function (assert) {
    respondWith('/courses/1201/gradebook/user_ids', {}, 200, {}, { user_ids: STUDENT_IDS });
    respondWith('/students', { user_ids: STUDENT_IDS.slice(0, 2) }, 200, {}, STUDENTS_PAGE_1);
    respondWith('/students', { user_ids: STUDENT_IDS.slice(2, 3) }, 200, {}, STUDENTS_PAGE_2);
    respondWith('/submissions', { student_ids: STUDENT_IDS.slice(0, 2) }, 200, { Link: '' }, SUBMISSIONS_CHUNK_1);
    respondWith('/submissions', { student_ids: STUDENT_IDS.slice(2, 3) }, 200, { Link: '' }, SUBMISSIONS_CHUNK_2);

    const pages = [];
    function saveSubmissions (submissions) {
      pages.push(submissions);
    }

    const dataLoader = callLoadGradebookData({ submissionsChunkCb: saveSubmissions });
    const resolve = assert.async();

    dataLoader.gotSubmissions.then(() => {
      strictEqual(pages.length, 2, 'two pages of submissions were returned');
      deepEqual(pages[0], SUBMISSIONS_CHUNK_1);
      deepEqual(pages[1], SUBMISSIONS_CHUNK_2);
      resolve();
    });
  });

  QUnit.only('requests submissions with pagination', function (assert) {
    respondWith('/courses/1201/gradebook/user_ids', {}, 200, {}, { user_ids: STUDENT_IDS });
    respondWith('/students', { user_ids: STUDENT_IDS }, 200, {}, STUDENTS_PAGE_1.concat(STUDENTS_PAGE_2));
    const responseHeaders = { Link: '</submissions&page=2>; rel="last"' };
    respondWith('/submissions', { student_ids: STUDENT_IDS }, 200, responseHeaders, SUBMISSIONS_CHUNK_1);
    respondWith('/submissions', { page: '2', student_ids: STUDENT_IDS }, 200, { Link: '' }, SUBMISSIONS_CHUNK_2);

    const pages = [];
    function saveSubmissions (submissions) {
      pages.push(submissions);
    }

    const dataLoader = callLoadGradebookData({ perPage: 50, submissionsChunkCb: saveSubmissions, submissionsChunkSize: 50 });
    const resolve = assert.async();

    dataLoader.gotSubmissions.then(() => {
      const submissionsRequests = XHRS.filter(xhr => xhr.url.match('/submissions'));
      strictEqual(submissionsRequests.length, 2, 'two requests for submissions were made');
      resolve();
    });
  });

  QUnit.module('Grading Period Assignments');

  test('resolves promise with data when grading period assignments are loaded', function (assert) {
    const responseData = { grading_period_assignments: GRADING_PERIOD_ASSIGNMENTS };
    respondWith('/courses/1201/gradebook/grading_period_assignments', {}, 200, {}, responseData);

    const dataLoader = callLoadGradebookData({ getGradingPeriodAssignments: true });
    const resolve = assert.async();

    dataLoader.gotGradingPeriodAssignments.then((data) => {
      deepEqual(data, responseData);
      resolve();
    });
  });

  test('optionally does not request grading period assignments', function () {
    const responseData = { grading_period_assignments: GRADING_PERIOD_ASSIGNMENTS };
    respondWith('/courses/1201/gradebook/grading_period_assignments', {}, 200, {}, responseData);

    const dataLoader = callLoadGradebookData();

    equal(typeof dataLoader.gotGradingPeriodAssignments, 'undefined');
  });

  QUnit.module('Custom Columns');

  test('requests custom columns using the given url', function () {
    respondWith('/customcols', {}, 200, { Link: '' }, CUSTOM_COLUMNS_PAGE_1);

    callLoadGradebookData();

    const userIdsRequests = XHRS.filter(xhr => xhr.url.match('/customcols'));
    strictEqual(userIdsRequests.length, 1, 'one request for custom columns was made');
  });

  test('includes hidden columns when requesting custom columns', function (assert) {
    respondWith('/customcols', {}, 200, { Link: '' }, CUSTOM_COLUMNS_PAGE_1);

    const dataLoader = callLoadGradebookData();
    const resolve = assert.async();

    dataLoader.gotCustomColumns.then(() => {
      const request = XHRS.find(xhr => xhr.url.match('/customcols'));
      const params = qs.parse(request.url.split('?')[1]);
      equal(params.include_hidden, 'true');
      resolve();
    });
  });

  test('requests all paginated pages of custom columns', function (assert) {
    respondWith('/customcols', {}, 200, { Link: '</customcols&page=2>; rel="last"' }, CUSTOM_COLUMNS_PAGE_1);
    respondWith('/customcols', { page: '2' }, 200, { Link: '' }, CUSTOM_COLUMNS_PAGE_2);

    const dataLoader = callLoadGradebookData();
    const resolve = assert.async();

    dataLoader.gotCustomColumns.then(() => {
      const requests = XHRS.filter(xhr => xhr.url.match('/customcols'));
      strictEqual(requests.length, 2);
      resolve();
    });
  });

  test('resolves promise with custom columns', function (assert) {
    respondWith('/customcols', {}, 200, { Link: '' }, CUSTOM_COLUMNS_PAGE_1);

    const resolve = assert.async();
    const dataLoader = callLoadGradebookData();

    dataLoader.gotCustomColumns.then((cols) => {
      deepEqual(cols, CUSTOM_COLUMNS_PAGE_1);
      resolve();
    });
  });

  test("doesn't fetch custom column data until all other data is done", function (assert) {
    respondWith('/customcols', {}, 200, { Link: '' }, CUSTOM_COLUMNS_PAGE_1);

    const done = assert.async();
    const dataLoader = callLoadGradebookData();

    dataLoader.gotCustomColumns.then(() => {
      strictEqual(XHRS.filter(xhr => xhr.url.match(/data/)).length, 0, 'custom columns for other data to finish');

      dataLoader.gotSubmissions.resolve();

      setTimeout(() => {
        strictEqual(XHRS.filter(xhr => xhr.url.match(/data/)).length, 2);
        done();
      });
    });
  });

  test('requests custom column data for the given column ids', function (assert) {
    const done = assert.async();
    const dataLoader = callLoadGradebookData({ customColumnIds: ['2401', '2402'] });

    dataLoader.gotSubmissions.resolve();

    setTimeout(() => {
      const urls = XHRS.filter(xhr => xhr.url.match(/data/)).map(xhr => xhr.url);
      const expectedUrls = [
        '/customcols/2401/data?custom_column_data_params=...',
        '/customcols/2402/data?custom_column_data_params=...'
      ];
      deepEqual(urls, expectedUrls);
      done();
    });
  });
});
