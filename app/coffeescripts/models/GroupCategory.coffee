define [
  'Backbone'
  'compiled/collections/GroupCollection'
  'compiled/collections/GroupUserCollection'
], ({Model}, GroupCollection, GroupUserCollection) ->

  class GroupCategory extends Model
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
