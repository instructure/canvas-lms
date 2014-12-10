define (require) ->
  EventTracker = require('../event_tracker')
  K = require('../constants')
  $ = require('jquery')
  debugConsole = require('compiled/util/debugConsole')
  parseQuestionId = require('../util/parse_question_id')

  class QuestionFlagged extends EventTracker
    eventType: K.EVT_QUESTION_FLAGGED
    options: {
      buttonSelector: '.flag_question'
      questionSelector: '.question'
      questionMarkedClass: 'marked'
    }

    install: (deliver) ->
      $(document.body).on "click.#{@uid}", @getOption('buttonSelector'), (e) =>
        $question = $(e.target).closest(@getOption('questionSelector'))
        isFlagged = $question.hasClass(@getOption('questionMarkedClass'))
        questionId = parseQuestionId($question[0])

        debugConsole.log """
          Question #{questionId} #{
            if isFlagged then 'is now flagged' else 'is no longer flagged'
          }.
        """

        deliver({
          flagged: isFlagged,
          questionId: questionId
        })