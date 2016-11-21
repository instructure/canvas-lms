define [
  'react'
  'react-dom'
  'jsx/gradebook/grid/components/dropdown_components/moveTotalColumnToggle',
  'jsx/gradebook/grid/actions/gradebookToolbarActions'
], (React, ReactDOM, MoveTotalColumnToggle, GradebookToolbarActions) ->

  wrapper = document.getElementById('fixtures')
  Simulate = React.addons.TestUtils.Simulate

  renderComponent = () ->
    componentFactory = React.createFactory(MoveTotalColumnToggle)
    ReactDOM.render(componentFactory(), wrapper)

  module 'MoveTotalColumnToggle',
    setup: ->
      @component = renderComponent()
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'mounts correctly', ->
    ok @component.isMounted()

  test 'Displays "Move to front" if total_column_in_front is false', ->
    @component.setState({toolbarOptions: {totalColumnInFront: false }})
    menuItem = @component.refs.moveToFront.getDOMNode()
    deepEqual menuItem.children[0].innerHTML, 'Move to front'

  test 'Displays "Move to end" if total_column_in_front is true', ->
    @component.setState({toolbarOptions: {totalColumnInFront: true }})
    menuItem = @component.refs.moveToFront.getDOMNode()
    deepEqual menuItem.children[0].innerHTML, 'Move to end'

  test 'Fires toggleTotalInFront action when toggle is clicked', ->
    @component.setState({toolbarOptions: { totalColumnInFront: true }})
    toggleAction = @stub(GradebookToolbarActions, 'toggleTotalColumnInFront')
    @component.handleClick()
    ok toggleAction.called

  test 'Calls toggleTotalInFront with false when total_column_in_front is true', ->
    @component.setState({toolbarOptions: { totalColumnInFront: true }})
    toggleAction = @stub(GradebookToolbarActions, 'toggleTotalColumnInFront')
    @component.handleClick()
    ok toggleAction.calledWith(false)

  test 'Calls toggleTotalInFront with true when total_column_in_front is false', ->
    @component.setState({toolbarOptions: { totalColumnInFront: false }})
    toggleAction = @stub(GradebookToolbarActions, 'toggleTotalColumnInFront')
    @component.handleClick()
    ok toggleAction.calledWith(true)
