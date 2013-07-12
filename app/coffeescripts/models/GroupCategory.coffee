define [
  'underscore'
  'Backbone'
  'compiled/collections/GroupCollection'
  'compiled/collections/GroupUserCollection'
  'compiled/models/progressable'
], (_, {Model}, GroupCollection, GroupUserCollection, progressable) ->

  class GroupCategory extends Model

    urlRoot: '/api/v1/group_categories'

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

    present: =>
      data = _.extend {}, @attributes
      data.progress = @progressModel.toJSON()
      data
