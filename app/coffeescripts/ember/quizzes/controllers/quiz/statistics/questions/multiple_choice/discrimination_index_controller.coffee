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
    #   // total number of students in each bracket
    #   "total": [
    #     4, 2, 4
    #   ],
    #
    #   // % of students who got it right in each bracket
    #   "ratio": [
    #     0.75, 0.5, 0.25
    #   ]
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

      {
        correct: [ stats.top.correct, stats.mid.correct, stats.bot.correct ],
        total: [ stats.top.total, stats.mid.total, stats.bot.total ],
        ratio: [
          (1.0 * stats.top.correct / stats.top.total) || 0,
          (1.0 * stats.mid.correct / stats.mid.total) || 0,
          (1.0 * stats.bot.correct / stats.bot.total) || 0
        ]
      }
    ).property('model.{top,middle,bottom}StudentCount')