define [
  'react'
  'underscore'
  'jsx/dashboard_card/RecentActivityToggle'
], (React, _, RecentActivityToggle) ->

  TestUtils = React.addons.TestUtils

  module 'RecentActivityToggle',
    setup: ->
      @props = {
        recent_activity_dashboard: false
      }

  test 'rendered input checked value should reflect state', ->
    component = TestUtils.renderIntoDocument(RecentActivityToggle(
      @props
    ))
    $html = $(component.getDOMNode())
    ok !$html.find('input').prop('checked'),
      'should not be checked if recent_activity_dashboard is false'
    React.unmountComponentAtNode(component.getDOMNode().parentNode)

    component = TestUtils.renderIntoDocument(RecentActivityToggle({
      recent_activity_dashboard: true
    }))
    $html = $(component.getDOMNode())
    ok $html.find('input').prop('checked'),
      'should be checked if recent_activity_dashboard is true'
    React.unmountComponentAtNode(component.getDOMNode().parentNode)
