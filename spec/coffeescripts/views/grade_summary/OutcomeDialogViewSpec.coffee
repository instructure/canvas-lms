define [
  'underscore'
  'compiled/models/grade_summary/Outcome'
  'compiled/views/grade_summary/OutcomeDialogView'
], (_, Outcome, OutcomeDialogView) ->

  module 'OutcomeDialogViewSpec',
    setup: ->
      @outcomeDialogView = new OutcomeDialogView({
        model: new Outcome()
      })
      @e = (name, options={}) -> $.Event(name, _.extend(options, {
        currentTarget: @outcomeDialogView.el
      }))

  test '#show', ->
    renderSpy = sinon.stub(@outcomeDialogView, 'render')
    dialogSpy = sinon.stub(@outcomeDialogView.$el, 'dialog')

    @outcomeDialogView.show(@e('mouseenter'))
    ok !renderSpy.called, 'should not render on any event'
    ok !dialogSpy.called, 'should not open dialog on any event'

    # enter; space
    _.each([13, 32], (i) =>
      @outcomeDialogView.show(@e('mouseenter', keyCode: i))
      ok renderSpy.called, "should render with keyCode #{i}"
      ok dialogSpy.called, "should open dialog with keyCode #{i}"
      renderSpy.reset()
      dialogSpy.reset()
    )

    # backspace; escape
    _.each([8, 27], (i) =>
      @outcomeDialogView.show(@e('mouseenter', keyCode: i))
      ok !renderSpy.called, "should not render with keyCode #{i}"
      ok !dialogSpy.called, "should not open dialog with keyCode #{i}"
    )

    @outcomeDialogView.show(@e('click'))
    ok renderSpy.called, "should render with click"
    ok dialogSpy.called, "should open dialog with click"
    renderSpy.reset()
    dialogSpy.reset()

    @outcomeDialogView.render.restore()
    @outcomeDialogView.$el.dialog.restore()

  test 'toJSON', ->
    ok @outcomeDialogView.toJSON()['dialog'], 'should include dialog key'
