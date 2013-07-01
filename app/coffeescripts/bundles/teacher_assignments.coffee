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
  'underscore'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/models/Course'
  'compiled/views/CollectionView'
  'compiled/views/InputFilterView'
  'compiled/views/assignments/AssignmentGroupListItemView'
  'compiled/views/assignments/TeacherIndexView'
  'compiled/views/assignments/AssignmentSettingsView'
  'compiled/views/assignments/AssignmentGroupWeightsView'
  'jst/assignments/teacher_index/AssignmentGroupList'
], (_, AssignmentGroupCollection, Course, CollectionView, InputFilterView, AssignmentGroupListItemView, TeacherIndexView, AssignmentSettingsView, AssignmentGroupWeightsView, assignmentGroupsTemplate) ->

  assignmentGroups = new AssignmentGroupCollection
  assignmentGroups.fetch() # TODO: reset this instead

  course = new Course
  course.url = ENV.COURSE_URL
  course.fetch()

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
    createGroupView: new Backbone.View

  @app.render()
  @app.$el.appendTo $('#content')
