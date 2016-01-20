define [
  'react'
  'underscore'
  'jsx/dashboard_card/RecentActivityToggle',
  'helpers/assertions'
], (React, _, RecentActivityToggle, assertions) ->

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

  test 'it should be accessible', (assert) ->
    Toggle = React.createElement(RecentActivityToggle, @props)

    wrapper = $('<div>').appendTo('body')[0]

    component = React.render(Toggle, wrapper)

    $html = $(React.findDOMNode(component))

    done = assert.async()
    assertions.isAccessible $html, done

    React.unmountComponentAtNode(component.getDOMNode().parentNode)
    wrapper.remove()
