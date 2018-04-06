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

const course = new Course()
course.url = ENV.URLS.course_url
const courseFetch = course.fetch()

const includes = ['assignments', 'discussion_topic']
if (ENV.PERMISSIONS.manage) {
  includes.push('all_dates')
  includes.push('module_ids')
  // observers
} else if (ENV.current_user_has_been_observer_in_this_course) {
  includes.push('all_dates')
}

const userIsAdmin = _.contains(ENV.current_user_roles, 'admin')

const assignmentGroups = new AssignmentGroupCollection([], {
  course,
  params: {
    include: includes,
    exclude_response_fields: ['description', 'rubric'],
    override_assignment_dates: !ENV.PERMISSIONS.manage
  },
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
const indexEl = window.location.href.indexOf('assignments') === -1 ? '#course_home_content' : '#content'

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
Promise.all([
  courseFetch,
  assignmentGroups.fetch({reset: true})
]).then(() => {
  if (ENV.HAS_GRADING_PERIODS) { app.filterResults() }
  if (ENV.PERMISSIONS.manage) {
    assignmentGroups.loadModuleNames()
  } else {
    assignmentGroups.getGrades()
  }
})
