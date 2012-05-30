define [
  'compiled/views/ActivityFeed/items/ActivityFeedItemView'
  'compiled/views/ActivityFeed/items/Announcement'
  'compiled/views/ActivityFeed/items/Collaboration'
  'compiled/views/ActivityFeed/items/Conference'
  'compiled/views/ActivityFeed/items/Conversation'
  'compiled/views/ActivityFeed/items/DiscussionTopic'
  'compiled/views/ActivityFeed/items/Message'
  'compiled/views/ActivityFeed/items/Submission'
], (ActivityFeedItemView) ->

  activityFeedItemViewFactory = (activityFeedItem) ->
    type = activityFeedItem.toJSON().type
    View = ActivityFeedItemView[type]
    if View
      new View model: activityFeedItem
    else
      new ActivityFeedItemView model: activityFeedItem

