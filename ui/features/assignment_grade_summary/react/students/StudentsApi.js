/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import parseLinkHeader from 'link-header-parsing/parseLinkHeaderFromAxios'

const STUDENTS_PER_PAGE = 50

function normalizeStudentPage(data) {
  const students = []
  const provisionalGrades = []

  data.forEach(studentDatum => {
    const studentId = studentDatum.id || studentDatum.anonymous_id

    students.push({
      displayName: studentDatum.display_name || null,
      id: studentId,
    })

    studentDatum.provisional_grades.forEach(gradeDatum => {
      provisionalGrades.push({
        grade: gradeDatum.grade,
        graderId: gradeDatum.scorer_id || gradeDatum.anonymous_grader_id,
        id: gradeDatum.provisional_grade_id,
        score: gradeDatum.score,
        selected: studentDatum.selected_provisional_grade_id === gradeDatum.provisional_grade_id,
        studentId,
      })
    })
  })

  return {provisionalGrades, students}
}

function getAllStudentsPages(url, callbacks) {
  axios
    .get(url)
    .then(response => {
      callbacks.onPageLoaded(normalizeStudentPage(response.data))
      const linkHeaders = parseLinkHeader(response)
      if (linkHeaders.next) {
        getAllStudentsPages(linkHeaders.next, callbacks)
      } else {
        callbacks.onAllPagesLoaded()
      }
    })
    .catch(response => {
      callbacks.onFailure(response)
    })
}

export function loadStudents(courseId, assignmentId, callbacks) {
  const queryParams = `include[]=provisional_grades&allow_new_anonymous_id=true&per_page=${STUDENTS_PER_PAGE}`
  const url = `/api/v1/courses/${courseId}/assignments/${assignmentId}/gradeable_students?${queryParams}`

  getAllStudentsPages(url, callbacks)
}
