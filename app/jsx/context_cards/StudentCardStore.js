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

import axios from 'axios'

const tag = 'STUDENT_CONTEXT_CARDS=1'

class StudentCardStore {
  constructor(studentId, courseId) {
    this.studentId = studentId
    this.courseId = courseId
    this.state = {
      loading: true,
      user: {},
      course: {},
      submissions: [],
      analytics: null,
      permissions: {
        manage_grades: false,
        send_messages: false,
        view_all_grades: false,
        view_analytics: false,
        become_user: false
      }
    }
  }

  getState() {
    return this.state
  }

  load() {
    Promise.all([
      this.loadCourse(this.courseId),
      this.loadUser(this.studentId, this.courseId),
      this.loadAnalytics(this.studentId, this.courseId),
      this.loadRecentlyGradedSubmissions(this.studentId, this.courseId),
      this.loadPermissions(this.courseId)
    ]).then(() => this.setState({loading: false}))
  }

  loadPermissions(courseId) {
    const permissions = Object.keys(this.state.permissions)
      .map(permission => `permissions[]=${permission}`)
      .join('&')

    return axios
      .get(`/api/v1/courses/${courseId}/permissions?${tag}&${permissions}`)
      .then(response => this.setState({permissions: response.data}))
      .catch(() => {})
  }

  loadCourse(courseId) {
    return axios
      .get(`/api/v1/courses/${courseId}?${tag}&include[]=sections`)
      .then(response => this.setState({course: response.data}))
      .catch(() => {})
  }

  loadUser(studentId, courseId) {
    const includes = [
      'avatar_url',
      'enrollments',
      'inactive_enrollments',
      'current_grading_period_scores'
    ]
    const includesQuery = includes.join('&include[]=')
    return axios
      .get(`/api/v1/courses/${courseId}/users/${studentId}?${tag}&include[]=${includesQuery}`)
      .then(response => this.setState({user: response.data}))
      .catch(() => {})
  }

  loadAnalytics(studentId, courseId) {
    return axios
      .get(`/api/v1/courses/${courseId}/analytics/student_summaries?${tag}&student_id=${studentId}`)
      .then(response => this.setState({analytics: response.data[0] || {}}))
      .catch(() => {})
  }

  MAX_SUBMISSIONS = 10

  loadRecentlyGradedSubmissions(studentId, courseId) {
    return axios
      .get(
        `/api/v1/courses/${courseId}/students/submissions?${tag}&student_ids[]=${studentId}&order=graded_at&order_direction=descending&include[]=assignment&per_page=20`
      )
      .then(result => {
        const submissions = result.data.filter(s => s.grade != null).slice(0, this.MAX_SUBMISSIONS)
        this.setState({submissions})
      })
      .catch(() => {})
  }

  setState(newState) {
    this.state = {...this.state, ...newState}
    if (typeof this.onChange === 'function') {
      this.onChange(this.state)
    }
  }
}

export default StudentCardStore
