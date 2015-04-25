define [
  'underscore'
  'compiled/models/grade_summary/Outcome'
  'compiled/views/grade_summary/OutcomeDialogView'
  'compiled/views/grade_summary/OutcomeLineGraphView'
], (_, Outcome, OutcomeDialogView, OutcomeLineGraphView) ->

  module 'OutcomeDialogViewSpec',
    setup: ->
      @outcomeDialogView = new OutcomeDialogView({
        model: new Outcome()
      })
      @e = (name, options={}) -> $.Event(name, _.extend(options, {
        currentTarget: @outcomeDialogView.el
      }))

  test 'assign instance of OutcomeLineGraphView on init', ->
    ok @outcomeDialogView.outcomeLineGraphView instanceof OutcomeLineGraphView

  test 'afterRender', ->
    setElementSpy = sinon.stub(@outcomeDialogView.outcomeLineGraphView, 'setElement')
    renderSpy = sinon.stub(@outcomeDialogView.outcomeLineGraphView, 'render')

    @outcomeDialogView.render()

    ok setElementSpy.called, 'should set linegraph element'
    ok renderSpy.called, 'should render line graph'

    @outcomeDialogView.outcomeLineGraphView.setElement.restore()
    @outcomeDialogView.outcomeLineGraphView.render.restore()

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
