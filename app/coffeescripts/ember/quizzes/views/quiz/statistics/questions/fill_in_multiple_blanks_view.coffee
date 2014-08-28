define [ '../questions_view' ], (Base) ->
  Base.extend
    # FIMB and friends with answer sets should start out with the first set
    # pre-activated instead of showing nothing.
    preselectAnswerSet: (->
      unless @get('controller.activeAnswer')
        blankId = @get('controller.answerSets.firstObject.id')

        if blankId
          @get('controller').send('activateAnswer', blankId)
    ).on('didInsertElement')
