/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import AssignmentGroupCollection from 'compiled/collections/AssignmentGroupCollection'
import Course from 'compiled/models/Course'
import AssignmentGroupListView from 'compiled/views/assignments/AssignmentGroupListView'
import CreateGroupView from 'compiled/views/assignments/CreateGroupView'
import IndexView from 'compiled/views/assignments/IndexView'
import AssignmentSettingsView from 'compiled/views/assignments/AssignmentSettingsView'
import AssignmentSyncSettingsView from 'compiled/views/assignments/AssignmentSyncSettingsView'
import AssignmentGroupWeightsView from 'compiled/views/assignments/AssignmentGroupWeightsView'
import ToggleShowByView from 'compiled/views/assignments/ToggleShowByView'
import _ from 'underscore'
import splitAssetString from 'compiled/str/splitAssetString'
import {getPrefetchedXHR} from '@instructure/js-utils'
import {monitorLtiMessages} from 'lti/messages'

const course = new Course({
  id: encodeURIComponent(splitAssetString(ENV.context_asset_string)[1]),
  apply_assignment_group_weights: ENV.apply_assignment_group_weights
})
course.url = ENV.URLS.course_url

const userIsAdmin = _.includes(ENV.current_user_roles, 'admin')

const assignmentGroups = new AssignmentGroupCollection([], {
  course,
  courseSubmissionsURL: ENV.URLS.course_student_submissions_url
})

const assignmentGroupsView = new AssignmentGroupListView({
  collection: assignmentGroups,
  sortURL: ENV.URLS.sort_url,
  assignment_sort_base_url: ENV.URLS.assignment_sort_base_url,
  course,
  userIsAdmin
})

let assignmentSettingsView = false
let assignmentSyncSettingsView = false
let createGroupView = false
let showByView = false
const indexEl =
  window.location.href.indexOf('assignments') === -1 ? '#course_home_content' : '#content'

if (ENV.PERMISSIONS.manage_assignments) {
  assignmentSettingsView = new AssignmentSettingsView({
    model: course,
    assignmentGroups,
    weightsView: AssignmentGroupWeightsView,
    userIsAdmin
  })

  assignmentSyncSettingsView = new AssignmentSyncSettingsView({
    collection: assignmentGroups,
    model: course,
    sisName: ENV.SIS_NAME
  })

  createGroupView = new CreateGroupView({
    assignmentGroups,
    course,
    userIsAdmin
  })
} else {
  showByView = new ToggleShowByView({
    course,
    assignmentGroups
  })
}

const app = new IndexView({
  el: indexEl,
  assignmentGroupsView,
  assignmentSettingsView,
  assignmentSyncSettingsView,
  createGroupView,
  showByView,
  collection: assignmentGroups
})

app.render()

// kick it all off
course.trigger('change')
getPrefetchedXHR('assignment_groups_url')
  .then(res =>
    res.json().then(data => {
      // we have to do things a little different than a normal paginatedCollection
      // because we used prefetch_xhr to prefetch the first page of assignment_groups
      // but we still want the rest of the pages (if any) to be fetched like any
      // other paginatedCollection would.
      assignmentGroups.reset(data)
      const mockJqXHR = {getResponseHeader: h => res.headers.get(h)}
      assignmentGroups._setStateAfterFetch(mockJqXHR, {})
      if (!assignmentGroups.loadedAll) {
        return assignmentGroups.fetch({page: 'next'})
      }
    })
  )
  .then(() => {
    if (ENV.HAS_GRADING_PERIODS) {
      app.filterResults()
    }
    if (ENV.PERMISSIONS.manage) {
      assignmentGroups.loadModuleNames()
    } else {
      assignmentGroups.getGrades()
    }
  })

monitorLtiMessages()
