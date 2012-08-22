require [
  'jquery'
  'compiled/models/DiscussionTopic'
  'compiled/models/Announcement'
  'compiled/views/DiscussionTopics/EditView'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/str/splitAssetString'
], ($, DiscussionTopic, Announcement, EditView, AssignmentGroupCollection, splitAssetString) ->

  is_announcement = ENV.DISCUSSION_TOPIC.ATTRIBUTES?.is_announcement
  model = new (if is_announcement then Announcement else DiscussionTopic)(ENV.DISCUSSION_TOPIC.ATTRIBUTES)
  model.urlRoot = ENV.DISCUSSION_TOPIC.URL_ROOT

  view = new EditView(model: model)

  [contextType, contextId] = splitAssetString ENV.context_asset_string
  if contextType is 'courses' && !is_announcement
    (view.assignmentGroupCollection = new AssignmentGroupCollection).contextAssetString = ENV.context_asset_string

  $ -> view.render().$el.appendTo('#content')

  view
