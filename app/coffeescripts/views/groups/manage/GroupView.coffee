#
# Copyright (C) 2013 - present Instructure, Inc.
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

define [
  'jquery'
  'Backbone'
  'jst/groups/manage/group'
  './GroupUsersView'
  './GroupDetailView'
  './GroupCategoryCloneView'
  '../../../util/groupHasSubmissions'
], ($, {View}, template, GroupUsersView, GroupDetailView, GroupCategoryCloneView, groupHasSubmissions) ->

  class GroupView extends View

    tagName: 'li'

    className: 'group'

    attributes: ->
      "data-id": @model.id

    template: template

    @optionProperty 'expanded'

    @optionProperty 'addUnassignedMenu'

    @child 'groupUsersView', '[data-view=groupUsers]'
    @child 'groupDetailView', '[data-view=groupDetail]'

    events:
      'click .toggle-group': 'toggleDetails'
      'click .add-user': 'showAddUser'
      'focus .add-user': 'showAddUser'
      'blur .add-user': 'hideAddUser'

    dropOptions:
      accept: '.group-user'
      activeClass: 'droppable'
      hoverClass: 'droppable-hover'
      tolerance: 'pointer'

    attach: ->
      @expanded = false
      @users = @model.users()
      @model.on 'destroy', @remove, this
      @model.on 'change:members_count', @updateFullState, this
      @model.on 'change:max_membership', @updateFullState, this

    afterRender: ->
      @$el.toggleClass 'group-expanded', @expanded
      @$el.toggleClass 'group-collapsed', !@expanded
      @groupDetailView.$toggleGroup.attr 'aria-expanded', '' + @expanded
      @updateFullState()

    updateFullState: ->
      return if @model.isLocked()
      if @model.isFull()
        @$el.droppable("destroy") if @$el.data('droppable')
        @$el.addClass('slots-full')
      else
        # enable droppable on the child GroupView (view)
        if !@$el.data('droppable')
          @$el.droppable(Object.assign({}, @dropOptions))
            .on('drop', @_onDrop)
        @$el.removeClass('slots-full')

    toggleDetails: (e) ->
      e.preventDefault()
      @expanded = not @expanded
      if @expanded and not @users.loaded
        @users.load(if @model.usersCount() then 'all' else 'none')
      @afterRender()

    showAddUser: (e) ->
      e.preventDefault()
      e.stopPropagation()
      $target = $(e.currentTarget)
      @addUnassignedMenu.group = @model
      @addUnassignedMenu.showBy $target, e.type is 'click'

    hideAddUser: (e) ->
      @addUnassignedMenu.hide()

    closeMenus: ->
      @groupDetailView.closeMenu()
      @groupUsersView.closeMenus()

    groupsAreDifferent: (user) =>
      !user.has('group') || (user.get('group').get("id") != @model.get("id"))

    eitherGroupHasSubmission: (user) =>
      (user.has('group') && groupHasSubmissions user.get('group')) || groupHasSubmissions @model

    isUnassignedUserWithSubmission: (user) =>
      !user.has('group') && user.has('group_submissions') && user.get('group_submissions').length > 0

    ##
    # handle drop events on a GroupView
    # e - Event object.
    #   e.currentTarget - group the user is dropped on
    # ui - jQuery UI object.
    #   ui.draggable - the user being dragged
    _onDrop: (e, ui) =>
      user = ui.draggable.data('model')
      diffGroupsWithSubmission = @groupsAreDifferent(user) && @eitherGroupHasSubmission(user)
      unassignedWithSubmission = @isUnassignedUserWithSubmission(user) && @model.usersCount() > 0

      if diffGroupsWithSubmission || unassignedWithSubmission
        @cloneCategoryView = new GroupCategoryCloneView
          model: @model.collection.category,
          openedFromCaution: true
        @cloneCategoryView.open()
        @cloneCategoryView.on "close", =>
          if @cloneCategoryView.cloneSuccess
            window.location.reload()
          else if @cloneCategoryView.changeGroups
            @moveUser(e, user)
      else
        @moveUser(e, user)

    moveUser: (e, user) ->
      newGroupId = $(e.currentTarget).data('id')
      setTimeout =>
        @model.collection.category.reassignUser(user, @model.collection.get(newGroupId))
