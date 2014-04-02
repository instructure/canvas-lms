define [
  'ember'
  'underscore'
], (Ember, _) ->
  Ember.ObjectController.extend
    ratioFor: (score) ->
      quizPoints = Math.max(@get('model.quiz.pointsPossible'), 1) # avoid division by zero
      ratio = @get("model.#{score}") / quizPoints
      Math.round (ratio * 100.0)

    avgScoreRatio: (->
      @ratioFor('avgScore')
    ).property('avgScore')

    highScoreRatio: (->
      @ratioFor('highScore')
    ).property('highScore')

    lowScoreRatio: (->
      @ratioFor('lowScore')
    ).property('lowScore')

    # Format a duration given in seconds into a stopwatch-style timer, e.g:
    #
    #   1 second      => 00:01
    #   30 seconds    => 00:30
    #   84 seconds    => 01:24
    #   7230 seconds  => 02:00:30
    #   7530 seconds  => 02:05:30
    #
    formattedAvgDuration: (->
      floor = Math.floor
      seconds = @get('model.avgDuration')
      pad = (duration) ->
        ('00' + duration).slice(-2)

      if seconds > 3600
        hh = floor (seconds / 3600)
        mm = floor ((seconds - hh*3600) / 60)
        ss = seconds % 60
        "#{pad hh}:#{pad mm}:#{pad ss}"
      else
        "#{pad floor seconds / 60}:#{pad floor seconds % 60}"
    ).property('avgDuration')

    # Convert the percentile-score map into an array of 101 elements to
    # represent scores from 0% to 100%.
    #
    # For a score map that looks like this:
    #   {
    #     29: 1,
    #     30: 1,
    #     33: 3,
    #     35: 5,
    #     36: 4,
    #     39: 1,
    #     40: 1,
    #     42: 2,
    #     44: 5,
    #     46: 6,
    #     52: 4,
    #     54: 7,
    #     55: 8,
    #     61: 1,
    #     66: 1,
    #     67: 2,
    #     73: 4,
    #     76: 3
    #   }
    #
    # Output will look like this:
    #   [
    #     0,0, 0,0, 0,0, 0,0, 0,0, // 0-9
    #     0,0, 0,0, 0,0, 0,0, 0,0, // 10-19
    #     0,0, 0,0, 0,0, 0,0, 0,1, // 20-29
    #     1,0, 0,3, 0,5, 4,0, 0,1, // 30-39
    #     1,0, 2,0, 5,0, 6,0, 0,0, // 40-49
    #     0,0, 4,0, 7,8, 0,0, 0,0, // 50-59
    #     0,1, 0,0, 0,0, 1,2, 0,0, // 60-69
    #     0,0, 0,4, 0,0, 3,0, 0,0, // 70-79
    #     0,0, 0,0, 0,0, 0,0, 0,0, // 80-89
    #     0,0, 0,0, 0,0, 0,0, 0,0, // 90-99
    #     0 // 100
    #   ]
    scoreChartData: (->
      set = []
      scores = @get('model.submissionStatistics.scores') || {}

      for percentile in [0..100]
        set[percentile] = scores["#{percentile}"] || 0

      set
    ).property('model.submissionStatistics')
