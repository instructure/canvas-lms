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

import $ from 'jquery'
import cheaterDepaginate from '../shared/CheatDepaginator'
import StudentContentDataLoader from './default_gradebook/DataLoader/StudentContentDataLoader'

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

  const studentContentDataLoader = new StudentContentDataLoader({
    loadedStudentIds: opts.loadedStudentIds,
    onStudentsChunkLoaded: opts.studentsPageCb,
    onSubmissionsChunkLoaded: opts.submissionsChunkCb,
    studentsChunkSize: opts.perPage,
    studentsParams: opts.studentsParams,
    studentsUrl: opts.studentsURL,
    submissionsChunkSize: opts.submissionsChunkSize,
    submissionsUrl: opts.submissionsURL
  })

  const gotContextModules = getContextModules(opts.contextModulesURL);

  const gotStudents = $.Deferred()
  const gotSubmissions = $.Deferred()

  gotStudentIds.then(async data => {
    await studentContentDataLoader.load(data.user_ids)
    gotStudents.resolve()
    gotSubmissions.resolve()
  })

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
