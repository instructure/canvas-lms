define [
  'Backbone'
  'compiled/home/models/quickStartBar/Discussion'
  'jst/quickStartBar/discussion'
  'jquery.instructure_date_and_time'
  'vendor/jquery.placeholder'
], ({View}, Discussion, template) ->

  class DiscussionView extends View

    events:
      'change [name=graded]': 'onGradedClick'

    initialize: ->
      @model or= new Discussion

    onGradedClick: (event) ->
      graded = event.target.checked
      @$('[name=points_possible], [name=due_at]').prop 'disabled', not graded
      @$('.ui-datepicker-trigger').toggleClass 'disabled', not graded

    render: ->
      html = template @model.toJSON
      @$el.html html
      @filter()

    filter: ->
      @$('.dateField').datetime_field()
      @$('.ui-datepicker-trigger').addClass('disabled')
      @$('input[type=text], textarea').placeholder()

