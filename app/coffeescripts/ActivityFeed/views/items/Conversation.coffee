define [
  'compiled/ActivityFeed/views/items/ActivityFeedItemView'
], (ActivityFeedItemView) ->

  class ActivityFeedItemView.Conversation extends ActivityFeedItemView

    renderContent: ->
      json = @model.toJSON()
      """
        Conversation
        #{json.message}
      """

