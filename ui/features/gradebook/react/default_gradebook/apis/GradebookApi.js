/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import axios from '@canvas/axios'
import I18n from 'i18n!gradebookGradebookApi'
import {underscore} from 'convert-case'

function applyScoreToUngradedSubmissions(courseId, params) {
  const url = `/api/v1/courses/${courseId}/apply_score_to_ungraded_submissions`
  return axios.put(url, underscore(params))
}

function createTeacherNotesColumn(courseId) {
  const url = `/api/v1/courses/${courseId}/custom_gradebook_columns`
  const data = {
    column: {
      position: 1,
      teacher_notes: true,
      title: I18n.t('Notes')
    }
  }
  return axios.post(url, data)
}

function updateTeacherNotesColumn(courseId, columnId, attr) {
  const url = `/api/v1/courses/${courseId}/custom_gradebook_columns/${columnId}`
  return axios.put(url, {column: attr})
}

function updateSubmission(courseId, assignmentId, userId, submission, enterGradesAs) {
  const url = `/api/v1/courses/${courseId}/assignments/${assignmentId}/submissions/${userId}`
  return axios.put(url, {
    submission: underscore(submission),
    include: ['visibility'],
    prefer_points_over_scheme: enterGradesAs === 'points'
  })
}

function saveUserSettings(courseId, gradebook_settings) {
  const url = `/api/v1/courses/${courseId}/gradebook_settings`
  return axios.put(url, {gradebook_settings})
}

function updateColumnOrder(courseId, columnOrder) {
  const url = `/courses/${courseId}/gradebook/save_gradebook_column_order`
  return axios.post(url, {column_order: columnOrder})
}

export default {
  applyScoreToUngradedSubmissions,
  createTeacherNotesColumn,
  saveUserSettings,
  updateColumnOrder,
  updateTeacherNotesColumn,
  updateSubmission
}
