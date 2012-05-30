define [
  'compiled/views/ActivityFeed/items/ActivityFeedItemView'
], (ActivityFeedItemView) ->

  class ActivityFeedItemView.Collaboration extends ActivityFeedItemView

    renderContent: ->
      json = @model.toJSON()
      """
        Collaboration
        #{json.message}
      """

