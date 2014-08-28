define [
  'ember'
  'vendor/d3.v3'
  '../../../shared/seconds_to_time'
], (Ember, d3, secondsToTime) ->
  {max, sum} = d3

  Ember.ObjectController.extend
    ratioFor: (score) ->
      quizPoints = parseFloat(@get('quiz.pointsPossible'))

      if quizPoints > 0
        Ember.Util.round(@get(score) / quizPoints * 100.0, 0)
      else
        0

    avgScoreRatio: (-> @ratioFor('avgScore') ).property('avgScore')
    highScoreRatio: (-> @ratioFor('highScore') ).property('highScore')
    lowScoreRatio: (-> @ratioFor('lowScore') ).property('lowScore')

    # Format a duration given in seconds into a stopwatch-style timer, e.g:
    #
    #   1 second      => 00:01
    #   30 seconds    => 00:30
    #   84 seconds    => 01:24
    #   7230 seconds  => 02:00:30
    #   7530 seconds  => 02:05:30
    #
    formattedAvgDuration: (->
      secondsToTime @get('avgDuration')
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
      set = Ember.A()
      scores = @get('submissionStatistics.scores') || {}
      highest = max(Ember.keys(scores).map (d) -> parseInt(d, 10))

      for percentile in [0..max([100, highest])]
        set[percentile] = scores["#{percentile}"] || 0

      # merge right outliers with 100%
      set[100] = sum(set.splice(100, set.length));

      set
    ).property('submissionStatistics')
