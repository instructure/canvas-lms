define [
  'use!backbone'
  'compiled/discussions/Participant'
], (Backbone, Participant) ->

  class ParticipantCollection extends Backbone.Collection

    model: Participant

