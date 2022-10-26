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

import axios from '@canvas/axios'
import parseLinkHeader from 'link-header-parsing/parseLinkHeaderFromAxios'
import MigrationStates from './migrationStates'

const ApiClient = {
  _depaginate(url, maxPages = Infinity, allResults = []) {
    return axios.get(url).then(res => {
      const results = allResults.concat(res.data)
      const remainingPages = maxPages - 1
      if (res.headers.link && remainingPages > 0) {
        const links = parseLinkHeader(res)
        if (links.next) {
          return this._depaginate(links.next, remainingPages, results)
        }
      }
      res.data = results
      return res
    })
  },

  _queryString(params) {
    return params
      .map(param => {
        const key = Object.keys(param)[0]
        const value = param[key]
        return value ? `${key}=${value}` : null
      })
      .filter(param => !!param)
      .join('&')
  },

  getCourses({accountId}, {search = '', term = '', subAccount = ''} = {}) {
    const params = this._queryString([
      {per_page: '100'},
      {blueprint: 'false'},
      {blueprint_associated: 'false'},
      {'include[]': 'term'},
      {'include[]': 'teachers'},
      {teacher_limit: '5'},
      {search_term: search},
      {enrollment_term_id: term},
    ])

    return this._depaginate(`/api/v1/accounts/${subAccount || accountId}/courses?${params}`, 1)
  },

  getAssociations({masterCourse}) {
    const params = this._queryString([{per_page: '100'}, {teacher_limit: '5'}])

    return this._depaginate(
      `/api/v1/courses/${masterCourse.id}/blueprint_templates/default/associated_courses?${params}`
    )
  },

  saveAssociations({masterCourse, addedAssociations, removedAssociations}) {
    return axios.put(
      `/api/v1/courses/${masterCourse.id}/blueprint_templates/default/update_associations`,
      {
        course_ids_to_add: addedAssociations.map(c => c.id),
        course_ids_to_remove: removedAssociations.map(c => c.id),
      }
    )
  },

  getMigrations({masterCourse}) {
    return axios.get(`/api/v1/courses/${masterCourse.id}/blueprint_templates/default/migrations`)
  },

  beginMigration({
    masterCourse,
    willSendNotification,
    willIncludeCustomNotificationMessage,
    notificationMessage,
    willIncludeCourseSettings,
    willPublishCourses,
  }) {
    const params = {
      send_notification: willSendNotification,
    }
    if (willIncludeCourseSettings) {
      params.copy_settings = true // don't send parameter if not checked
    }
    if (willIncludeCustomNotificationMessage && notificationMessage) {
      params.comment = notificationMessage
    }
    if (willPublishCourses) {
      params.publish_after_initial_sync = true
    }
    return axios.post(
      `/api/v1/courses/${masterCourse.id}/blueprint_templates/default/migrations`,
      params
    )
  },

  checkMigration(state) {
    return this.getMigrations(state).then(res => {
      let status = MigrationStates.void

      if (res.data[0]) {
        status = res.data[0].workflow_state
      }

      res.data = status
      return res
    })
  },

  getMigration(
    {course},
    {blueprintType = 'blueprint_templates', templateId = 'default', changeId}
  ) {
    return axios.get(
      `/api/v1/courses/${course.id}/${blueprintType}/${templateId}/migrations/${changeId}`
    )
  },

  getMigrationDetails(
    {course},
    {blueprintType = 'blueprint_templates', templateId = 'default', changeId}
  ) {
    return axios.get(
      `/api/v1/courses/${course.id}/${blueprintType}/${templateId}/migrations/${changeId}/details`
    )
  },

  getFullMigration({course}, params) {
    return this.getMigration({course}, params).then(({data}) =>
      this.getMigrationDetails({course}, params).then(res =>
        Object.assign(data, {
          changeId: params.changeId,
          changes: res.data,
        })
      )
    )
  },

  getSyncHistory({masterCourse}) {
    return this.getMigrations({masterCourse}).then(({data}) =>
      Promise.all(
        // limit to last 5 migrations
        data
          .slice(0, 5)
          .map(mig =>
            this.getMigrationDetails({course: masterCourse}, {changeId: mig.id}).then(res =>
              Object.assign(mig, {changes: res.data})
            )
          )
      )
    )
  },

  toggleLocked({courseId, itemType, itemId, isLocked}) {
    return axios.put(`/api/v1/courses/${courseId}/blueprint_templates/default/restrict_item`, {
      content_type: itemType,
      content_id: itemId,
      restricted: isLocked,
    })
  },

  loadUnsyncedChanges({masterCourse}) {
    return axios.get(
      `/api/v1/courses/${masterCourse.id}/blueprint_templates/default/unsynced_changes`
    )
  },
}

export default ApiClient
