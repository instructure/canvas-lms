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
  'i18n!groups'
  'Backbone'
  'underscore'
  './GroupCategoryDetailView'
  './GroupsView'
  './UnassignedUsersView'
  './AddUnassignedMenu'
  'jst/groups/manage/groupCategory'
  '../../../jquery.rails_flash_notifications'
  'jquery.disableWhileLoading'
], (I18n, {View}, _, GroupCategoryDetailView, GroupsView, UnassignedUsersView, AddUnassignedMenu, template) ->

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

    _previousSearchTerm = ""

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

    filterChange: (event) ->
      search_term = event.target.value
      return if search_term == _previousSearchTerm #Don't rerender if nothing has changed

      @options.unassignedUsersView.setFilter(search_term)

      @_setUnassignedHeading(@originalCount) unless search_term.length >= 3
      _previousSearchTerm = search_term

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

      if !@attachedFilter
        @$filterUnassignedUsers.on "keyup", _.debounce(@filterChange.bind(this), 300)
        @attachedFilter = true

      # need to be set before their afterRender's run (i.e. before this
      # view's afterRender)
      @groupsView.$externalFilter = @$filter
      @unassignedUsersView.$externalFilter = @$filterUnassignedUsers

    afterRender: ->
      @setUnassignedHeading()
      @setGroupsHeading()

    setUnassignedHeading: ->
      count = @model.unassignedUsersCount() ? 0
      @originalCount = @originalCount || count
      @_setUnassignedHeading(count)

    _setUnassignedHeading: (count) ->
      @unassignedUsersView.render() if @unassignedUsersView
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
