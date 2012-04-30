define [
  'Backbone'
  'compiled/home/models/quickStartBar/Pin'
  'jst/quickStartBar/pin'
  'jquery.instructure_date_and_time'
], ({View}, Pin, template) ->

  class PinView extends View

    initialize: ->
      @model or= new Pin

    render: ->
      html = template @model.toJSON
      @$el.html html
      @filter()
    
    filter: ->
      console.profile 'datetime field'
      @$('.dateField').datetime_field()
      console.profileEnd 'datetime field'

