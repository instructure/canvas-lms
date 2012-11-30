define ['Backbone'], ({Model}) ->

  class DiscussionFilterState extends Model

    defaults:
      unread: false
      query: null
      collapsed: false

    hasFilter: ->
      {unread, query} = @attributes
      if unread or query?
        yes
      else
        no

    reset: ->
      @set
        unread: false
        query: null
        collapsed: false
      @trigger 'reset'


