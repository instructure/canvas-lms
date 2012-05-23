define [
  'Backbone'
  'underscore'
  'compiled/home/models/quickStartBar/Discussion'
  'jst/quickStartBar/discussion'
  'jquery.instructure_date_and_time'
  'vendor/jquery.placeholder'
], ({View}, _, Discussion, template) ->

  class DiscussionView extends View

    events:
      'change [name=graded]': 'onGradedClick'

    initialize: ->
      @model or= new Discussion

    onGradedClick: (event) ->
      graded = event.target.checked
      @$('[name="assignment[points_possible]"], [name="assignment[due_at]"]').prop 'disabled', not graded
      @$('.ui-datepicker-trigger').toggleClass 'disabled', not graded

    ##
    # TODO: abstract, shared by assignmentview
    onFormSubmit: (json) ->

      # get real date
      if json.assignment?.due_at?
        json.assignment.due_at = @$('.datetime_suggest').text()

      # map the course_ids into deferreds, saving a copy for each course
      dfds = _.map json.course_ids, (id) =>
        model = new Discussion json
        model.set 'course_id', id.replace /^course_/, ''
        model.save
          success: @parentView.onSaveSuccess
          fail: @parentView.onSaveFail

      # wait for all to be saved
      dfd = $.when(dfds...).then @parentView.onSaveSuccess, @parentView.onSaveFail
      @$('form').disableWhileLoading dfd

    render: ->
      html = template @model.toJSON
      @$el.html html
      @filter()

    filter: ->
      @$('.dateField').datetime_field()
      @$('.ui-datepicker-trigger').addClass('disabled')
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


