define [
  'Backbone'
  'underscore'
  'compiled/home/models/quickStartBar/Assignment'
  'jst/quickStartBar/assignment'
  'compiled/widget/ContextSearch'
  'jquery.instructure_date_and_time'
  'jquery.disableWhileLoading'
], ({View}, _, Assignment, template, ContextSearch) ->

  class AssignmentView extends View

    initialize: ->
      @model or= new Assignment

    render: ->
      html = template @model.toJSON
      @$el.html html
      @filter()

    filter: ->
      @$('input[name=due_at]').datetime_field()
      @$('input[name=course_ids]').contextSearch
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
      json.date = @$('.datetime_suggest').text()
      dfds = _.map json.course_ids, (id) =>
        model = new Assignment json
        model.set 'course_id', id.replace /^course_/, ''
        model.save
          success: @parentView.onSaveSuccess
          fail: @parentView.onSaveFail
      dfd = $.when(dfds...).then @parentView.onSaveSuccess, @parentView.onSaveFail
      @$('form').disableWhileLoading dfd

