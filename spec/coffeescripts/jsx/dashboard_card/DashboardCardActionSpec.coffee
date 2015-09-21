define [
  'react'
  'underscore'
  'jsx/dashboard_card/DashboardCardAction'
], (React, _, DashboardCardAction) ->

  TestUtils = React.addons.TestUtils

  module 'DashboardCardAction',
    setup: ->
      @props = {
        iconClass: 'icon-assignment',
        path: '/courses/1/assignments/'
      }

    teardown: ->
      if @component?
        React.unmountComponentAtNode(@component.getDOMNode().parentNode)

  test 'should render link & i', ->
    @component = TestUtils.renderIntoDocument(DashboardCardAction(
      @props
    ))
    $html = $(@component.getDOMNode())
    equal $html.prop('tagName'), 'A', 'parent tag should be link'
    equal $html.find('i').attr('class'), @props.iconClass,
      'i tag should have provided iconClass'
    equal $html.find('span.screenreader-only').length, 0,
      'should not have screenreader span'

  test 'should render actionType as screenreader text if provided', ->
    action_type = 'Dashboard Action'
    component = TestUtils.renderIntoDocument(DashboardCardAction(
      _.extend(@props, {
        actionType: action_type
      })
    ))
    $html = $(component.getDOMNode())
    equal $html.find('span.screenreader-only').text(), action_type

  test 'should display unread count when it is greater than zero', ->
    unread_count = 2
    @component = TestUtils.renderIntoDocument(DashboardCardAction(
      _.extend(@props, {
        unreadCount: unread_count
      })
    ))
    $html = $(@component.getDOMNode())
    equal $html.find('span.unread_count').text(), unread_count,
      'should display unread count'
    equal $html.find('span.screenreader-only').text(), 'Unread',
      'should display Unread as screenreader only text'

