define [
  'compiled/views/ActivityFeed/items/ActivityFeedItemView'
], (ActivityFeedItemView) ->

  class ActivityFeedItemView.Conversation extends ActivityFeedItemView

    renderContent: ->
      json = @model.toJSON()
      """
        Conversation
        #{json.message}
      """

