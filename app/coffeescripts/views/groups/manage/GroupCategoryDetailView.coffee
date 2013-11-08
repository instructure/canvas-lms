define [
  'i18n!groups'
  'underscore'
  'Backbone'
  'compiled/views/MessageStudentsDialog',
  'compiled/views/groups/manage/RandomlyAssignMembersView'
  'compiled/views/groups/manage/GroupEditView'
  'compiled/views/groups/manage/GroupCategoryEditView'
  'compiled/models/Group'
  'jst/groups/manage/groupCategoryDetail'
], (I18n, _, {View}, MessageStudentsDialog, RandomlyAssignMembersView, GroupEditView, GroupCategoryEditView, Group, template) ->

  class GroupCategoryDetailView extends View

    template: template

    @optionProperty 'parentView'

    events:
      'click .message-all-unassigned': 'messageAllUnassigned'
      'click .edit-category': 'editCategory'
      'click .delete-category': 'deleteCategory'
      'click .add-group': 'addGroup'

    els:
      '.randomly-assign-members': '$randomlyAssignMembersLink'

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

    toJSON: ->
      json = super
      json.canAssignMembers = @model.canAssignUnassignedMembers()
      json

    deleteCategory: (e) =>
      e.preventDefault()
      return unless confirm I18n.t('delete_confirm', 'Are you sure you want to remove this group set?')
      @model.destroy
        success: -> $.flashMessage I18n.t('flash.removed', 'Group set successfully removed.')
        failure: -> $.flashError I18n.t('flash.removeError', 'Unable to remove the group set. Please try again later.')

    addGroup: (e) ->
      e.preventDefault()
      @createView ?= new GroupEditView(editing: false)
      new_group = new Group(group_category_id: @model.id)
      new_group.on 'sync', _.once =>
        @collection.add(new_group)
      @createView.model = new_group
      @createView.toggle()

    editCategory: ->
      @editCategoryView ?= new GroupCategoryEditView({@model})
      @editCategoryView.open()

    messageAllUnassigned: (e) ->
      e.preventDefault()
      disabler = $.Deferred()
      @parentView.$el.disableWhileLoading disabler
      disabler.done =>
        # display the dialog when all data is ready
        students = @model.unassignedUsers().map (user)->
          {id: user.get("id"), short_name: user.get("short_name")}
        dialog = new MessageStudentsDialog
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
