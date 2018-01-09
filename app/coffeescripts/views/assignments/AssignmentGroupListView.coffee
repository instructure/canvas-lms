#
# Copyright (C) 2011 - present Instructure, Inc.
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
  'jquery'
  'underscore'
  'Backbone'
  '../SortableCollectionView'
  './AssignmentGroupListItemView'
  'jst/assignments/AssignmentGroupList'
  'jst/assignments/NoAssignmentsListItem'
], ($, _, Backbone, SortableCollectionView, AssignmentGroupListItemView, template, NoAssignmentsListItem) ->

  class AssignmentGroupListView extends SortableCollectionView
    @optionProperty 'course'
    @optionProperty 'userIsAdmin'

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
        userIsAdmin: @userIsAdmin
      new @itemView $.extend {}, (@itemViewOptions || {}), {model}, options

    createReorderURL: (id) ->
      @assignment_sort_base_url + "/" + id + "/reorder"

    # TODO: make menu a child view of listitem so that it can be rendered
    # by itself, and so it can manage all of the dialog stuff,
    # when that happens, this can be removed
    attachCollection: ->
      super
      @itemViewOptions = course: @course
      @collection.on 'render', @render
      @collection.on 'add', @renderIfLoaded
      @collection.on 'remove', @render
      @collection.on 'change:groupWeights', @render

    renderIfLoaded: =>
      if @collection.loadedAll
        @render()

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

    handleExtraClick: (e) =>
      e.stopImmediatePropagation()
      $(e.target).off('click', @handleExtraClick)

    collapse: (e, ui) =>
      item = ui.item
      id = item.children(":first").attr('data-id')
      item.find("#assignment_group_#{id}_assignments").slideUp(100)
      ui.item.css("height", "auto")
      $toggler = item.find('.element_toggler').first()
      arrow = $toggler.find('i').first()
      arrow.removeClass('icon-mini-arrow-down').addClass('icon-mini-arrow-right')

    expand: (e, ui) =>
      item = ui.item
      $toggler = item.find('.element_toggler').first()
      # FF triggers an extra click when you drop the item, so we want to handle it here
      $toggler.on('click', @handleExtraClick)

      # remove the extra click handler for browsers that don't trigger the extra click
      setTimeout(=>
        $toggler.off('click', @handleExtraClick)
      , 50)

      id = item.children(":first").attr('data-id')
      ag = @collection.findWhere id: id
      if ag && ag.groupView.shouldBeExpanded()
        item.find("#assignment_group_#{id}_assignments").slideDown(100)
        arrow = $toggler.find('i').first()
        arrow.addClass('icon-mini-arrow-down').removeClass('icon-mini-arrow-right')
