define [
  'underscore'
  'Backbone'
  'compiled/collections/GroupCollection'
  'compiled/collections/GroupUserCollection'
  'compiled/models/progressable'
  'compiled/backbone-ext/DefaultUrlMixin'
], (_, Backbone, GroupCollection, GroupUserCollection, progressable, DefaultUrlMixin) ->

  class GroupCategory extends Backbone.Model

    resourceName: "group_categories"
    @mixin progressable

    groups: ->
      @_groups = new GroupCollection(null)
      @_groups.category = this
      @_groups.url = "/api/v1/group_categories/#{@id}/groups?per_page=50"
      @_groups.loadAll = true
      if @get('groups_count') is 0
        @_groups.loadedAll = true
      else
        @_groups.fetch()
      @_groups.on 'fetched:last', => @set('groups_count', @_groups.length)
      @groups = -> @_groups
      @_groups

    groupsCount: ->
      if @_groups?.loadedAll
        @_groups.length
      else
        @get('groups_count')

    unassignedUsers: ->
      @_unassignedUsers = new GroupUserCollection(null, groupId: null)
      @_unassignedUsers.category = this
      @_unassignedUsers.url = "/api/v1/group_categories/#{@id}/users?unassigned=true&per_page=50"
      @_unassignedUsers.on 'fetched:last', => @set('unassigned_users_count', @_unassignedUsers.length)
      @unassignedUsers = -> @_unassignedUsers
      @_unassignedUsers

    unassignedUsersCount: ->
      @get('unassigned_users_count')

    canAssignUnassignedMembers: ->
      @groupsCount() > 0 and
        @get('role') isnt 'student_organized' and
        @get('self_signup') isnt 'restricted'

    assignUnassignedMembers: ->
      $.ajaxJSON "/api/v1/group_categories/#{@id}/assign_unassigned_members", 'POST', {}, @setUpProgress

    setUpProgress: (response) =>
      @set progress_url: response.url

    present: ->
      data = Backbone.Model::toJSON.call(this)
      data.progress = @progressModel.toJSON()
      data

    toJSON: ->
      data = _.omit(super, 'self_signup', 'split_group_count')
      data.create_group_count ?= @get('split_group_count') if @get('split_groups')
      data

    @mixin DefaultUrlMixin

    sync: (method, model, options = {}) ->
      options.url = @urlFor(method)
      if method is 'create' and model.get('split_groups') is '1'
        success = options.success ? ->
        options.success = (args) =>
          @progressStarting = true
          success(args)
          @assignUnassignedMembers()
      else if method is 'delete'
        if model.progressModel
          model.progressModel.onPoll = ->
      Backbone.sync method, model, options

    urlFor: (method) ->
      if method is 'create'
        @_defaultUrl()
      else
        "/api/v1/group_categories/#{@id}"
