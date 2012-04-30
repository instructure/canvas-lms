define [
  'compiled/home/views/ActivityFeed/items/ActivityFeedItemView'
], (ActivityFeedItemView) ->

  class ActivityFeedItemView.Submission extends ActivityFeedItemView

    renderContent: ->
      json = @model.toJSON()
      """
        Submission
        #{json.message}
      """

