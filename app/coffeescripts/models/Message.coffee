define [
  'underscore'
  'Backbone'
], (_, {Model}) ->

  class Message extends Model

    parse: (data) ->
      if data.messages
        _.each data.messages, (message) ->
          message.author = _.find(data.participants, (p) -> p.id is message.author_id)
          message.participants = _.chain(message.participating_user_ids)
            .map((id) ->
              return null if id == message.author_id
              _.find(data.participants, (p) -> p.id == id).name
            )
            .reject((message) -> _.isNull(message))
            .value()
          if message.participants.length > 2
            message.summarizedParticipants = message.participants.slice(0, 2)
            message.hiddenParticipantCount = message.participants.length - 2
      data

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

    toJSON: ->
      { conversation: _.extend(super, unread: @unread()) }
