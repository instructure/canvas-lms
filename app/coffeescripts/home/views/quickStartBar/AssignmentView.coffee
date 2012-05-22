define [
  'Backbone'
  'underscore'
  'compiled/home/models/quickStartBar/Assignment'
  'jst/quickStartBar/assignment'
  'jquery.instructure_date_and_time'
  'compiled/widget/ContextSearch'
  'jquery.disableWhileLoading'
], ({View}, _, Assignment, template, formToJSON, ContextSearch) ->

  class AssignmentView extends View

    initialize: ->
      @model or= new Assignment

    render: ->
      html = template @model.toJSON
      @$el.html html
      @setup()

    setup: ->
      @$('input[name=due_at]').datetime_field()
      @$('input[name=course_id]').contextSearch
        contexts: ENV.CONTEXTS
        placeholder: "Type the name of a class to assign this too..."
        selector:
          baseData:
            type: 'course'
          preparer: (postData, data, parent) ->
            for row in data
              row.noExpand = true
          browser: false

    onFormSubmit: (json) ->
      ids = json['course_id[]']

      # get real date
      json.date = @$('.datetime_suggest').text()

      # get rid of course_id[] from autocomplete
      delete json['course_id[]']

      if _.isArray ids
        dfd = @saveCopies ids, json
      else
        json.course_id = ids.replace /^course_/, ''
        dfd = @model.save json,
          success: @parentView.onSaveSuccess
          fail: @parentView.onSaveFail

      @$('form').disableWhileLoading dfd

    saveCopies: (ids, attrs) ->
      dfds = _.map ids, (id) =>
        model = new Assignment attrs
        model.set 'course_id', id.replace /^course_/, ''
        model.save
          success: @parentView.onSaveSuccess
          fail: @parentView.onSaveFail


      $.when(dfds...).then @parentView.onSaveSuccess #TODO onFail

