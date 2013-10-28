define [
  'i18n!GroupView'
  'underscore'
  'Backbone'
  'jst/groups/manage/group'
  'compiled/views/groups/manage/GroupUsersView'
  'compiled/views/groups/manage/GroupEditView'
  'compiled/jquery.rails_flash_notifications'
], (I18n, _, {View}, template, GroupUsersView, GroupEditView) ->

  class GroupView extends View

    tagName: 'li'

    className: 'group'

    template: template

    @optionProperty 'expanded'

    @optionProperty 'addUnassignedMenu'

    @child 'groupUsersView', '[data-view=groupUsers]'

    events:
      'click .toggle-group': 'toggleDetails'
      'click .edit-group': 'editGroup'
      'click .delete-group': 'deleteGroup'
      'click .add-user': 'showAddUser'
      'focus .add-user': 'showAddUser'
      'blur .add-user': 'hideAddUser'

    els:
      '.group-summary': '$summary'
      '.al-trigger': '$groupActions'
      '.toggle-group': '$toggleGroup'

    attach: ->
      @expanded = false
      @users = @model.users()
      @model.on 'change', @render
      @model.on 'destroy', @remove, this
      @users.on 'add remove reset', @updateSummary

    editGroup: (e) =>
      e.preventDefault()
      @editView ?= new GroupEditView({@model, focusReturnsTo: => @$el.find('.al-trigger')})
      @editView.toggle()

    deleteGroup: (e) =>
      e.preventDefault()
      unless confirm I18n.t('delete_confirm', 'Are you sure you want to remove this group?')
        @$groupActions.focus()
        return
      @model.destroy
        success: -> $.flashMessage I18n.t('flash.removed', 'Group successfully removed.')
        failure: -> $.flashError I18n.t('flash.removeError', 'Unable to remove the group. Please try again later.')

    toJSON: ->
      json = super
      json.summary = @summary()
      json

    summary: ->
      if ENV.group_user_type is 'student'
        I18n.t "student_count", "student", count: @model.usersCount()
      else
        I18n.t "user_count", "user", count: @model.usersCount()

    updateSummary: =>
      @$summary.text @summary()

    afterRender: ->
      @$el.toggleClass 'group-expanded', @expanded
      @$el.toggleClass 'group-collapsed', !@expanded
      @$toggleGroup.attr 'aria-expanded', '' + @expanded

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
      @addUnassignedMenu.groupId = @model.id
      @addUnassignedMenu.showBy $target, e.type is 'click'

    hideAddUser: (e) ->
      @addUnassignedMenu.hide()

