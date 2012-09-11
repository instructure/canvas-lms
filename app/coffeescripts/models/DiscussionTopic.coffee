define [
  'Backbone'
  'jquery'
  'underscore'
  'compiled/collections/ParticipantCollection'
  'compiled/collections/DiscussionEntriesCollection'
], (Backbone, $, _, ParticipantCollection, DiscussionEntriesCollection) ->

  class DiscussionTopic extends Backbone.Model
    resourceName: 'discussion_topics'

    defaults:
      discussion_type: 'side_comment'
      podcast_enabled: false
      podcast_has_student_posts: false
      require_initial_post: false
      is_announcement: false

    dateAttributes: [
      'last_reply_at'
      'posted_at'
      'delayed_post_at'
    ]

    initialize: ->
      @participants = new ParticipantCollection

      @entries = new DiscussionEntriesCollection
      @entries.url = => "#{_.result this, 'url'}/entries"
      @entries.participants = @participants

    ##
    # this is for getting the topic 'full view' from the api
    # see: http://<canvas>/doc/api/discussion_topics.html#method.discussion_topics_api.view
    fetchEntries: ->
      baseUrl = _.result this, 'url'
      $.get "#{baseUrl}/view", ({unread_entries, participants, view: entries}) =>
        @unreadEntries = unread_entries
        @participants.reset participants

        # TODO: handle nested replies and 'new_entries' here
        @entries.reset(entries)

    summary: ->
      $('<div/>').html(@get('message')).text() || ''

    # TODO: this would belong in Backbone.model, but I dont know of others are going to need it much
    # or want to commit to this api so I am just putting it here for now
    updateOneAttribute: (key, value, options = {}) ->
      data = {}
      data[key] = value
      options = _.defaults options,
        data: JSON.stringify(data)
        contentType: 'application/json'
      @save {}, options

    positionAfter: (otherId) ->
      throw '`otherId` must be either the id of the model you want to position this after or the string "top"
            (meaning you want to put this topic at the top of the list)' unless otherId > 0 || otherId is 'top'
      @updateOneAttribute 'position_after', otherId
      collection = @collection
      otherIndex = if otherId == 'top' then 0 else collection.indexOf(collection.get(otherId))
      collection.remove this, silent: true
      collection.models.splice otherIndex, 0, this
      collection.reset collection.models
