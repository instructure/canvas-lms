define [
  'Backbone'
  'compiled/quickStartBar/models/Assignment'
  'jst/quickStartBarTemplates/assignment'
  'jquery.instructure_date_and_time'
], ({View}, Assignment, template) ->

  class AssignmentView extends View

    render: ->
      html = template @model.toJSON
      @$el.html html
      @filter()
    
    afterRender: ->
      @$('.dateField').datetime_field()

