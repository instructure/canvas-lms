define [
  'jquery'
  'vendor/usher/usher'
  'Backbone'
  'jquery.ajaxJSON'
], ($, Usher, Backbone, template) ->

  ##
  # Base class for all tours. A tour with the ruby name
  # :first_time_login should be found at
  # views/tours/FirstTimeLogin.coffee to be automatically included.
  #
  # examples:
  #
  #   class DiscussionTourView
  #     template: template

  class TourView extends Backbone.View

    events:
      'click .usher-close': 'dismissSession'
      'click .dismiss-tour': 'dismissForever'

    @optionProperty 'name'

    initialize: ->
      super
      @render()
      @$el.appendTo $(document.body)
      @tour = new Usher @$el
      @attachTour()

    start: =>
      @tour.start()

    attachTour: ->
      setTimeout @start, 2000

    dismissSession: ->
      $.ajaxJSON "/tours/dismiss/session/#{@name}", 'DELETE'

    dismissForever: ->
      $.ajaxJSON "/tours/dismiss/#{@name}", 'DELETE'
      @tour.close()

    ##
    # Use this when you have no hook to something being rendered
    onElementRendered: (selector, cb, _attempts) ->
      el = $(selector)
      _attempts = ++_attempts or 1
      return cb(el) if el.length
      return if _attempts is 60
      setTimeout (=> @onElementRendered(selector, cb, _attempts)), 250

