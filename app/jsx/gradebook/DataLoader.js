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
import _ from 'underscore'

import cheaterDepaginate from '../shared/CheatDepaginator'
import NaiveRequestDispatch from '../gradezilla/default_gradebook/DataLoader/NaiveRequestDispatch'

function getGradingPeriodAssignments(courseId) {
  const url = `/courses/${courseId}/gradebook/grading_period_assignments`
  return $.ajaxJSON(url, 'GET', {})
}

// loaders
const getAssignmentGroups = (url, params, dispatch) => {
  return dispatch.getDepaginated(url, params)
}
const getCustomColumns = url => {
  return $.ajaxJSON(url, 'GET', {})
}
const getSections = url => {
  return $.ajaxJSON(url, 'GET', {})
}

// submission loading is tricky
let pendingStudentsForSubmissions
let submissionsLoaded
let studentsLoaded
let submissionChunkCount
let gotSubmissionChunkCount
let submissionsLoading = false
let submissionURL
let submissionParams
let submissionChunkSize
let submissionChunkCb

const gotSubmissionsChunk = data => {
  gotSubmissionChunkCount++
  submissionChunkCb(data)

  if (gotSubmissionChunkCount === submissionChunkCount && studentsLoaded.isResolved()) {
    submissionsLoaded.resolve()
  }
}

const getPendingSubmissions = dispatch => {
  while (pendingStudentsForSubmissions.length) {
    const studentIds = pendingStudentsForSubmissions.splice(0, submissionChunkSize)
    submissionChunkCount++
    dispatch.getDepaginated(submissionURL, {student_ids: studentIds, ...submissionParams}).then(
      gotSubmissionsChunk
    )
  }
}

const getSubmissions = (url, params, cb, chunkSize, dispatch) => {
  submissionURL = url
  submissionParams = params
  submissionChunkCb = cb
  submissionChunkSize = chunkSize

  submissionsLoaded = $.Deferred()
  submissionChunkCount = 0
  gotSubmissionChunkCount = 0

  submissionsLoading = true
  getPendingSubmissions(dispatch)
  return submissionsLoaded
}

const getStudents = (url, params, studentChunkCb, dispatch) => {
  pendingStudentsForSubmissions = []

  const gotStudentPage = students => {
    studentChunkCb(students)

    const studentIds = _.pluck(students, 'id')
    ;[].push.apply(pendingStudentsForSubmissions, studentIds)

    if (submissionsLoading) {
      getPendingSubmissions(dispatch)
    }
  }

  studentsLoaded = cheaterDepaginate(url, params, gotStudentPage)
  return studentsLoaded
}

const getDataForColumn = (column, url, params, cb) => {
  url = url.replace(/:id/, column.id)
  const augmentedCallback = data => cb(column, data)
  return cheaterDepaginate(url, params, augmentedCallback)
}

const getCustomColumnData = (url, params, cb, customColumnsDfd, waitForDfds) => {
  const customColumnDataLoaded = $.Deferred()
  let customColumnDataDfds

  // waitForDfds ensures that custom column data is loaded *last*
  $.when.apply($, waitForDfds).then(() => {
    customColumnsDfd.then(customColumns => {
      customColumnDataDfds = customColumns.map(col => getDataForColumn(col, url, params, cb))
    })
  })

  $.when.apply($, customColumnDataDfds).then(() => customColumnDataLoaded.resolve())

  return customColumnDataLoaded
}

const loadGradebookData = opts => {
  const dispatch = new NaiveRequestDispatch()

  const gotAssignmentGroups = getAssignmentGroups(
    opts.assignmentGroupsURL,
    opts.assignmentGroupsParams,
    dispatch
  )
  if (opts.onlyLoadAssignmentGroups) {
    return {gotAssignmentGroups}
  }

  let gotGradingPeriodAssignments
  if (opts.getGradingPeriodAssignments) {
    gotGradingPeriodAssignments = getGradingPeriodAssignments(opts.courseId)
  }
  const gotCustomColumns = getCustomColumns(opts.customColumnsURL)
  const gotStudents = getStudents(
    opts.studentsURL,
    opts.studentsParams,
    opts.studentsPageCb,
    dispatch
  )
  const gotSubmissions = getSubmissions(
    opts.submissionsURL,
    opts.submissionsParams,
    opts.submissionsChunkCb,
    opts.submissionsChunkSize,
    dispatch
  )
  const gotCustomColumnData = getCustomColumnData(
    opts.customColumnDataURL,
    opts.customColumnDataParams,
    opts.customColumnDataPageCb,
    gotCustomColumns,
    [gotSubmissions]
  )

  return {
    gotAssignmentGroups,
    gotCustomColumns,
    gotGradingPeriodAssignments,
    gotStudents,
    gotSubmissions,
    gotCustomColumnData
  }
}

export default {loadGradebookData: loadGradebookData, getDataForColumn: getDataForColumn}
