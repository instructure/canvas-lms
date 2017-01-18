define [
  'i18n!GroupDetailView'
  'jquery'
  'Backbone'
  'compiled/views/groups/manage/GroupEditView'
  'compiled/views/groups/manage/GroupCategoryCloneView'
  'jst/groups/manage/groupDetail'
  'compiled/jquery.rails_flash_notifications'
], (I18n, $, {View}, GroupEditView, GroupCategoryCloneView, template) ->

  class GroupDetailView extends View

    @optionProperty 'users'

    template: template

    events:
      'click .edit-group': 'editGroup'
      'click .delete-group': 'deleteGroup'

    els:
      '.toggle-group': '$toggleGroup'
      '.al-trigger': '$groupActions'
      '.edit-group': '$editGroupLink'

    attach: ->
      @model.on 'change', @render

    summary: ->
      count = @model.usersCount()
      if @model.theLimit()
        if ENV.group_user_type is 'student'
          I18n.t "%{count} / %{max} students", count: count, max: @model.theLimit()
        else
          I18n.t "%{count} / %{max} users", count: count, max: @model.theLimit()
      else
        if ENV.group_user_type is 'student'
          I18n.t "student_count", "student", count: count
        else
          I18n.t "user_count", "user", count: count

    editGroup: (e) =>
      e.preventDefault()
      @editView ?= new GroupEditView({@model, groupCategory: @model.collection.category})
      @editView.setTrigger @$editGroupLink
      @editView.open()

    deleteGroup: (e) =>
      e.preventDefault()
      if confirm I18n.t('delete_confirm', 'Are you sure you want to remove this group?')
        if @model.get("has_submission")
          @cloneCategoryView = new GroupCategoryCloneView
            model: @model.collection.category
            openedFromCaution: true
          @cloneCategoryView.open()
          @cloneCategoryView.on "close", =>
            if @cloneCategoryView.cloneSuccess
              window.location.reload()
            else if @cloneCategoryView.changeGroups
              @performDeleteGroup()
            else
              @$groupActions.focus()
        else
          @performDeleteGroup()
      else
        @$groupActions.focus()

    performDeleteGroup: ->
      @model.destroy
        success: -> $.flashMessage I18n.t('flash.removed', 'Group successfully removed.')
        error: -> $.flashError I18n.t('flash.removeError', 'Unable to remove the group. Please try again later.')

    closeMenu: ->
      @$groupActions.data('kyleMenu')?.$menu.popup 'close'

    toJSON: ->
      json = @model.toJSON()
      json.leader = @model.get('leader')
      json.canAssignUsers = ENV.IS_LARGE_ROSTER and not @model.isLocked()
      json.canEdit = not @model.isLocked()
      json.summary = @summary()
      json
