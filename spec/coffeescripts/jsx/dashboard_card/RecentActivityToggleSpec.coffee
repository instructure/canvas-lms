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

  test 'rendered button should reflect state by showing the appropriate icon as active', ->
    Toggle = React.createElement(RecentActivityToggle, @props)
    component = TestUtils.renderIntoDocument(Toggle)
    $html = $(React.findDOMNode(component))
    notOk $html.find('#dashboardToggleButtonStreamIcon').hasClass('dashboard-toggle-button-icon--active'),
      'The stream icon should not have an active class if recent_activity_dashboard is false'
    React.unmountComponentAtNode(component.getDOMNode().parentNode)

    Toggle = React.createElement(RecentActivityToggle, {
      recent_activity_dashboard: true
    })
    component = TestUtils.renderIntoDocument(Toggle)
    $html = $(React.findDOMNode(component))
    ok $html.find('#dashboardToggleButtonStreamIcon').hasClass('dashboard-toggle-button-icon--active'),
      'The stream icon should have an active class if recent_activity_dashboard is true'
    React.unmountComponentAtNode(component.getDOMNode().parentNode)
