define [
  'vendor/usher/usher'
  'Backbone'
], (Usher, Backbone, template) ->

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

    initialize: ->
      @render()
      @$el.appendTo $(document.body)
      @tour = new Usher @$el
      @attach()

    start: =>
      @tour.start()

    attach: ->
      setTimeout @start, 2000

