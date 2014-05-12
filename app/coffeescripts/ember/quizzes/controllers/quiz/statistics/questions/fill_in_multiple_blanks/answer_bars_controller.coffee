define [
  'ember'
  '../multiple_choice/answer_bars_controller'
], (Em, BaseController) ->
  BaseController.extend
    answers: Em.computed.alias('ratioCalculator.answerPool')