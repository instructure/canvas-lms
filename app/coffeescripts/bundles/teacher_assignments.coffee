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
  'compiled/models/Assignment'
  'compiled/collections/AssignmentCollection'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/views/CollectionView'
  'compiled/views/InputFilterView'
  'jst/assignments/TeacherIndex'
  'jst/assignments/teacher_index/AssignmentGroupList'
  'jst/assignments/teacher_index/AssignmentGroupListItem'
  'jst/assignments/teacher_index/AssignmentListItem'
], (Backbone, Assignment, AssignmentCollection, AssignmentGroupCollection, CollectionView, InputFilterView, layoutTemplate, assignmentGroupsTemplate, assignmentGroupTemplate, assignmentTemplate) ->

  assignmentGroups = new AssignmentGroupCollection
  assignmentGroups.fetch() # TODO: reset this instead

  class EditableAssignmentIndexView extends Backbone.View

    template: layoutTemplate

    @child 'assignmentGroupsView', '[data-view=assignmentGroups]'

    @child 'inputFilterView', '[data-view=inputFilter]'

    @child 'createGroupView', '[data-view=createGroup]'

    @child 'createAssignmentView', '[data-view=createAssignment]'

    els:
      '#addGroup': '$addGroupButton'
      '#addAssignment': '$addAssignmentButton'

    afterRender: ->
      # child views so they get rendered automatically, need to stop it
      @createGroupView.hide()
      @createAssignmentView.hide()


  inputFilterView = new InputFilterView
    collection: assignmentGroups

  class AssignmentView extends Backbone.View
    tagName: "li"
    template: assignmentTemplate
    toJSON: -> @model.toView()

  class AssignmentGroupView extends CollectionView
    tagName: "li"
    itemView: AssignmentView
    template: assignmentGroupTemplate
    initialize: (options) ->
      @collection = new AssignmentCollection @model.get('assignments')
      super
    toJSON: -> @model.toJSON()

  assignmentGroupsView = new CollectionView
    template: assignmentGroupsTemplate
    itemView: AssignmentGroupView
    collection: assignmentGroups

  @app = new EditableAssignmentIndexView
    assignmentGroupsView: assignmentGroupsView
    inputFilterView: inputFilterView
    createGroupView: new Backbone.View
    createAssignmentView: new Backbone.View

  @app.render()
  @app.$el.appendTo $('#content')
