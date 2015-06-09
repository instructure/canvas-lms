define [
  'compiled/models/QuizOverrideLoader'
], (QuizOverrideLoader) ->

  module 'QuizOverrideLoader dates selection',
    setup: ->
      @loader = QuizOverrideLoader
      @latestDate = "2015-04-05"
      @middleDate = "2014-04-05"
      @earliestDate = "2013-04-05"

      @dates = [
        {due_at: @latestDate, lock_at: null, unlock_at: @middleDate},
        {due_at: @middleDate, lock_at: null, unlock_at: @earliestDate},
        {due_at: @earliestDate, lock_at: null, unlock_at: @latestDate}
      ]

    teardown: ->
      # noop

  test 'can select the latest date from a group', ->
    equal @loader._chooseLatest(@dates, "due_at"), @latestDate

  test 'can select the earliest date from a group', ->
    equal @loader._chooseEarliest(@dates, "unlock_at"), @earliestDate

  test 'ignores null dates and handles empty arrays', ->
    dates = [{},{}]
    equal @loader._chooseLatest(dates, "due_at"), null
    dates = []
    equal @loader._chooseLatest(dates, "due_at"), null
