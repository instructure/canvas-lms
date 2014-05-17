define [
  '../../../start_app'
  'ember'
  '../../../../controllers/quiz/statistics/summary_controller'
  'ember-qunit'
  '../../../environment_setup'
], (startApp, Ember, QuizStatisticsSummaryController, emq) ->

  {run} = Ember

  App = startApp()
  emq.setResolver(Ember.DefaultResolver.create({namespace: App}))

  emq.moduleFor('controller:quiz_statistics_summary', 'QuizStatisticsSummaryController', {
    setup: ->
      App = startApp()
      emq.setResolver(Ember.DefaultResolver.create({namespace: App}))
      @model = Ember.Object.create({})
      @subject = this.subject()
      @subject.set('model', @model)
    teardown: ->
      run App, 'destroy'
    }
  )

  emq.test 'sanity', ->
    ok(@subject)

  emq.test '#scoreChartData', ->
    @model.set('submissionStatistics', {})
    @model.set('submissionStatistics.scores', {
      42: 3,
      88: 12,
      100: 1
    })
    data = @subject.get('scoreChartData')
    equal data.length, 101
    equal data[42], 3
    equal data[88], 12
    equal data[100], 1

  emq.test '#scoreChartData: it considers scores over 100% as 100%', ->
    @model.set('submissionStatistics', {
      scores: {
        100: 1,
        101: 2,
        105: 2
      }
    })

    data = @subject.get('scoreChartData')
    equal data.length, 101
    equal data[100], 5

  emq.test '#formattedAvgDuration: pads durations with leading zeros', ->
    @model.set('avgDuration', 42)
    equal @subject.get('formattedAvgDuration'), '00:42'
    @model.set('avgDuration', 63)
    equal @subject.get('formattedAvgDuration'), '01:03'

  emq.test '#formattedAvgDuration: includes hours in output', ->
    @model.set('avgDuration', 3721)
    equal @subject.get('formattedAvgDuration'), '01:02:01'

  emq.test '#avgScoreRatio', ->
    @model.set('quiz', { pointsPossible: 32 })
    @model.set('avgScore', 17)
    equal @subject.get('avgScoreRatio'), 53

  emq.test '#highScoreRatio', ->
    @model.set('quiz', { pointsPossible: 32 })
    @model.set('highScore', 30)
    equal @subject.get('highScoreRatio'), 94

  emq.test '#lowScoreRatio', ->
    @model.set('quiz', { pointsPossible: 32 })
    @model.set('lowScore', 4)
    equal @subject.get('lowScoreRatio'), 13

