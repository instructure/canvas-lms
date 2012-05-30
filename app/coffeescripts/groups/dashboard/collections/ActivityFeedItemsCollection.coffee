define [
  'compiled/collections/ActivityFeedItemsCollection'
], (BaseActivityFeedItemsCollection) ->

  class ActivityFeedItemsCollection extends BaseActivityFeedItemsCollection
    urls:
      everything: '/api/v1/groups/:filter/activity_stream'

    filter: ENV.GROUP_ID
