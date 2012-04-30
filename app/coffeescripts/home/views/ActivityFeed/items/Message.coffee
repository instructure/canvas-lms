define [
  'compiled/home/views/ActivityFeed/items/ActivityFeedItemView'
], (ActivityFeedItemView) ->

  class ActivityFeedItemView.Message extends ActivityFeedItemView

    renderContent: ->
      json = @model.toJSON()
      """
        Message
        #{json.message}
      """

