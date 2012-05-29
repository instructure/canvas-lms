define [
  'underscore'
  'Backbone'
  'i18n!discussions'
], (_, Backbone, I18n) ->

  UNKOWN_AUTHOR =
    avatar_image_url: null
    display_name: 'Unknown Author'
    id: null

  ##
  # Model representing an entry in discussion topic
  class Entry extends Backbone.Model

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
        UNKOWN_AUTHOR

