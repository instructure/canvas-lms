define ['i18n!discussions', 'compiled/discussions/app'], (I18n, app) ->

  UNKOWN_AUTHOR =
    avatar_image_url: null
    display_name: I18n.t 'uknown_author', 'Unknown Author'
    id: null

  ##
  # Finds a participant in the discussion by id
  #
  # @param {Number} userId
  findParticipant = (userId) ->
    participant = app.topicView.discussion?.participants.get userId
    if participant?
      # found the participant
      participant.toJSON()
    else if userId is ENV.DISCUSSION.CURRENT_USER.id
      # in case the current user isn't in the participants
      ENV.DISCUSSION.CURRENT_USER
    else
      # ¯\(°_o)/¯
      UNKOWN_AUTHOR

