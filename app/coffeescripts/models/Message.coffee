define [
  'underscore'
  'Backbone'
], (_, {Model, Collection}) ->

  class Message extends Model
    initialize: ->
      @messageCollection = new Collection()
      @on('change:messages', @handleMessages)

    parse: (data) ->
      if data.messages
        _.each data.messages, (message) ->
          message.author = _.find(data.participants, (p) -> p.id is message.author_id)
          message.participants = _.chain(message.participating_user_ids)
            .map((id) ->
              return null if id == message.author_id
              _.find(data.participants, (p) -> p.id == id)
            )
            .reject((message) -> _.isNull(message))
            .value()
          message.participantNames = _.pluck(message.participants, 'name')
          if message.participants.length > 2
            message.summarizedParticipantNames = message.participantNames.slice(0, 2)
            message.hiddenParticipantCount = message.participants.length - 2
          message.context_name = data.context_name
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

    toJSON: ->
      { conversation: _.extend(super, unread: @unread()) }
