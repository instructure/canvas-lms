define [
  'compiled/views/ActivityFeed/items/ActivityFeedItemView'
], (ActivityFeedItemView) ->

  class ActivityFeedItemView.Conference extends ActivityFeedItemView

    renderContent: ->
      json = @model.toJSON()
      """
        Conference
        #{json.message}
      """

