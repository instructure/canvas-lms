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
  'compiled/views/InputFilterView'
  'compiled/views/assignments/AssignmentGroupListView'
  'compiled/views/assignments/CreateGroupView'
  'compiled/views/assignments/IndexView'
  'compiled/views/assignments/AssignmentSettingsView'
  'compiled/views/assignments/AssignmentGroupWeightsView'
], (AssignmentGroupCollection, Course, InputFilterView, AssignmentGroupListView, CreateGroupView, IndexView, AssignmentSettingsView, AssignmentGroupWeightsView) ->

  course = new Course
  course.url = ENV.URLS.course_url
  course.fetch()

  assignmentGroups = new AssignmentGroupCollection [],
    course: course
    modules: ENV.MODULES
    params:
      include: ["assignments"]
      override_assignment_dates: !ENV.PERMISSIONS.manage

  inputFilterView = new InputFilterView
    collection: assignmentGroups

  assignmentGroupsView = new AssignmentGroupListView
    collection: assignmentGroups

  assignmentSettingsView = false
  createGroupView = false

  if ENV.PERMISSIONS.manage
    assignmentSettingsView = new AssignmentSettingsView
      model: course
      assignmentGroups: assignmentGroups
      weightsView: AssignmentGroupWeightsView

    createGroupView = new CreateGroupView
      assignmentGroups: assignmentGroups
      course: course

  @app = new IndexView
    assignmentGroupsView: assignmentGroupsView
    inputFilterView: inputFilterView
    assignmentSettingsView: assignmentSettingsView
    createGroupView: createGroupView

  @app.render()

  # kick it all off
  assignmentGroups.fetch() # TODO: reset this instead
