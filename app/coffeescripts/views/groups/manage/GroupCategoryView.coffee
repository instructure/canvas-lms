define [
  'i18n!groups'
  'underscore'
  'Backbone'
  'compiled/views/groups/manage/GroupCategoryDetailView'
  'compiled/views/groups/manage/GroupsView'
  'compiled/views/groups/manage/UnassignedUsersView'
  'compiled/views/groups/manage/AddUnassignedMenu'
  'compiled/views/groups/manage/AssignToGroupMenu'
  'jst/groups/manage/groupCategory'
  'compiled/jquery.rails_flash_notifications'
], (I18n, _, {View}, GroupCategoryDetailView, GroupsView, UnassignedUsersView, AddUnassignedMenu, AssignToGroupMenu, template) ->

  class GroupCategoryView extends View

    template: template

    @optionProperty 'groupCount'

    @child 'groupCategoryDetailView', '[data-view=groupCategoryDetail]'
    @child 'unassignedUsersView', '[data-view=unassignedUsers]'
    @child 'groupsView', '[data-view=groups]'

    events:
      'click .delete-category': 'deleteCategory'

    initialize: (options) ->
      @groups = @model.groups()
      # TODO: move all of these to GroupCategoriesView#createItemView
      options.groupCategoryDetailView ?= new GroupCategoryDetailView
        model: @model
        collection: @groups
      options.groupsView ?= @groupsView(options)
      options.unassignedUsersView ?= @unassignedUsersView(options)
      super

    groupsView: (options) ->
      addUnassignedMenu = null
      if ENV.IS_LARGE_ROSTER
        users = @model.unassignedUsers(false)
        addUnassignedMenu = new AddUnassignedMenu collection: users
      new GroupsView {
        collection: @groups
        addUnassignedMenu
      }

    unassignedUsersView: (options) ->
      return false if ENV.IS_LARGE_ROSTER
      assignToGroupMenu = new AssignToGroupMenu collection: @groups
      new UnassignedUsersView {
        collection: @model.unassignedUsers(false)
        groupsCollection: @groups
        assignToGroupMenu
      }

    attach: ->
      @model.on 'destroy', @remove, this

    deleteCategory: (e) =>
      e.preventDefault()
      return unless confirm I18n.t('delete_confirm', 'Are you sure you want to remove this group category?')
      @model.destroy
        success: -> $.flashMessage I18n.t('flash.removed', 'Group category successfully removed.')
        failure: -> $.flashError I18n.t('flash.removeError', 'Unable to remove the group category. Please try again later.')
