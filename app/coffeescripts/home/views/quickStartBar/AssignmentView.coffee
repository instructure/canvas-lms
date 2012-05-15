define [
  'Backbone'
  'compiled/home/models/quickStartBar/Assignment'
  'jst/quickStartBar/assignment'
  'compiled/util/formToJSON'
  'jquery.instructure_date_and_time'
], ({View}, Assignment, template, formToJSON) ->

  class AssignmentView extends View

    events:
      'submit form': 'onFormSubmit'

    initialize: ->
      @model or= new Assignment

    onFormSubmit: (event) ->
      event.preventDefault()
      $form = $ event.target
      json = formToJSON $(event.target)
      console.log json

    render: ->
      html = template @model.toJSON
      @$el.html html
      @setup()

    setup: ->
      @$('.dateField').datetime_field()

    teardown: ->

