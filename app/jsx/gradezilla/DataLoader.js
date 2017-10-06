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

import $ from 'jquery';
import cheaterDepaginate, { consumePagesInOrder } from 'jsx/shared/CheatDepaginator';
import _ from 'lodash';

const submissionsParams = {
  exclude_response_fields: ['preview_url'],
  response_fields: [
    'id', 'user_id', 'url', 'score', 'grade', 'submission_type', 'submitted_at', 'assignment_id',
    'grade_matches_current_submission', 'attachments', 'late', 'missing', 'workflow_state', 'excused',
    'points_deducted', 'seconds_late', 'cached_due_date', 'entered_score', 'entered_grade', 'grading_period_id'
  ]
};

let pendingStudentsForSubmissions;
let submissionsLoaded;
let studentsLoaded;
let submissionChunkCount;
let gotSubmissionChunkCount;
let submissionsLoading = false;
let submissionURL;
let submissionChunkSize;
let submissionChunkCb;

function getStudentIds (courseId) {
  const url = `/courses/${courseId}/gradebook/user_ids`;
  return $.ajaxJSON(url, 'GET', {});
}

function getGradingPeriodAssignments (courseId) {
  const url = `/courses/${courseId}/gradebook/grading_period_assignments`;
  return $.ajaxJSON(url, 'GET', {});
}

function getAssignmentGroups (url, params) {
  return cheaterDepaginate(url, params);
}

function getContextModules (url) {
  return cheaterDepaginate(url);
}

function getCustomColumns (url) {
  return cheaterDepaginate(url, { include_hidden: true });
}

function gotSubmissionsChunk (data) {
  gotSubmissionChunkCount++;
  submissionChunkCb(data);

  if (gotSubmissionChunkCount === submissionChunkCount && studentsLoaded.isResolved()) {
    submissionsLoaded.resolve();
  }
}

function getPendingSubmissions () {
  while (pendingStudentsForSubmissions.length) {
    const studentIds = pendingStudentsForSubmissions.splice(0, submissionChunkSize);
    submissionChunkCount++;
    $.ajaxJSON(
      submissionURL,
      'GET',
      { student_ids: studentIds, ...submissionsParams },
      gotSubmissionsChunk
    );
  }
}

function getSubmissions (url, cb, chunkSize) {
  submissionURL = url;
  submissionChunkCb = cb;
  submissionChunkSize = chunkSize;

  submissionsLoaded = $.Deferred();
  submissionChunkCount = 0;
  gotSubmissionChunkCount = 0;

  submissionsLoading = true;
  getPendingSubmissions();
  return submissionsLoaded;
}

function getStudents (options, gotStudentIds) {
  const url = options.studentsURL;
  const params = options.studentsParams;
  const studentChunkCb = options.studentsPageCb;

  pendingStudentsForSubmissions = [];
  studentsLoaded = $.Deferred();

  const gotStudentPage = (students) => {
    studentChunkCb(students);

    const studentIds = _.map(students, 'id');
    [].push.apply(pendingStudentsForSubmissions, studentIds);

    if (submissionsLoading) {
      getPendingSubmissions();
    }
  };

  const studentData = [];
  const pageCallback = consumePagesInOrder(gotStudentPage, studentData);

  function getStudentPage (studentIds, page) {
    return $.ajaxJSON(
      url,
      'GET',
      { ...params, per_page: options.perPage, user_ids: studentIds },
      (response) => { pageCallback(response, page) }
    );
  }

  gotStudentIds.then((data) => {
    const loadedStudentIds = options.loadedStudentIds || [];
    const allStudentIds = data.user_ids;

    const studentIdsToLoad = _.difference(allStudentIds, loadedStudentIds);

    if (studentIdsToLoad.length === 0) {
      studentsLoaded.resolve([]);
      submissionsLoaded.resolve([]);
    }

    const studentIdChunks = _.chunk(studentIdsToLoad, options.perPage);
    const studentRequests = studentIdChunks.map((studentIds, chunkIndex) => (
      getStudentPage(studentIds, chunkIndex + 1) // `page is 1-based index`
    ));

    $.when(...studentRequests)
      .then(() => {
        studentsLoaded.resolve(studentData);
      })
      .fail(() => {
        studentsLoaded.reject();
      });
  });

  return studentsLoaded;
}

function getDataForColumn (columnId, url, params, cb) {
  const columnUrl = url.replace(/:id/, columnId);
  const augmentedCallback = data => cb(columnId, data);
  return cheaterDepaginate(columnUrl, params, augmentedCallback);
}

function getCustomColumnData (options, customColumnsDfd, waitForDfds) {
  const url = options.customColumnDataURL;
  const params = options.customColumnDataParams;
  const cb = options.customColumnDataPageCb;
  const customColumnDataLoaded = $.Deferred();

  if (url) {
    // waitForDfds ensures that custom column data is loaded *last*
    $.when(...waitForDfds).then(() => {
      if (options.customColumnIds) {
        const customColumnDataDfds = options.customColumnIds.map(columnId => getDataForColumn(columnId, url, params, cb));
        $.when(...customColumnDataDfds).then(() => customColumnDataLoaded.resolve());
      } else {
        customColumnsDfd.then((customColumns) => {
          const customColumnDataDfds = customColumns.map(col => getDataForColumn(col.id, url, params, cb));
          $.when(...customColumnDataDfds).then(() => customColumnDataLoaded.resolve());
        });
      }
    });
  }

  return customColumnDataLoaded;
}

function loadGradebookData (opts) {
  const gotAssignmentGroups = getAssignmentGroups(opts.assignmentGroupsURL, opts.assignmentGroupsParams);
  if (opts.onlyLoadAssignmentGroups) {
    return { gotAssignmentGroups };
  }

  // Begin loading Students before any other data.
  const gotStudentIds = getStudentIds(opts.courseId);
  let gotGradingPeriodAssignments;
  if (opts.getGradingPeriodAssignments) {
    gotGradingPeriodAssignments = getGradingPeriodAssignments(opts.courseId);
  }
  const gotCustomColumns = getCustomColumns(opts.customColumnsURL);
  const gotStudents = getStudents(opts, gotStudentIds);
  const gotContextModules = getContextModules(opts.contextModulesURL);
  const gotSubmissions = getSubmissions(opts.submissionsURL, opts.submissionsChunkCb, opts.submissionsChunkSize);

  // Custom Column Data will load only after custom columns and all submissions.
  const gotCustomColumnData = getCustomColumnData(opts, gotCustomColumns, [gotSubmissions]);

  return {
    gotAssignmentGroups,
    gotContextModules,
    gotCustomColumns,
    gotGradingPeriodAssignments,
    gotStudentIds,
    gotStudents,
    gotSubmissions,
    gotCustomColumnData
  };
}

export default {
  getDataForColumn,
  loadGradebookData
};
