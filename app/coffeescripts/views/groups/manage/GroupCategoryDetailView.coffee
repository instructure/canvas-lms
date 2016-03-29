define [
  'i18n!groups'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/MessageStudentsDialog',
  'compiled/views/groups/manage/RandomlyAssignMembersView'
  'compiled/views/groups/manage/GroupCreateView'
  'compiled/views/groups/manage/GroupCategoryEditView'
  'compiled/views/groups/manage/GroupCategoryCloneView'
  'compiled/models/Group'
  'jst/groups/manage/groupCategoryDetail'
], (I18n, $, _, {View}, MessageStudentsDialog, RandomlyAssignMembersView, GroupCreateView, GroupCategoryEditView, GroupCategoryCloneView, Group, template) ->

  class GroupCategoryDetailView extends View

    template: template

    @optionProperty 'parentView'

    events:
      'click .message-all-unassigned': 'messageAllUnassigned'
      'click .edit-category': 'editCategory'
      'click .delete-category': 'deleteCategory'
      'click .add-group': 'addGroup'
      'click .clone-category' : 'cloneCategory'

    els:
      '.randomly-assign-members': '$randomlyAssignMembersLink'
      '.al-trigger': '$groupCategoryActions'
      '.edit-category': '$editGroupCategoryLink'
      '.message-all-unassigned': '$messageAllUnassignedLink'
      '.add-group': '$addGroupButton'

    initialize: (options) ->
      super
      @randomlyAssignUsersView = new RandomlyAssignMembersView
        model: options.model

    attach: ->
      @collection.on 'add remove reset', @render
      @model.on 'change', @render

    afterRender: ->
      # its trigger will not be rendered yet, set it manually
      @randomlyAssignUsersView.setTrigger @$randomlyAssignMembersLink
      # reassign the trigger for the createView modal if instantiated
      @createView?.setTrigger @$addGroupButton

    toJSON: ->
      json = super
      json.canMessageMembers = @model.canMessageUnassignedMembers()
      json.canAssignMembers = @model.canAssignUnassignedMembers()
      json.locked = @model.isLocked()
      json

    deleteCategory: (e) =>
      e.preventDefault()
      unless confirm I18n.t('delete_confirm', 'Are you sure you want to remove this group set?')
        @$groupCategoryActions.focus()
        return
      @model.destroy
        success: -> $.flashMessage I18n.t('flash.removed', 'Group set successfully removed.')
        failure: -> $.flashError I18n.t('flash.removeError', 'Unable to remove the group set. Please try again later.')

    addGroup: (e) ->
      e.preventDefault()
      @createView ?= new GroupCreateView
        groupCategory: @model
        trigger: @$addGroupButton
      newGroup = new Group({group_category_id: @model.id}, {newAndEmpty: true})
      newGroup.once 'sync', =>
        @collection.add(newGroup)
      @createView.model = newGroup
      @createView.open()

    editCategory: ->
      @editCategoryView ?= new GroupCategoryEditView
        model: @model
        trigger: @$editGroupCategoryLink
      @editCategoryView.open()

    cloneCategory: (e) ->
      e.preventDefault()
      @cloneCategoryView = new GroupCategoryCloneView
        model: @model
        openedFromCaution: false
      @cloneCategoryView.open()
      @cloneCategoryView.on "close", =>
        if @cloneCategoryView.cloneSuccess
          window.location.reload()
        else
          $("#group-category-#{@model.id}-actions").focus()

    messageAllUnassigned: (e) ->
      e.preventDefault()
      disabler = $.Deferred()
      @parentView.$el.disableWhileLoading disabler
      disabler.done =>
        # display the dialog when all data is ready
        students = @model.unassignedUsers().map (user)->
          {id: user.get("id"), short_name: user.get("short_name")}
        dialog = new MessageStudentsDialog
          trigger: @$messageAllUnassignedLink
          context: @model.get 'name'
          recipientGroups: [
            {name: I18n.t('students_who_have_not_joined_a_group', 'Students who have not joined a group'), recipients: students}
          ]
        dialog.open()
      users = @model.unassignedUsers()
      # get notified when last page is fetched and then open the dialog
      users.on 'fetched:last', =>
        disabler.resolve()
      # ensure all data is loaded before displaying dialog
      if users.urls.next?
        users.loadAll = true
        users.fetch page: 'next'
      else
        disabler.resolve()
