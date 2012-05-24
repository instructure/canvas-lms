define [
  'compiled/ActivityFeed/views/items/ActivityFeedItemView'
], (ActivityFeedItemView) ->

  class ActivityFeedItemView.Message extends ActivityFeedItemView

    renderContent: ->
      json = @model.toJSON()
      """
        Message
        #{json.message}
      """

