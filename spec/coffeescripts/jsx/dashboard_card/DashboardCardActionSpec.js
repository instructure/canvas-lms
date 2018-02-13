#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'react'
  'react-dom'
  'react-addons-test-utils'
  'underscore'
  'jsx/dashboard_card/DashboardCardAction'
], ($, React, ReactDOM, TestUtils, _, DashboardCardAction) ->

  QUnit.module 'DashboardCardAction',
    setup: ->
      @props = {
        iconClass: 'icon-assignment',
        path: '/courses/1/assignments/'
      }

    teardown: ->
      if @component?
        ReactDOM.unmountComponentAtNode(@component.getDOMNode().parentNode)

  test 'should render link & i', ->
    @component = TestUtils.renderIntoDocument(React.createElement(DashboardCardAction,
      @props
    ))
    $html = $(@component.getDOMNode())
    equal $html.prop('tagName'), 'A', 'parent tag should be link'
    equal $html.find('i').attr('class'), @props.iconClass,
      'i tag should have provided iconClass'
    equal $html.find('span.screenreader-only').length, 0,
      'should not have screenreader span'

  test 'should render actionType as screenreader text if provided', ->
    screen_reader_label = 'Dashboard Action'
    component = TestUtils.renderIntoDocument(React.createElement(DashboardCardAction,
      _.extend(@props, {
        screenReaderLabel: screen_reader_label
      })
    ))
    $html = $(component.getDOMNode())
    equal $html.find('span.screenreader-only').text(), screen_reader_label

  test 'should display unread count when it is greater than zero', ->
    unread_count = 2
    @component = TestUtils.renderIntoDocument(React.createElement(DashboardCardAction,
      _.extend(@props, {
        unreadCount: unread_count
      })
    ))
    $html = $(@component.getDOMNode())
    equal $html.find('span.unread_count').text(), unread_count,
      'should display unread count'
    equal $html.find('span.screenreader-only').text(), 'Unread',
      'should display Unread as screenreader only text'

