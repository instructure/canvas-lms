define [
  'Backbone'
  'underscore'
  'compiled/collections/ParticipantCollection'
  'compiled/collections/EntriesCollection'
], (Backbone, _, ParticipantCollection, EntriesCollection) ->

  class Topic extends Backbone.Model

    initialize: ->
      @participants = new ParticipantCollection

      @entries = new EntriesCollection
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

