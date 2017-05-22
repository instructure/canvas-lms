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
  'underscore'
  'i18n!EditGroupAssignmentView'
  'compiled/views/DialogFormView'
  'compiled/collections/GroupCollection'
  'compiled/views/groups/manage/GroupCategoryCloneView'
  'jst/groups/manage/editGroupAssignment'
  'jst/EmptyDialogFormWrapper'
], ($, _, I18n, DialogFormView, GroupCollection, GroupCategoryCloneView, template, wrapper) ->

  class EditGroupAssignmentView extends DialogFormView

    @optionProperty 'group'

    els:
      '.single-select': '$singleSelectList'

    defaults:
      title: I18n.t "move_to", "Move To"
      width: 450
      height: 350

    template: template

    wrapperTemplate: wrapper

    className: 'form-dialog'

    events:
      'click .dialog_closer': 'close'
      'click .set-group': 'setGroup'

    openAgain: ->
      super
      # reset the form contents
      @render()
      # auto-focus the select element
      @$singleSelectList.focus()

    setGroup: (e) =>
      e.preventDefault()
      e.stopPropagation()
      targetGroup = @$('option:selected').val()

      if targetGroup
        if @group.get('has_submission') or @group.collection.get(targetGroup).get('has_submission')
          @close()
          @cloneCategoryView = new GroupCategoryCloneView
            model: @model.collection.category
            openedFromCaution: true
          @cloneCategoryView.open()
          @cloneCategoryView.on "close", =>
            if @cloneCategoryView.cloneSuccess
              window.location.reload()
            else if @cloneCategoryView.changeGroups
              @moveUser(targetGroup, false)
        else
          @moveUser(targetGroup, true)

    moveUser: (targetGroup, closeDialog) ->
      @group.collection.category.reassignUser(@model, @group.collection.get(targetGroup))
      if closeDialog
        @close()
      # focus override to the user's new group heading if they're moved
      $("[data-id='#{targetGroup}'] .group-heading")?.focus()

    getFilteredGroups: ->
      new GroupCollection @group.collection.filter (g) => g isnt @group

    toJSON: ->
      groupCollection = @getFilteredGroups()
      hasGroups = groupCollection.length > 0
      {
        allFull: hasGroups and groupCollection.models.every (g) -> g.isFull()
        groupId: @group.id
        userName: @model.get('name')
        groups: groupCollection.toJSON()
      }
