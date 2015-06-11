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
    equal $html.children('span.screenreader-only').length, 0,
      'should not have screenreader span'
    ok !$html.attr('class').match(/active/), 'should not be marked active'

  test 'should render span if screenreader text provided', ->
    screenreader_text = 'Screenreader Text'
    component = TestUtils.renderIntoDocument(DashboardCardAction(
      _.extend(@props, {
        screenreader: screenreader_text
      })
    ))
    $html = $(component.getDOMNode())
    equal $html.children('span.screenreader-only').length, 1,
      'should have screenreader span'
    equal $html.children('span').text(), screenreader_text
    ok $html.children('span').hasClass('screenreader-only')
    React.unmountComponentAtNode(component.getDOMNode().parentNode)

    component = TestUtils.renderIntoDocument(DashboardCardAction(
      _.extend(@props, {
        screenreader: screenreader_text,
        hasActivity: true
      })
    ))
    $html = $(component.getDOMNode())
    ok $html.children('span').text().match(/Unread/),
      'should include Unread in text if icon has activity'
    React.unmountComponentAtNode(component.getDOMNode().parentNode)

  test 'should be marked active when hasActivity', ->
    @component = TestUtils.renderIntoDocument(DashboardCardAction(
      _.extend(@props, {
        hasActivity: true
      })
    ))
    $html = $(@component.getDOMNode())
    ok $html.attr('class').match(/active/), 'should be marked active'
