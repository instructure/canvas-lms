define [
  'compiled/home/views/ActivityFeed/items/ActivityFeedItemView'
  'compiled/home/views/ActivityFeed/items/Announcement'
  'compiled/home/views/ActivityFeed/items/Collaboration'
  'compiled/home/views/ActivityFeed/items/Conference'
  'compiled/home/views/ActivityFeed/items/Conversation'
  'compiled/home/views/ActivityFeed/items/DiscussionTopic'
  'compiled/home/views/ActivityFeed/items/Message'
  'compiled/home/views/ActivityFeed/items/Submission'
], (ActivityFeedItemView) ->

  activityFeedItemViewFactory = (activityFeedItem) ->
    type = activityFeedItem.toJSON().type
    View = ActivityFeedItemView[type]
    if View
      new View model: activityFeedItem
    else
      new ActivityFeedItemView model: activityFeedItem

