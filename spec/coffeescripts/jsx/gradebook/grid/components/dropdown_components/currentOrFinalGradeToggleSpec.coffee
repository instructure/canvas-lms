define [
  'react'
  'react-dom'
  'jsx/gradebook/grid/components/dropdown_components/currentOrFinalGradeToggle',
  'jsx/gradebook/grid/actions/gradebookToolbarActions'
], (React, ReactDOM, CurrentOrFinalGradeToggle, GradebookToolbarActions) ->

  wrapper = document.getElementById('fixtures')
  Simulate = React.addons.TestUtils.Simulate

  renderComponent = () ->
    element = React.createElement(CurrentOrFinalGradeToggle)
    ReactDOM.render(element, wrapper)

  module 'CurrentOrFinalGradeToggle',
    setup: ->
      @component = renderComponent()
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'Displays "Show Current Grade" if treat ungraded as zero is set to true', ->
    @component.setState({ toolbarOptions: { treatUngradedAsZero: true } })
    deepEqual @component.refs.gradeToggle.props.title, 'Show Current Grade'

  test 'Displays "Show Final Grade" if treat ungraded as zero is set to false', ->
    @component.setState({ toolbarOptions: { treatUngradedAsZero: false } })
    deepEqual @component.refs.gradeToggle.props.title, 'Show Final Grade'

  test 'Fires the appropriate action when the toggle is clicked', ->
    @component.setState({ toolbarOptions: { treatUngradedAsZero: true } })
    toggleAction = @stub(GradebookToolbarActions, 'toggleTreatUngradedAsZero')
    toggleLink = @component.refs.gradeToggle.refs.link.getDOMNode()
    Simulate.click(toggleLink)
    ok toggleAction.calledWith(false)
