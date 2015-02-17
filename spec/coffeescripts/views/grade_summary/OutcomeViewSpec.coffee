define [
  'underscore'
  'compiled/models/grade_summary/Outcome'
  'compiled/views/grade_summary/OutcomeLineGraphView'
  'compiled/views/grade_summary/OutcomePopoverView'
  'compiled/views/grade_summary/OutcomeView'
  'compiled/views/grade_summary/ProgressBarView'
], (_, Outcome, OutcomeLineGraphView, OutcomePopoverView, OutcomeView, ProgressBarView) ->

  module 'OutcomeViewSpec',
    setup: ->
      @outcomeView = new OutcomeView(model: new Outcome())

  test 'assign instance of ProgressBarView on init', ->
    ok @outcomeView.progress instanceof ProgressBarView

  test 'have after render beheavior', ->
    ok _.isUndefined(@outcomeView.outcomeLineGraphView, 'precondition')
    ok _.isUndefined(@outcomeView.popover, 'precondition')

    @outcomeView.render()

    ok @outcomeView.outcomeLineGraphView instanceof OutcomeLineGraphView
    ok @outcomeView.popover instanceof OutcomePopoverView

    spies = [
      sinon.spy(@outcomeView.outcomeLineGraphView, 'setElement'),
      sinon.spy(@outcomeView.outcomeLineGraphView, 'render')
    ]

    @outcomeView.popover.trigger('outcomes:popover:open')
    _.each(spies, (spy) ->
      ok spy.called
    )

