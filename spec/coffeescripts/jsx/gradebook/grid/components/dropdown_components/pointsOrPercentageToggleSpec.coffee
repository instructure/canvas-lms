define [
  'react'
  'react-dom'
  'jsx/gradebook/grid/components/dropdown_components/pointsOrPercentageToggle',
  'jsx/gradebook/grid/actions/gradebookToolbarActions',
  'compiled/gradebook2/GradeDisplayWarningDialog',
  'jquery'
], (React, ReactDOM, PointsOrPercentageToggle, GradebookToolbarActions, GradeDisplayWarningDialog, $) ->

  wrapper = document.getElementById('fixtures')
  Simulate = React.addons.TestUtils.Simulate

  renderComponent = ->
    componentFactory = React.createFactory(PointsOrPercentageToggle)
    ReactDOM.render(componentFactory(), wrapper)

  removeDialog = ->
    $dialog = $('.ui-dialog')
    if $dialog.length > 0
      $dialog.remove()
      $('#grade_display_warning_dialog').remove()

  module 'PointsOrPercentageToggle',
    setup: ->
      @component = renderComponent()
      @component.setState(
        toolbarOptions:
          showTotalGradeAsPoints: false,
          warnedAboutTotalsDisplay: false
      )
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper
      removeDialog()

  test 'mounts on build', ->
    ok renderComponent().isMounted()

  test '#totalShowingAsPoints returns true if totals are being shown as points', ->
    @component.setState({ toolbarOptions: { showTotalGradeAsPoints: true, warnedAboutTotalsDisplay: false } })
    deepEqual @component.totalShowingAsPoints(), true

  test '#toggle triggers GradebookToolbarActions#showTotalGradeAsPoints', ->
    toggleAction = @stub(GradebookToolbarActions, 'showTotalGradeAsPoints')
    @component.toggle()
    ok toggleAction.calledWith(true)

  test '#toggleAndHideWarning calls toggle() and triggers' +
  'GradebookToolbarActions#hideTotalDisplayWarning', ->
    hideWarningAction = @stub(GradebookToolbarActions, 'hideTotalDisplayWarning')
    toggle = @stub(@component, 'toggle')
    @component.toggleAndHideWarning()
    ok hideWarningAction.calledWith(true)
    ok toggle.called

  test "a warning dialog shows (if the user hasn't opted out of it) when the toggle is clicked", ->
    link = @component.refs.dropdownOption.refs.link.getDOMNode()
    Simulate.click(link)
    ok document.getElementById('grade_display_warning_dialog')

  test "a warning dialog does not show when the toggle is clicked if the user has opted out of it", ->
    @component.setState({ toolbarOptions: { warnedAboutTotalsDisplay: true, showTotalGradeAsPoints: false } })
    @stub(GradebookToolbarActions, 'showTotalGradeAsPoints')
    link = @component.refs.dropdownOption.refs.link.getDOMNode()
    Simulate.click(link)
    notOk document.getElementById('grade_display_warning_dialog')
