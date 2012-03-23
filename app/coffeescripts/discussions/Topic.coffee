define [
  'compiled/backbone-ext/Backbone'
], (Backbone) ->

  ##
  # Model for a topic, the initial data received from the server
  class Topic extends Backbone.Model

    defaults:
      # people involved in the conversation
      participants: []

      # ids for the entries that are unread
      unread_entries: []

      # the whole discussion tree, EntryCollections are made out of
      # these
      view: null

    url: ENV.DISCUSSION.ROOT_URL

