define [
  'compiled/ActivityFeed/views/items/ActivityFeedItemView'
], (ActivityFeedItemView) ->

  class ActivityFeedItemView.Submission extends ActivityFeedItemView

    renderContent: ->
      json = @model.toJSON()
      """
        Submission
        #{json.message}
      """

