#
# Copyright (C) 2013 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#
require [
  'compiled/collections/AssignmentGroupCollection'
  'compiled/models/Course'
  'compiled/views/assignments/AssignmentGroupListView'
  'compiled/views/assignments/CreateGroupView'
  'compiled/views/assignments/IndexView'
  'compiled/views/assignments/AssignmentSettingsView'
  'compiled/views/assignments/AssignmentGroupWeightsView'
  'compiled/views/assignments/ToggleShowByView'
  'underscore'
], (AssignmentGroupCollection, Course, AssignmentGroupListView,
  CreateGroupView, IndexView, AssignmentSettingsView,
  AssignmentGroupWeightsView, ToggleShowByView, _) ->

  course = new Course
  course.url = ENV.URLS.course_url
  course.fetch()

  includes = ["assignments", "discussion_topic"]
  if ENV.PERMISSIONS.manage
    includes.push "all_dates"
    includes.push "module_ids"
  # observers
  else if !_.include(ENV.current_user_roles, "student")
    includes.push "all_dates"

  assignmentGroups = new AssignmentGroupCollection [],
    course: course
    params:
      include: includes
      override_assignment_dates: !ENV.PERMISSIONS.manage
    courseSubmissionsURL: ENV.URLS.course_student_submissions_url

  assignmentGroupsView = new AssignmentGroupListView
    collection: assignmentGroups
    sortURL: ENV.URLS.sort_url
    assignment_sort_base_url: ENV.URLS.assignment_sort_base_url
    course: course

  assignmentSettingsView = false
  createGroupView = false
  showByView = false
  indexEl = if window.location.href.indexOf('assignments') == -1
    '#course_home_content'
  else
    "#content"

  if ENV.PERMISSIONS.manage
    assignmentSettingsView = new AssignmentSettingsView
      model: course
      assignmentGroups: assignmentGroups
      weightsView: AssignmentGroupWeightsView

    createGroupView = new CreateGroupView
      assignmentGroups: assignmentGroups
      course: course
  else
    showByView = new ToggleShowByView
      course: course
      assignmentGroups: assignmentGroups


  app = new IndexView
    el: indexEl
    assignmentGroupsView: assignmentGroupsView
    assignmentSettingsView: assignmentSettingsView
    createGroupView: createGroupView
    showByView: showByView
    collection: assignmentGroups

  app.render()

  # kick it all off
  assignmentGroups.fetch(reset: true).then ->
    if ENV.PERMISSIONS.manage
      assignmentGroups.loadModuleNames()
    else
      assignmentGroups.getGrades()
