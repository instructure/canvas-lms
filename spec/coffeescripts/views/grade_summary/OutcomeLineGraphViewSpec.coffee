define [
  'underscore'
  'compiled/models/grade_summary/Outcome'
  'compiled/collections/OutcomeResultCollection'
  'compiled/views/grade_summary/OutcomeLineGraphView'
  'timezone'
  'helpers/fakeENV'
], (_, Outcome, OutcomeResultCollection, OutcomeLineGraphView, tz, fakeENV) ->

  module 'OutcomeLineGraphViewSpec',
    setup: ->
      fakeENV.setup()
      ENV.context_asset_string = 'course_1'
      ENV.current_user = {display_name: 'Student One'}
      ENV.student_id = 6

      @server = sinon.fakeServer.create()
      @response = {
        outcome_results: [{
          submitted_or_assessed_at: tz.parse('2015-04-24T19:27:54Z')
          links: {
            alignment: 'alignment_1'
          }
        }],
        linked: {
          alignments: [{
            id: 'alignment_1'
            name: 'Alignment Name'
          }]
        }
      }

      @outcomeLineGraphView = new OutcomeLineGraphView({
        el: $('<div class="line-graph"></div>')[0]
        model: new Outcome(
          id: 2
          friendly_name: 'Friendly Outcome Name'
          mastery_points: 3
          points_possible: 5
        )
      })

    teardown: ->
      fakeENV.teardown()
      @server.restore()

  test '#initialize', ->
    ok @outcomeLineGraphView.collection instanceof OutcomeResultCollection,
      'should have an OutcomeResultCollection'
    ok !@outcomeLineGraphView.deferred.isResolved(),
      'should have unresolved promise'
    @outcomeLineGraphView.collection.trigger('fetched:last')
    ok @outcomeLineGraphView.deferred.isResolved(),
      'should resolve promise on fetched:last'

  test 'render', ->
    renderSpy = @spy(@outcomeLineGraphView, 'render')
    ok !@outcomeLineGraphView.deferred.isResolved(),
      'precondition'
    ok @outcomeLineGraphView.render()
    ok _.isUndefined(@outcomeLineGraphView.svg),
      'should not render svg if promise is unresolved'

    @outcomeLineGraphView.collection.trigger('fetched:last')
    ok renderSpy.calledTwice, 'promise should call render'
    ok _.isUndefined(@outcomeLineGraphView.svg),
      'should not render svg if collection is empty'

    @outcomeLineGraphView.collection.parse(@response)
    @outcomeLineGraphView.collection.add(
      @response['outcome_results'][0]
    )
    ok @outcomeLineGraphView.render()
    ok !_.isUndefined(@outcomeLineGraphView.svg),
      'should render svg if scores are present'
    ok @outcomeLineGraphView.$('.screenreader-only'),
      'should render table of data for screen reader'
