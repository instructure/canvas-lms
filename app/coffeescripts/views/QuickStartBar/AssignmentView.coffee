define [
  'compiled/views/QuickStartBar/BaseItemView'
  'underscore'
  'compiled/models/Assignment'
  'jst/quickStartBar/assignment'
  'compiled/widget/ContextSearch'
  'jquery.instructure_date_and_time'
  'jquery.disableWhileLoading'
], (BaseItemView, _, Assignment, template, ContextSearch) ->

  class AssignmentView extends BaseItemView

    template: template

    contextSearchOptions:
      fakeInputWidth: '100%'
      contexts: ENV.CONTEXTS
      placeholder: "Type the name of a class to assign this to..."
      selector:
        baseData:
          type: 'course'
        preparer: (postData, data, parent) ->
          for row in data
            row.noExpand = true
        browser: false

    save: (json) ->
      json.date = @$('.datetime_suggest').text()
      dfds = _.map json.course_ids, (id) =>
        model = new Assignment json
        model.set 'course_id', id.replace /^course_/, ''
        model.save()
      $.when dfds...

    @type:  'assignment'
    @title: -> super 'assignment', 'Assignment'
