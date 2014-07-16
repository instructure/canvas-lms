define [
  'underscore'
  'Backbone'
  'compiled/str/TextHelper'
], (_, {Model, Collection}, TextHelper) ->

  class Message extends Model
    initialize: ->
      @messageCollection = new Collection()
      @on('change:messages', @handleMessages)

    parse: (data) ->
      if data.messages
          findParticipant = (id) -> _.find(data.participants, id: id)
        _.each data.messages, (message) ->
          message.author = findParticipant(message.author_id)

          message.participants = []
          message.participantNames = []
          for id in message.participating_user_ids when id isnt message.author_id
            if participant = findParticipant(id)
              message.participants.push participant
              message.participantNames.push participant.name

          if message.participants.length > 2
            message.summarizedParticipantNames = message.participantNames.slice(0, 2)
            message.hiddenParticipantCount = message.participants.length - 2
          message.context_name = data.context_name
          message.has_attachments = message.media_comment || message.attachments.length
          message.bodyHTML = TextHelper.formatMessage(message.body)
      data

    handleMessages: ->
      @messageCollection.reset(@get('messages') || [])
      @listenTo(@messageCollection, 'change:selected', @handleSelection)

    handleSelection: (model, value) ->
      return if !value
      @messageCollection.each (m) -> m.set(selected: false) if m != model

    unread: ->
      @get('workflow_state') is 'unread'

    starred: ->
      @get('starred')

    toggleReadState: (set_read) ->
      set_read ?= @unread()
      @set('workflow_state', if set_read then 'read' else 'unread')

    toggleStarred: (setStarred) ->
      setStarred ?= !@starred()
      @set('starred', setStarred)

    timestamp: ->
      lastMessage  = new Date(@get('last_message_at')).getTime()
      lastAuthored = new Date(@get('last_authored_message_at')).getTime()
      new Date(_.max([lastMessage, lastAuthored]))

    toJSON: ->
      { conversation: _.extend(super, unread: @unread(), starred: @starred(), timestamp: @timestamp()) }
