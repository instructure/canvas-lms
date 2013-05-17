define [
  'Backbone'
  'compiled/models/DiscussionEntry'
], (Backbone, DiscussionEntry) ->

  class DiscussionEntryCollection extends Backbone.Collection

    model: DiscussionEntry

