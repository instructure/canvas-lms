define [
  'react'
  'react-dom'
  'jsx/gradebook/grid/components/dropdown_components/gradebookKyleMenu'
  'jsx/gradebook/grid/components/dropdown_components/totalHeaderDropdownOptions'
  'underscore'
  'jquery'
  'compiled/jquery.kylemenu'
], (React, ReactDOM, GradebookKyleMenu, DropdownOptions, _, $) ->

  wrapper = document.getElementById('fixtures')
  Simulate = React.addons.TestUtils.Simulate

  renderComponent = (data) ->
    componentFactory = React.createFactory(GradebookKyleMenu)
    $("<div id='append'></div>").appendTo('#fixtures')
    childFactory = React.createFactory(DropdownOptions)
    child = childFactory({ idAttribute: 'dropdownOptions'})
    ReactDOM.render(componentFactory(data, child), wrapper)

  module 'GradebookKyleMenu',
    setup: ->
      @dropdown = renderComponent({
        dropdownOptionsId: 'dropdownOptions',
        idToAppendTo: 'append',
        screenreaderText: 'test dropdown',
        defaultClassNames: 'test-menu'
      })
      @dropdownLink = @dropdown.refs.dropdownLink.getDOMNode()

    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'dropdown options are not shown until the user clicks on the link', ->
    notOk @dropdown.state.showMenu
    Simulate.click(@dropdownLink)
    ok @dropdown.state.showMenu

  test 'the dropdown link gets the appropriate classes when the menu pops open', ->
    event = { type: 'popupopen' }
    @dropdown.handleMenuPopup(event)
    linkClassNames = @dropdown.refs.dropdownLink.props.className
    ok linkClassNames.indexOf('ui-menu-trigger-menu-is-open') >= 0
