define [
  'underscore'
  'compiled/models/grade_summary/Outcome'
  'compiled/views/grade_summary/OutcomePopoverView'
  'compiled/views/grade_summary/OutcomeDialogView'
  'compiled/views/grade_summary/OutcomeView'
  'compiled/views/grade_summary/ProgressBarView'
], (_, Outcome, OutcomePopoverView, OutcomeDialogView, OutcomeView, ProgressBarView) ->

  module 'OutcomeViewSpec',
    setup: ->
      @outcomeView = new OutcomeView({
        el: $('<li><a class="more-details"></a></li>')
        model: new Outcome()
      })
      @e = (name, options={}) -> $.Event(name, _.extend(options, {
        currentTarget: @outcomeView.$el.find('a.more-details')
      }))

  test 'assign instance of ProgressBarView on init', ->
    ok @outcomeView.progress instanceof ProgressBarView

  test 'have after render beheavior', ->
    ok _.isUndefined(@outcomeView.popover, 'precondition')

    @outcomeView.render()

    ok @outcomeView.popover instanceof OutcomePopoverView
    ok @outcomeView.dialog instanceof OutcomeDialogView

  test 'click & keydown .more-details', ->
    @outcomeView.render()
    showSpy = sinon.stub(@outcomeView.dialog, 'show')
    @outcomeView.$el.find('a.more-details').trigger(@e('click'))
    ok showSpy.called

    showSpy.reset()

    @outcomeView.$el.find('a.more-details').trigger(@e('keydown'))
    ok showSpy.called

    @outcomeView.dialog.show.restore()
