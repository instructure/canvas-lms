define [
  'i18n!discussions'
  'Backbone'
  'compiled/models/Participant'
], (I18n, Backbone, Participant) ->

  class ParticipantCollection extends Backbone.Collection

    model: Participant

    defaults:
      currentUser: {}
      unknown:
        avatar_image_url: null
        display_name: I18n.t 'uknown_author', 'Unknown Author'
        id: null

    findOrUnknownAsJSON: (id) ->
      # might want to refactor this to return a real participant not the JSON
      participant = @get id
      if participant?
        participant.toJSON()
      else if id is ENV.current_user.id
        # current user isn't a participant (yet)
        ENV.current_user
      else
        # ¯\(°_o)/¯
        @options.unknown


