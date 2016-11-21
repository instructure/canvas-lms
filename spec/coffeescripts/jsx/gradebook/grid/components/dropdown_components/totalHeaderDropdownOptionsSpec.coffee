define [
  'react'
  'react-dom'
  'jsx/gradebook/grid/components/dropdown_components/totalHeaderDropdownOptions'
  'helpers/fakeENV'
  'jsx/gradebook/grid/constants'
], (React, ReactDOM, DropdownOptions, fakeENV, GradebookConstants) ->

  wrapper = document.getElementById('fixtures')

  renderComponent = (data) ->
    componentFactory = React.createFactory(DropdownOptions)
    ReactDOM.render(componentFactory(data), wrapper)

  module 'TotalHeaderDropdownOptions',
    setup: ->
      @component = renderComponent({ idAttribute: 'dropdownOptions'})
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'includes options for Switch to Points and Move to Front', ->
    ok @component.refs.switchToPoints
    ok @component.refs.moveToFront

  test 'includes a toggle for current grade/final grade', ->
    ok @component.refs.currentOrFinalToggle

  module 'TotalHeaderDropdownOptions with percent group weighting scheme',
    setup: ->
      fakeENV.setup({ GRADEBOOK_OPTIONS: { group_weighting_scheme: 'percent' } })
      GradebookConstants.refresh()
      @component = renderComponent({ idAttribute: 'dropdownOptions'})
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper
      fakeENV.teardown()

  test 'does not includes an option for Switch to Points', ->
    notOk @component.refs.switchToPoints
