define [
  'i18n!GroupDetailView'
  'jquery'
  'Backbone'
  'compiled/views/groups/manage/GroupEditView'
  'jst/groups/manage/groupDetail'
  'compiled/jquery.rails_flash_notifications'
], (I18n, $, {View}, GroupEditView, template) ->

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
      unless confirm I18n.t('delete_confirm', 'Are you sure you want to remove this group?')
        @$groupActions.focus()
        return
      @model.destroy
        success: -> $.flashMessage I18n.t('flash.removed', 'Group successfully removed.')
        error: -> $.flashError I18n.t('flash.removeError', 'Unable to remove the group. Please try again later.')

    closeMenu: ->
      @$groupActions.data('kyleMenu')?.$menu.popup 'close'

    toJSON: ->
      json = @model.toJSON()
      json.canAssignUsers = ENV.IS_LARGE_ROSTER and not @model.isLocked()
      json.canEdit = not @model.isLocked()
      json.summary = @summary()
      json
