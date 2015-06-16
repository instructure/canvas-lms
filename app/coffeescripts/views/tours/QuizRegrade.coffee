define [
  'jquery'
  'compiled/views/TourView'
  'jst/tours/QuizRegrade'
  'vendor/usher/usher'
], ($, TourView, template, Usher) ->

  class QuizRegrade extends TourView

    template: template

    attachTour: ->
      $(document).one 'click', '.select_answer_link', =>
        setTimeout =>
          @tour.start()
        , 500
