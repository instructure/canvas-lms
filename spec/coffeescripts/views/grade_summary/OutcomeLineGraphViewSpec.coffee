define [
  'underscore'
  'compiled/models/grade_summary/Outcome'
  'compiled/views/grade_summary/OutcomeLineGraphView'
  'timezone'
  'helpers/fakeENV'
], (_, Outcome, OutcomeLineGraphView, tz, fakeENV) ->

  module 'OutcomeLineGraphViewSpec',
    setup: ->
      fakeENV.setup()
      ENV.current_user = {display_name: 'Student One'}

      @outcomeLineGraphView = new OutcomeLineGraphView({
        el: $('<div class="line-graph"></div>')[0]
        model: new Outcome(
          friendly_name: 'Friendly Outcome Name'
          scores: []
        )
      })
      @scores = [{
        assessed_at: tz.parse('2015-02-01T12:30:40Z')
        score:5
      }, {
        assessed_at: tz.parse('2015-02-02T12:30:40Z')
        score:1
      }, {
        assessed_at: tz.parse('2015-02-03T12:30:40Z')
        score:2
      }]

    teardown: ->
      fakeENV.teardown()

  test 'render', ->
    ok @outcomeLineGraphView.render()
    ok _.isUndefined(@outcomeLineGraphView.svg),
      'should not render svg if no scores are present'

    ok @outcomeLineGraphView.model.set(scores: @scores)
    ok @outcomeLineGraphView.render()
    ok !_.isUndefined(@outcomeLineGraphView.svg),
      'should render svg if scores are present'
    ok @outcomeLineGraphView.$('.screenreader-only'),
      'should render table of data for screen reader'
