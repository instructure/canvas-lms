define [
  'jquery'
  'underscore'
  'jsx/grading/tabContainer'
  'jqueryui/tabs'
], ($, _, TabContainer) ->

  TestUtils = React.addons.TestUtils

  module 'TabContainer',
    renderComponent: (props) ->
      element = React.createElement(TabContainer, props)
      TestUtils.renderIntoDocument(element)

    unmount: (component) ->
      React.unmountComponentAtNode(React.findDOMNode(component).parentNode)

  test 'does not render grading periods if Multiple Grading Periods is disabled', ->
    component = @renderComponent(multipleGradingPeriodsEnabled: false)
    notOk component.refs.gradingPeriods
    @unmount(component)

  test 'renders the grading periods if Multiple Grading Periods is enabled', ->
    component = @renderComponent(multipleGradingPeriodsEnabled: true)
    ok component.refs.gradingPeriods
    @unmount(component)

  test 'renders the grading standards if Multiple Grading Periods is disabled', ->
    component = @renderComponent(multipleGradingPeriodsEnabled: false)
    ok component.refs.gradingStandards
    @unmount(component)

  test 'renders the grading standards if Multiple Grading Periods is enabled', ->
    component = @renderComponent(multipleGradingPeriodsEnabled: true)
    ok component.refs.gradingStandards
    @unmount(component)
