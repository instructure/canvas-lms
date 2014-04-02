define [ 'ember' ], (Ember) ->
  Ember.Controller.extend
    chartData: (->
      @get('model.answers').map (answer) ->
        {
          id: answer.id # we need the IDs for tooltip work
          y: answer.responses
          correct: answer.correct # correct answer bars get highlighted
        }
    ).property('model.answers')
