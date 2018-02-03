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
  'i18n!GroupUsersView'
  'jquery'
  'jsx/move_item'
  '../../../collections/GroupCollection'
  '../../PaginatedCollectionView'
  './GroupUserView'
  './GroupCategoryCloneView'
  'jst/groups/manage/groupUsers'
  '../../../util/groupHasSubmissions'
  'jqueryui/draggable'
  'jqueryui/droppable'
], (I18n, $, MoveItem, GroupCollection, PaginatedCollectionView, GroupUserView, GroupCategoryCloneView, template, groupHasSubmissions) ->

  class GroupUsersView extends PaginatedCollectionView

    defaults: Object.assign {},
      PaginatedCollectionView::defaults,
      itemView: GroupUserView
      itemViewOptions:
        canAssignToGroup: false
        canEditGroupAssignment: true
        markInactiveStudents: false

    dragOptions:
      appendTo: 'body'
      helper: 'clone'
      opacity: 0.75
      refreshPositions: true
      revert: 'invalid'
      revertDuration: 150
      start: (event, ui) ->
        # hide AssignToGroupMenu (original and helper)
        $('.assign-to-group-menu').hide()

    initialize: ->
      super
      @detachScroll() if @collection.loadAll

    template: template

    attach: ->
      @model.on 'change:members_count', @render
      @model.on 'change:leader', @render
      @collection.on 'moved', @highlightUser

    highlightUser: (user) ->
      user.itemView.highlight()

    closeMenus: ->
      for model in @collection.models
        model.itemView.closeMenu()

    events:
      'click .remove-from-group': 'removeUserFromGroup'
      'click .remove-as-leader': 'removeLeader'
      'click .set-as-leader': 'setLeader'
      'click .edit-group-assignment': 'editGroupAssignment'

    removeUserFromGroup: (e) ->
      e.preventDefault()
      e.stopPropagation()
      $target = $(e.currentTarget)
      user = @collection.getUser($target.data('user-id'))

      if groupHasSubmissions @model
        @cloneCategoryView = new GroupCategoryCloneView
          model: @model.collection.category,
          openedFromCaution: true
        @cloneCategoryView.open()
        @cloneCategoryView.on "close", =>
          if @cloneCategoryView.cloneSuccess
            window.location.reload()
          else if @cloneCategoryView.changeGroups
            @removeUser(e, $target)
          else
            $("#group-#{@model.id}-user-#{user.id}-actions").focus()
      else
        @removeUser(e, $target)

    removeUser: (e, $target) ->
      @collection.getUser($target.data('user-id')).save 'group', null

    removeLeader: (e) ->
      e.preventDefault()
      e.stopPropagation()
      $target = $(e.currentTarget)
      user_id = $target.data('user-id').toString().replace("user_", "")
      user_name = @model.get('leader').display_name
      @model.save {leader: null}, success: =>
        $.screenReaderFlashMessage(I18n.t('Removed %{user} as group leader', {user: user_name}))
        $(".group-user-actions[data-user-id='user_#{user_id}']", @el).focus()

    setLeader: (e) ->
      e.preventDefault()
      e.stopPropagation()
      $target = $(e.currentTarget)
      user_id = $target.data('user-id').toString().replace("user_", "")
      @model.save {leader: {id: user_id}}, success: =>
        $.screenReaderFlashMessage(I18n.t('%{user} is now group leader', {user: @model.get('leader').display_name}))
        $(".group-user-actions[data-user-id='user_#{user_id}']", @el).focus()

    editGroupAssignment: (e) ->
      e.preventDefault()
      e.stopPropagation()

      $target = $(e.currentTarget)
      user = @collection.getUser($target.data('user-id'))

      @moveTrayProps =
        title: I18n.t('Move Student')
        items: [
          id: user.get('id')
          title: user.get('name')
          groupId: @model.get('id')
        ]
        moveOptions:
          groupsLabel: I18n.t('Groups')
          groups: MoveItem.backbone.collectionToGroups(@model.collection, (col) => models: [])
          excludeCurrent: true
        onMoveSuccess: (res) =>
          groupsHaveSubs = groupHasSubmissions(@model) || groupHasSubmissions(@model.collection.get(res.groupId))
          userHasSubs = user.get('group_submissions')?.length > 0
          newGroupNotEmpty = @model.collection.get(res.groupId).usersCount() > 0
          if groupsHaveSubs || (userHasSubs && newGroupNotEmpty)
            @cloneCategoryView = new GroupCategoryCloneView
              model: user.collection.category
              openedFromCaution: true
            @cloneCategoryView.open()
            @cloneCategoryView.on 'close', =>
              if @cloneCategoryView.cloneSuccess
                window.location.reload()
              else if @cloneCategoryView.changeGroups
                @moveUser(user, res.groupId)
          else
            @moveUser(user, res.groupId)

        focusOnExit: (item) =>
          document.querySelector(".group[data-id=\"#{item.groupId}\"] .group-heading")

      MoveItem.renderTray(@moveTrayProps, document.getElementById('not_right_side'))

    moveUser: (user, groupId) ->
      @model.collection.category.reassignUser(user, @model.collection.get(groupId))

    toJSON: ->
      count: @model.usersCount()
      locked: @model.isLocked()
      ENV: ENV

    renderItem: (model) =>
      super
      @_initDrag(model.view) unless @model?.isLocked()

    # enable draggable on the child GroupUserView (view)
    _initDrag: (view) =>
      view.$el.draggable(Object.assign({}, @dragOptions))
      view.$el.on 'dragstart', (event, ui) ->
        ui.helper.css 'width', view.$el.width()
        $(event.target).draggable 'option', 'containment', 'document'
        $(event.target).data('draggable')._setContainment()

    removeItem: (model) =>
      model.view.remove()
