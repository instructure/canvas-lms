define [
  'compiled/ActivityFeed/views/items/ActivityFeedItemView'
], (ActivityFeedItemView) ->

  class ActivityFeedItemView.Announcement extends ActivityFeedItemView

    renderContent: ->
      json = @model.toJSON()
      """
        Announcement
        #{json.message}
      """

