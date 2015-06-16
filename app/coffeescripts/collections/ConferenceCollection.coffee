define [
  'Backbone'
  'compiled/models/Conference'
], ({Collection}, Conference) ->

  class ConferenceCollection extends Collection
    model: Conference
