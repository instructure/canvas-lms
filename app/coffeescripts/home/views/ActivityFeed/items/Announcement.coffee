define [
  'compiled/home/views/ActivityFeed/items/ActivityFeedItemView'
], (ActivityFeedItemView) ->

  class ActivityFeedItemView.Announcement extends ActivityFeedItemView

    renderContent: ->
      json = @model.toJSON()
      """
        Announcement
        #{json.message}
      """

