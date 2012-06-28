define [
  'Backbone'
  'compiled/models/Participant'
], (Backbone, Participant) ->

  class ParticipantCollection extends Backbone.Collection

    model: Participant

