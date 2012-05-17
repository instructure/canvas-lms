define [
  'Backbone'
  'compiled/home/models/quickStartBar/Assignment'
  'jst/quickStartBar/assignment'
  'jquery.instructure_date_and_time'
], ({View}, Assignment, template, formToJSON) ->

  class AssignmentView extends View

    initialize: ->
      @model or= new Assignment

    render: ->
      html = template @model.toJSON
      @$el.html html
      @setup()

    setup: ->
      @$('.dateField').datetime_field()

    onBeforeSave: ->
      @$('button[type=submit]').html 'Saving...'
      @$(':input').attr 'disabled', true

