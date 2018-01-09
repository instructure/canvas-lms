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
  './PopoverMenuView'
  './GroupCategoryCloneView'
  '../../../models/GroupUser'
  'jst/groups/manage/assignToGroupMenu'
  'jquery'
  '../../../util/groupHasSubmissions'
  '../../../jquery/outerclick'
], (PopoverMenuView, GroupCategoryCloneView, GroupUser, template, $, groupHasSubmissions) ->

  class AssignToGroupMenu extends PopoverMenuView

    defaults: Object.assign {},
      PopoverMenuView::defaults,
      zIndex: 10

    events: Object.assign {},
      PopoverMenuView::events,
      'click .set-group': 'setGroup'
      'focusin .focus-bound': "boundFocused"

    attach: ->
      @collection.on 'change add remove reset', @render

    tagName: 'div'

    className: 'assign-to-group-menu ui-tooltip popover content-top horizontal'

    template: template

    setGroup: (e) ->
      e.preventDefault()
      e.stopPropagation()
      newGroupId = $(e.currentTarget).data('group-id')
      userId = @model.id

      if groupHasSubmissions @collection.get(newGroupId)
        @cloneCategoryView = new GroupCategoryCloneView
            model: @model.collection.category
            openedFromCaution: true
        @cloneCategoryView.open()
        @cloneCategoryView.on "close", =>
            if @cloneCategoryView.cloneSuccess
              window.location.reload()
            else if @cloneCategoryView.changeGroups
              @moveUser(newGroupId)
            else
              $("[data-user-id='user_#{userId}']").focus()
              @hide()
      else
        @moveUser(newGroupId)

    moveUser: (newGroupId) ->
      @collection.category.reassignUser(@model, @collection.get(newGroupId))
      @$el.detach()
      @trigger("close", {"userMoved": true })

    toJSON: ->
      hasGroups = @collection.length > 0
      {
        groups: @collection.toJSON()
        noGroups: !hasGroups
        allFull: hasGroups and @collection.models.every (g) -> g.isFull()
      }

    attachElement: ->
      $('body').append(@$el)

    focus: ->
      noGroupsToJoin = @collection.length <= 0 or @collection.models.every (g) -> g.isFull()
      toFocus = if noGroupsToJoin then ".popover-content p" else "li a" #focus text if no groups, focus first group if groups
      @$el.find(toFocus).first().focus()

    boundFocused: ->
      #force hide and pretend we pressed escape
      @$el.detach()
      @trigger("close", {"escapePressed": true })
