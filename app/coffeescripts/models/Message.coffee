define [
  'underscore'
  'Backbone'
], (_, {Model}) ->

  class Message extends Model

    parse: (data) ->
      if data.messages
        _.each data.messages, (message) ->
          message.author = _.find(data.participants, (p) -> p.id is message.author_id)
      data

    participantList: ->
      names = _.pluck(@get('participants'), 'name').join(', ')

    unread: ->
      @get('workflow_state') is 'unread'

    toggleReadState: (set_read) ->
      set_read ?= @unread()
      @set('workflow_state', if set_read then 'read' else 'unread')

    toJSON: ->
      { conversation: _.extend(super, participantList: @participantList(), unread: @unread()) }
