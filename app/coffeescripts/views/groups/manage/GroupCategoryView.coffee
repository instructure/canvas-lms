define [
  'i18n!groups'
  'underscore'
  'Backbone'
  'compiled/views/MessageStudentsDialog',
  'compiled/views/groups/manage/GroupCategoryDetailView'
  'compiled/views/groups/manage/GroupCategoryEditView'
  'compiled/views/groups/manage/GroupsView'
  'compiled/views/groups/manage/UnassignedUsersView'
  'compiled/views/groups/manage/AddUnassignedMenu'
  'compiled/views/groups/manage/AssignToGroupMenu'
  'compiled/views/groups/manage/GroupEditView'
  'compiled/models/Group'
  'jst/groups/manage/groupCategory'
  'compiled/jquery.rails_flash_notifications'
  'jquery.disableWhileLoading'
], (I18n, _, {View}, MessageStudentsDialog, GroupCategoryDetailView, GroupCategoryEditView, GroupsView, UnassignedUsersView, AddUnassignedMenu, AssignToGroupMenu, GroupEditView, Group, template) ->

  class GroupCategoryView extends View

    template: template

    @optionProperty 'groupCount'
    @optionProperty 'randomlyAssignStudentsInProgress'

    @child 'groupCategoryDetailView', '[data-view=groupCategoryDetail]'
    @child 'unassignedUsersView', '[data-view=unassignedUsers]'
    @child 'groupsView', '[data-view=groups]'

    events:
      'click .message-all-unassigned': 'messageAllUnassigned'
      'click .edit-category': 'editCategory'
      'click .delete-category': 'deleteCategory'
      'click .add-group': 'addGroup'

    initialize: (options) ->
      @groups = @model.groups()
      # TODO: move all of these to GroupCategoriesView#createItemView
      options.groupCategoryDetailView ?= new GroupCategoryDetailView
        model: @model
        collection: @groups
      options.groupsView ?= @groupsView(options)
      options.unassignedUsersView ?= @unassignedUsersView(options)
      if progress = @model.get('progress')
        @model.progressModel.set progress
        @randomlyAssignStudentsInProgress = true
      else if @model.get('progress_url') or @model.progressStarting
        @randomlyAssignStudentsInProgress = true
      super

    groupsView: (options) ->
      addUnassignedMenu = null
      if ENV.IS_LARGE_ROSTER
        users = @model.unassignedUsers()
        addUnassignedMenu = new AddUnassignedMenu collection: users
      new GroupsView {
        collection: @groups
        addUnassignedMenu
      }

    unassignedUsersView: (options) ->
      return false if ENV.IS_LARGE_ROSTER
      assignToGroupMenu = new AssignToGroupMenu collection: @groups
      new UnassignedUsersView {
        collection: @model.unassignedUsers()
        groupsCollection: @groups
        assignToGroupMenu
      }

    attach: ->
      @model.on 'destroy', @remove, this
      @model.progressModel.on 'change:url', =>
        @model.progressModel.set({'completion': 0})
        @randomlyAssignStudentsInProgress = true
      @model.progressModel.on 'change', @render
      @model.on 'progressResolved', =>
        @model.groups().fetch()
        @model.unassignedUsers().reset()
        @randomlyAssignStudentsInProgress = false
        @render()

    deleteCategory: (e) =>
      e.preventDefault()
      return unless confirm I18n.t('delete_confirm', 'Are you sure you want to remove this group category?')
      @model.destroy
        success: -> $.flashMessage I18n.t('flash.removed', 'Group category successfully removed.')
        failure: -> $.flashError I18n.t('flash.removeError', 'Unable to remove the group category. Please try again later.')

    addGroup: (e) ->
      e.preventDefault()
      @createView ?= new GroupEditView(editing: false)
      new_group = new Group(group_category_id: @model.id)
      new_group.on 'sync', _.once =>
        @groups.add(new_group)
      @createView.model = new_group
      @createView.toggle()

    toJSON: ->
      json = @model.present()
      json.randomlyAssignStudentsInProgress = @randomlyAssignStudentsInProgress
      json

    editCategory: ->
      @editCategoryView ?= new GroupCategoryEditView({@model})
      @editCategoryView.open()

    messageAllUnassigned: (e) ->
      e.preventDefault()
      disabler = $.Deferred()
      @$el.disableWhileLoading disabler
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
