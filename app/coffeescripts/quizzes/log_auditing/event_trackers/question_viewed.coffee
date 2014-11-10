define (require) ->
  EventTracker = require('../event_tracker')
  K = require('../constants')
  $ = require('jquery')
  inViewport = require('compiled/jquery/expressions/in_viewport')
  debugConsole = require('compiled/util/debugConsole')
  parseQuestionId = require('../util/parse_question_id')

  class QuestionViewed extends EventTracker
    eventType: K.EVT_QUESTION_VIEWED
    options: {
      frequency: 2500
    }

    install: (deliver) ->
      viewed = []

      @bind window, 'scroll', =>
        newlyViewed = @identifyVisibleQuestions().filter (questionId) ->
          viewed.indexOf(questionId) == -1

        if newlyViewed.length > 0
          viewed = viewed.concat(newlyViewed)

          debugConsole.log """
            Student has just viewed the following questions: #{newlyViewed}.
            (Questions viewed up until now are: #{viewed})
          """

          deliver(newlyViewed)

      , throttle: @getOption('frequency')

    identifyVisibleQuestions: ->
      $('.question[id]:visible')
        .filter(':in_viewport')
        .toArray()
        .map parseQuestionId