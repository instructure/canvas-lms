define [
  'compiled/views/QuickStartBar/BaseItemView'
  'jquery'
  'underscore'
  'compiled/models/QuickStartAssignment'
  'jst/quickStartBar/assignment'
  'compiled/widget/ContextSearch'
  'jquery.instructure_date_and_time'
  'jquery.disableWhileLoading'
], (BaseItemView, $, _, QuickStartAssignment, template, ContextSearch) ->

  class AssignmentView extends BaseItemView

    template: template

    contextSearchOptions:
      fakeInputWidth: '100%'
      contexts: ENV.CONTEXTS
      placeholder: "Type the name of a class to assign this to..."
      selector:
        baseData:
          type: 'course'
        noExpand: true
        browser: false

    save: (json) ->
      json.date = @$('.datetime_suggest').text()
      dfds = _.map json.course_ids, (id) =>
        model = new QuickStartAssignment json
        model.set 'course_id', id.replace /^course_/, ''
        model.save()
      $.when dfds...

    @type:  'assignment'
    @title: -> super 'assignment', 'Assignment'
