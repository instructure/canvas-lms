require [
  'jquery'
  'compiled/models/DiscussionTopic'
  'compiled/models/Announcement'
  'compiled/views/DiscussionTopics/EditView'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/str/splitAssetString'
  'grading_standards'
  'manage_groups'
], ($, DiscussionTopic, Announcement, EditView, AssignmentGroupCollection, splitAssetString) ->

  is_announcement = ENV.DISCUSSION_TOPIC.ATTRIBUTES?.is_announcement
  model = new (if is_announcement then Announcement else DiscussionTopic)(ENV.DISCUSSION_TOPIC.ATTRIBUTES)
  model.urlRoot = ENV.DISCUSSION_TOPIC.URL_ROOT

  [contextType, contextId] = splitAssetString ENV.context_asset_string
  view = new EditView(model: model, permissions: ENV.DISCUSSION_TOPIC.PERMISSIONS, contextType: contextType)

  if contextType is 'courses' && !is_announcement && ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_CREATE_ASSIGNMENT
    (view.assignmentGroupCollection = new AssignmentGroupCollection).contextAssetString = ENV.context_asset_string

  $ ->
    view.render().$el.appendTo('#content')
    $('#discussion-title').focus()

  view
