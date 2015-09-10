define [
  'jsx/gradebook/grid/components/currentOrFinalGradeToggle',
  'jsx/gradebook/grid/actions/gradebookToolbarActions'
], (CurrentOrFinalGradeToggle, GradebookToolbarActions) ->

  wrapper = document.getElementById('fixtures')
  Simulate = React.addons.TestUtils.Simulate

  renderComponent = () ->
    componentFactory = React.createFactory(CurrentOrFinalGradeToggle)
    React.render(componentFactory(), wrapper)

  module 'CurrentOrFinalGradeToggle',
    setup: ->
      @component = renderComponent()
    teardown: ->
      React.unmountComponentAtNode wrapper

  test 'Displays "Show Current Grade" if treat ungraded as zero is set to true', ->
    @component.setState({ toolbarOptions: { treatUngradedAsZero: true } })
    deepEqual @component.refs.gradeToggle.props.children, 'Show Current Grade'

  test 'Displays "Show Final Grade" if treat ungraded as zero is set to false', ->
    @component.setState({ toolbarOptions: { treatUngradedAsZero: false } })
    deepEqual @component.refs.gradeToggle.props.children, 'Show Final Grade'

  test 'Fires the appropriate action when the toggle is clicked', ->
    @component.setState({ toolbarOptions: { treatUngradedAsZero: true } })
    toggleAction = @stub(GradebookToolbarActions, 'toggleTreatUngradedAsZero')
    Simulate.click(@component.refs.gradeToggle)
    ok toggleAction.calledWith(false)
