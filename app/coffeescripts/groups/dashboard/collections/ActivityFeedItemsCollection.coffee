define [
  'compiled/ActivityFeed/ActivityFeedItemsCollection'
], (BaseActivityFeedItemsCollection) ->

  class ActivityFeedItemsCollection extends BaseActivityFeedItemsCollection
    urls:
      everything: '/groups/:filter/activity_stream'

    filter: ENV.GROUP_ID
