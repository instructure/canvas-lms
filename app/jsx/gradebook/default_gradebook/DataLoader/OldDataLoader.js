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

import {difference} from 'lodash'

import {deferPromise} from '../../../shared/async'

function getCustomColumns(courseId, dispatch) {
  const url = `/api/v1/courses/${courseId}/custom_gradebook_columns`
  return dispatch.getDepaginated(url, {include_hidden: true})
}

function getDataForColumn(courseId, columnId, options, perPageCallback, dispatch) {
  const url = `/api/v1/courses/${courseId}/custom_gradebook_columns/${columnId}/data`
  const augmentedCallback = data => perPageCallback(columnId, data)
  const params = {include_hidden: true, per_page: options.perPage}
  return dispatch.getDepaginated(url, params, augmentedCallback)
}

function getCustomColumnData(options, customColumnsDfd, dispatch) {
  const {courseId, gradebook} = options
  const perPageCallback = gradebook.gotCustomColumnDataChunk
  const customColumnDataLoaded = deferPromise()

  if (options.customColumnIds) {
    const customColumnDataDfds = options.customColumnIds.map(columnId =>
      getDataForColumn(courseId, columnId, options, perPageCallback, dispatch)
    )
    Promise.all(customColumnDataDfds).then(() => customColumnDataLoaded.resolve())
  } else {
    customColumnsDfd.then(customColumns => {
      const customColumnDataDfds = customColumns.map(column =>
        getDataForColumn(courseId, column.id, options, perPageCallback, dispatch)
      )
      Promise.all(customColumnDataDfds).then(() => customColumnDataLoaded.resolve())
    })
  }

  return customColumnDataLoaded.promise
}

function loadGradebookData(opts) {
  const {dataLoader, dispatch, gradebook} = opts

  const gotAssignmentGroups = opts.getAssignmentGroups
    ? dataLoader.assignmentGroupsLoader.loadAssignmentGroups()
    : null

  // Store currently-loaded student ids for diffing below.
  const loadedStudentIds = gradebook.courseContent.students.listStudentIds()

  // Begin loading Student IDs before any other data.
  const gotStudentIds = dataLoader.studentIdsLoader.loadStudentIds()

  let gotGradingPeriodAssignments
  if (opts.getGradingPeriodAssignments) {
    gotGradingPeriodAssignments = dataLoader.gradingPeriodAssignmentsLoader.loadGradingPeriodAssignments()
  }

  const gotCustomColumns = opts.getCustomColumns ? getCustomColumns(opts.courseId, dispatch) : null

  const gotContextModules = opts.getContextModules
    ? dataLoader.contextModulesLoader.loadContextModules()
    : null

  gotStudentIds
    .then(() => {
      const studentIds = gradebook.courseContent.students.listStudentIds()
      const studentIdsToLoad = difference(studentIds, loadedStudentIds)

      return dataLoader.studentContentDataLoader.load(studentIdsToLoad)
    })
    .then(() => {
      /*
       * Currently, custom columns data has the lowest priority for initial
       * data loading, so it waits until all students and submissions are
       * finished loading.
       */
      getCustomColumnData(opts, gotCustomColumns, dispatch)
    })

  return {
    gotAssignmentGroups,
    gotContextModules,
    gotCustomColumns,
    gotGradingPeriodAssignments,
    gotStudentIds
  }
}

export default {
  getDataForColumn,
  loadGradebookData
}
