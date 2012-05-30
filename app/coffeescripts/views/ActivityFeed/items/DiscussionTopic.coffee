define [
  'compiled/views/ActivityFeed/items/ActivityFeedItemView'
], (ActivityFeedItemView) ->

  class ActivityFeedItemView.DiscussionTopic extends ActivityFeedItemView

    renderContent: ->
      json = @model.toJSON()
      """
        DiscussionTopic
        #{json.message}
      """

