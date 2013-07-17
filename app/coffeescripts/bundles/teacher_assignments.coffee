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
  'compiled/views/CollectionView'
  'compiled/views/InputFilterView'
  'compiled/views/assignments/AssignmentGroupListItemView'
  'compiled/views/assignments/CreateGroupView'
  'compiled/views/assignments/TeacherIndexView'
  'compiled/views/assignments/AssignmentSettingsView'
  'compiled/views/assignments/AssignmentGroupWeightsView'
  'jst/assignments/teacher_index/AssignmentGroupList'

], (AssignmentGroupCollection, Course, CollectionView, InputFilterView, AssignmentGroupListItemView, CreateGroupView, TeacherIndexView, AssignmentSettingsView, AssignmentGroupWeightsView, assignmentGroupsTemplate) ->

  course = new Course
  course.url = ENV.COURSE_URL
  course.fetch()

  assignmentGroups = new AssignmentGroupCollection [],
    course: course
  assignmentGroups.fetch() # TODO: reset this instead

  assignmentSettingsView = new AssignmentSettingsView
    model: course
    assignmentGroups: assignmentGroups
    weightsView: AssignmentGroupWeightsView

  inputFilterView = new InputFilterView
    collection: assignmentGroups

  assignmentGroupsView = new CollectionView
    template: assignmentGroupsTemplate
    itemView: AssignmentGroupListItemView
    collection: assignmentGroups

  @app = new TeacherIndexView
    addAssignmentUrl: ENV.NEW_ASSIGNMENT_URL
    assignmentGroupsView: assignmentGroupsView
    inputFilterView: inputFilterView
    assignmentSettingsView: assignmentSettingsView
    createGroupView: new CreateGroupView
      assignmentGroups: assignmentGroups
      course: course

  @app.render()
