define ['Backbone'], ({Model}) ->

  class DiscussionFilterState extends Model

    defaults:
      unread: null
      query: null

    hasFilter: ->
      {unread, query} = @attributes
      if unread or query?
        yes
      else
        no

