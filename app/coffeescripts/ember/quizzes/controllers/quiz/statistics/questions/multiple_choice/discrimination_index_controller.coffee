define [ 'ember', 'underscore' ], (Ember, _) ->
  Ember.Controller.extend
    discriminationIndex: Ember.computed.alias('model.discriminationIndex')
    discriminationIndexClass: (->
      if @get('discriminationIndex') > 0.25 then 'positive' else 'negative'
    ).property('discriminationIndex')

    sign: (->
      if @get('discriminationIndex') > 0 then '+' else ''
    ).property('discriminationIndex')

    # Output looks like this:
    #
    # ```javascript
    # {
    #   // number of students in the top, middle, and bottom brackets who got
    #   // the question right (respectively)
    #   "correct": [
    #     3, 1, 1
    #   ],
    #
    #   // inverse of correct; those who didn't get it right
    #   "incorrect": [
    #     1, 2, 4
    #   ],
    #
    #   // Highest count in all brackets, regardless of correct status.
    #   //
    #   // Useful for using as an axis domain boundary.
    #   "maxPoint": 4
    # }
    # ```
    chartData: (->
      stats = {
        top:
          correct: @get('model.correctTopStudentCount')
          total: @get('model.topStudentCount')
        mid:
          correct: @get('model.correctMiddleStudentCount')
          total: @get('model.middleStudentCount')
        bot:
          correct: @get('model.correctBottomStudentCount')
          total: @get('model.bottomStudentCount')
      }

      data = {
        correct: [
          stats.top.correct, stats.mid.correct, stats.bot.correct
        ],

        incorrect: [
          stats.top.total - stats.top.correct,
          stats.mid.total - stats.mid.correct,
          stats.bot.total - stats.bot.correct
        ]
      }

      data.maxPoint = Math.max.apply Math, _.union(data.correct, data.incorrect)
      data
    ).property('model.{top,middle,bottom}StudentCount')