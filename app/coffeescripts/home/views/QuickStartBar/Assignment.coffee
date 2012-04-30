define [
  'Backbone'
  'compiled/home/models/quickStartBar/Assignment'
  'jst/quickStartBarTemplates/assignment'
  'jquery.instructure_date_and_time'
], ({View}, Assignment, template) ->

  class AssignmentView extends View

    render: ->
      html = template @model.toJSON
      @$el.html html
      @filter()
    
    filter: ->
      debugger
      @$('.dateField').datetime_field()

