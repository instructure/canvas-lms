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
      @_groups.url = "/api/v1/group_categories/#{@id}/groups?per_page=50"
      @_groups.loadAll = true
      @_groups.fetch() unless @get('groupCount') is 0
      @groups = -> @_groups
      @_groups

    groupsCount: ->
      @_groups?.length ? @get('groupCount')

    unassignedUsers: ->
      @_unassignedUsers = new GroupUserCollection(null, groupId: null)
      @_unassignedUsers.url = "/api/v1/group_categories/#{@id}/users?unassigned=true&per_page=50"
      @unassignedUsers = -> @_unassignedUsers
      @_unassignedUsers

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
