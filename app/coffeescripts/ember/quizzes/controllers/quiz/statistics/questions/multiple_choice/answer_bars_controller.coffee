define [ 'ember' ], (Ember) ->
  Ember.ObjectController.extend
    chartData: (->
      @get('answers').map (answer) ->
        {
          id: answer.id # we need the IDs for tooltip work
          y: answer.responses
          correct: answer.correct # correct answer bars get highlighted
        }
    ).property('answers')