define [
  'Backbone'
  'compiled/home/models/quickStartBar/Message'
  'jst/quickStartBar/message'
  'jquery.instructure_date_and_time'
], ({View}, Message, template) ->

  class MessageView extends View

    initialize: ->
      @model or= new Message

    render: ->
      html = template @model.toJSON
      @$el.html html
      @filter()
    
    filter: ->
      console.profile 'datetime field'
      @$('.dateField').datetime_field()
      console.profileEnd 'datetime field'

