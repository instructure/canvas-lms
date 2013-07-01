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
  'Backbone'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/views/CollectionView'
  'compiled/views/InputFilterView'
  'compiled/views/assignments/AssignmentGroupListItemView'
  'compiled/views/assignments/TeacherIndexView'
  'jst/assignments/teacher_index/AssignmentGroupList'
], (Backbone, AssignmentGroupCollection, CollectionView, InputFilterView, AssignmentGroupListItemView, TeacherIndexView, assignmentGroupsTemplate) ->

  assignmentGroups = new AssignmentGroupCollection
  assignmentGroups.fetch() # TODO: reset this instead

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
    createGroupView: new Backbone.View

  @app.render()
  @app.$el.appendTo $('#content')
