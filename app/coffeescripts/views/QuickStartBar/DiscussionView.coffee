define [
  'compiled/views/QuickStartBar/BaseItemView'
  'underscore'
  'compiled/models/Discussion'
  'jst/quickStartBar/discussion'
  'jquery.instructure_date_and_time'
  'vendor/jquery.placeholder'
], (BaseItemView, _, Discussion, template) ->

  class DiscussionView extends BaseItemView

    events: _.extend
      'change [name=graded]': 'onGradedClick'
    , BaseItemView::events

    template: template

    contextSearchOptions:
      fakeInputWidth: '100%'
      contexts: ENV.CONTEXTS
      placeholder: "Type the name of a class to send this too..."
      selector:
        baseData:
          type: 'course'
        preparer: (postData, data, parent) ->
          for row in data
            row.noExpand = true
        browser: false


    onGradedClick: (event) ->
      graded = event.target.checked
      @$('[name="assignment[points_possible]"], [name="assignment[due_at]"]').prop 'disabled', not graded
      @$('.ui-datepicker-trigger').toggleClass 'disabled', not graded

    save: (json) ->

      # get real date
      if json.assignment?.due_at?
        json.assignment.due_at = @$('.datetime_suggest').text()

      # map the context_ids into deferreds, saving a copy for each course
      dfds = _.map json.context_ids, (id) =>
        model = new Discussion json
        model.contextCode = id
        model.save()

      $.when dfds...

    filter: ->
      super
      @$('.ui-datepicker-trigger').addClass('disabled')

    @type:  'discussion'
    @title: -> super 'discussion', 'Discussion'
