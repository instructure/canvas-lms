define [
  'compiled/collections/DiscussionTopicsCollection'
  'compiled/models/Announcement'
  'compiled/str/splitAssetString'
], (DiscussionTopicsCollection, Announcement, splitAssetString) ->

  class AnnouncementsCollection extends DiscussionTopicsCollection

    # this sets it up so it uses /api/v1/<context_type>/<context_id>/discussion_topics as base url
    resourceName: 'discussion_topics'

    # this is wonky, and admittitedly not the right way to do this, but it is a workaround
    # to append the query string '?only_announcements=true' to the index action (which tells
    # discussionTopicsController#index to show announcements instead of discussion topics)
    # but remove it for create/show/update/delete
    _stringToAppendToURL: '?only_announcements=true'
    url: -> super + @_stringToAppendToURL

    model: Announcement
