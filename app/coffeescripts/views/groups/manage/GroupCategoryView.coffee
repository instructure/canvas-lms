define [
  'i18n!groups'
  'Backbone'
  'compiled/views/groups/manage/GroupCategoryDetailView'
  'compiled/views/groups/manage/GroupsView'
  'compiled/views/groups/manage/UnassignedUsersView'
  'compiled/views/groups/manage/AddUnassignedMenu'
  'jst/groups/manage/groupCategory'
  'compiled/jquery.rails_flash_notifications'
  'jquery.disableWhileLoading'
], (I18n, {View}, GroupCategoryDetailView, GroupsView, UnassignedUsersView, AddUnassignedMenu, template) ->

  class GroupCategoryView extends View

    template: template

    @child 'groupCategoryDetailView', '[data-view=groupCategoryDetail]'
    @child 'unassignedUsersView', '[data-view=unassignedUsers]'
    @child 'groupsView', '[data-view=groups]'

    els:
      '.filterable': '$filter'
      '.filterable-unassigned-users': '$filterUnassignedUsers'
      '.unassigned-users-heading': '$unassignedUsersHeading'
      '.groups-with-count': '$groupsHeading'

    initialize: (options) ->
      @groups = @model.groups()
      # TODO: move all of these to GroupCategoriesView#createItemView
      options.groupCategoryDetailView ?= new GroupCategoryDetailView
        parentView: this,
        model: @model
        collection: @groups
      options.groupsView ?= @groupsView(options)
      options.unassignedUsersView ?= @unassignedUsersView(options)
      if progress = @model.get('progress')
        @model.progressModel.set progress
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
      new UnassignedUsersView {
        category: @model
        collection: @model.unassignedUsers()
        groupsCollection: @groups
      }

    attach: ->
      @model.on 'destroy', @remove, this
      @model.on 'change', => @groupsView.updateDetails()

      @model.on 'change:unassigned_users_count', @setUnassignedHeading, this
      @groups.on 'add remove reset', @setGroupsHeading, this

      @model.progressModel.on 'change:url', =>
        @model.progressModel.set({'completion': 0})
      @model.progressModel.on 'change', @render
      @model.on 'progressResolved', =>
        @model.fetch success: =>
          @model.groups().fetch()
          @model.unassignedUsers().fetch()
          @render()

    cacheEls: ->
      super
      # need to be set before their afterRender's run (i.e. before this
      # view's afterRender)
      @groupsView.$externalFilter = @$filter
      @unassignedUsersView.$externalFilter = @$filterUnassignedUsers

    afterRender: ->
      @setUnassignedHeading()
      @setGroupsHeading()

    setUnassignedHeading: ->
      count = @model.unassignedUsersCount() ? 0
      @$unassignedUsersHeading.text(
        if @model.get('allows_multiple_memberships')
          I18n.t('everyone', "Everyone (%{count})", {count})
        else if ENV.group_user_type is 'student'
          I18n.t('unassigned_students', "Unassigned Students (%{count})", {count})
        else
          I18n.t('unassigned_users', "Unassigned Users (%{count})", {count})
      )

    setGroupsHeading: ->
      count = @model.groupsCount()
      @$groupsHeading.text I18n.t("groups_count", "Groups (%{count})", {count})

    toJSON: ->
      json = @model.present()
      json.ENV = ENV
      json.groupsAreSearchable = ENV.IS_LARGE_ROSTER and
                                 not json.randomlyAssignStudentsInProgress
      json

