define [
  'compiled/ActivityFeed/views/items/ActivityFeedItemView'
  'compiled/ActivityFeed/views/items/Announcement'
  'compiled/ActivityFeed/views/items/Collaboration'
  'compiled/ActivityFeed/views/items/Conference'
  'compiled/ActivityFeed/views/items/Conversation'
  'compiled/ActivityFeed/views/items/DiscussionTopic'
  'compiled/ActivityFeed/views/items/Message'
  'compiled/ActivityFeed/views/items/Submission'
], (ActivityFeedItemView) ->

  activityFeedItemViewFactory = (activityFeedItem) ->
    type = activityFeedItem.toJSON().type
    View = ActivityFeedItemView[type]
    if View
      new View model: activityFeedItem
    else
      new ActivityFeedItemView model: activityFeedItem

