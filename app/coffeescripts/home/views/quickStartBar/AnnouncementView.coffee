define [
  'Backbone'
  'underscore'
  'compiled/home/models/quickStartBar/Announcement'
  'jst/quickStartBar/announcement'
  'jquery.instructure_date_and_time'
], ({View}, _, Announcement, template) ->

  class AnnouncementView extends View

    initialize: ->
      @model or= new Announcement

    onFormSubmit: (json) ->

      # get real date
      if json.assignment?.due_at?
        json.assignment.due_at = @$('.datetime_suggest').text()

      # map the course_ids into deferreds, saving a copy for each course
      dfds = _.map json.course_ids, (id) =>
        model = new Announcement json
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
      @$('input[name=course_ids]').contextSearch
        contexts: ENV.CONTEXTS
        placeholder: "Type the name of a class to announce this too..."
        selector:
          baseData:
            type: 'course'
          preparer: (postData, data, parent) ->
            for row in data
              row.noExpand = true
          browser: false



