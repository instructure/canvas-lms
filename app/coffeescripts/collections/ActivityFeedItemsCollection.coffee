define ['Backbone'], ({Collection, Model}) ->

  class ActivityFeedItemsCollection extends Collection

    model: Model.extend()

    urlKey: 'everything'

    filter: ''

    urls:
      everything: '/api/v1/users/self/activity_stream'
      course: '/api/v1/courses/:filter/activity_stream'
      community: '/api/v1/groups/:filter/activity_stream'

    url: ->
      @urls[@urlKey].replace /:filter/, @filter

    add: (models, options) ->
      newModels = (model for model in models when not @get(model.id)?)
      super newModels, options

    comparator: (x, y) ->
      x = Date.parse(x.get('updated_at')).getTime()
      y = Date.parse(y.get('updated_at')).getTime()
      if x is y
        0
      else if x < y
        -1
      else
        1
