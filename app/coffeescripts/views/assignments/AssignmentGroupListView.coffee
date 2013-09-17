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
define [
  'underscore'
  'Backbone'
  'compiled/views/SortableCollectionView'
  'compiled/views/assignments/AssignmentGroupListItemView'
  'jst/assignments/AssignmentGroupList'
  'jst/assignments/NoAssignmentsListItem'
], (_, Backbone, SortableCollectionView, AssignmentGroupListItemView, template, NoAssignmentsListItem) ->

  class AssignmentGroupListView extends SortableCollectionView
    @optionProperty 'course'

    template: template
    itemView: AssignmentGroupListItemView

    @optionProperty 'assignment_sort_base_url'

    render: =>
      super(ENV.PERMISSIONS.manage)

    renderItem: (model) =>
      view = super
      model.groupView.collapseIfNeeded()
      view

    createItemView: (model) ->
      options =
        parentCollection: @collection
        childKey: 'assignments'
        groupKey: 'assignment_group_id'
        groupId: model.id
        reorderURL: @createReorderURL(model.id)
        noItemTemplate: NoAssignmentsListItem
      new @itemView $.extend {}, (@itemViewOptions || {}), {model}, options

    createReorderURL: (id) ->
      @assignment_sort_base_url + "/" + id + "/reorder"


    # TODO: make menu a child view of listitem so that it can be rendered
    # by itself, and so it can manage all of the dialog stuff,
    # when that happens, this can be removed
    attachCollection: ->
      super
      @itemViewOptions = course: @course
      @collection.on 'add', @render
      @collection.on 'remove', @render

    renderOnReset: =>
      @firstResetLanded = true
      super

    toJSON: ->
      data = super
      _.extend({}, data,
        firstResetLanded: @firstResetLanded
      )

    _initSort: ->
      super
      @$list.on('sortstart', @collapse)
      @$list.on('sortstop', @expand)

    collapse: (e, ui) =>
      id = ui.item.children(":first").data('id')
      ui.item.find("#assignment_group_#{id}_assignments").slideUp(100)
      ui.item.css("height", "auto")

    expand: (e, ui) =>
      id = ui.item.children(":first").data('id')
      ag = @collection.findWhere id: parseInt(id)
      if ag && ag.groupView.shouldBeExpanded()
        ui.item.find("#assignment_group_#{id}_assignments").slideDown(100)
