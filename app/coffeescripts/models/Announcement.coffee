define [
  'compiled/models/DiscussionTopic'
  'underscore'
], (DiscussionTopic, _) ->

  class Announcement extends DiscussionTopic

    # this is wonky, and admittitedly not the right way to do this, but it is a workaround
    # to append the query string '?only_announcements=true' to the index action (which tells
    # discussionTopicsController#index to show announcements instead of discussion topics)
    # but remove it for create/show/update/delete
    urlRoot: -> _.result(@collection, 'url').replace(@collection._stringToAppendToURL, '')

    defaults:
      is_announcement: true

