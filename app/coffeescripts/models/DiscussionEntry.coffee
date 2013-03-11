define [
  'underscore'
  'Backbone'
  'i18n!discussions'
], (_, Backbone, I18n) ->

  UNKNOWN_AUTHOR =
    avatar_image_url: null
    display_name: I18n.t 'unknown_author', 'Unknown Author'
    id: null

  ##
  # Model representing an entry in discussion topic
  class DiscussionEntry extends Backbone.Model

    author: ->
      @findParticipant @get('user_id')

    editor: ->
      @findParticipant @get('editor_id')

    findParticipant: (user_id) ->
      if user_id && user = @collection?.participants.get user_id
        user.toJSON()
      else if user_id is ENV.current_user?.id
        ENV.current_user
      else
        UNKNOWN_AUTHOR

