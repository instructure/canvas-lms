define [
  'compiled/collections/GroupUserCollection'
  'compiled/models/GroupUser'
], (GroupUserCollection, GroupUser) ->

  class UnassignedGroupUserCollection extends GroupUserCollection

    url: ->
      _url = "/api/v1/group_categories/#{@category.id}/users?per_page=50&include[]=sections&exclude[]=pseudonym"
      _url += "&unassigned=true" unless @category.get('allows_multiple_memberships')
      @url = _url

    # don't add/remove people in the "Everyone" collection (this collection)
    # if the category supports multiple memberships
    membershipsLocked: ->
      @category.get('allows_multiple_memberships')

    increment: (amount) ->
      @category.increment 'unassigned_users_count', amount

    search: (filter, options) ->
      options = options || {}
      options.reset = true

      if filter && filter.length >= 3
        options.url = @url + "&search_term=" + filter
        @filtered = true
        return @fetch(options)
      else if @filtered
        @filtered = false
        options.url = @url
        return @fetch(options)

      # do nothing
