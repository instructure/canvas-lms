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
  'jsx/dashboard_card/DashboardCard'
  'jsx/dashboard_card/CourseActivitySummaryStore',
  'helpers/assertions'
], ($, React, ReactDOM, TestUtils, _, DashboardCard, CourseActivitySummaryStore, assertions) ->

  QUnit.module 'DashboardCard',
    setup: ->
      @stream = [{
        "type": "DiscussionTopic",
        "unread_count": 2,
        "count": 7
      }, {
        "type": "Announcement",
        "unread_count": 0,
        "count": 3
      }]
      @props = {
        shortName: 'Bio 101',
        originalName: 'Biology',
        assetString: 'foo',
        href: '/courses/1',
        courseCode: '101',
        id: '1',
        backgroundColor: '#EF4437',
        image: null,
        imagesEnabled: false
      }
      @stub(CourseActivitySummaryStore, 'getStateForCourse').returns({})

    teardown: ->
      localStorage.clear()
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@component).parentNode)
      @wrapper.remove() if @wrapper

  test 'render', ->
    DashCard = React.createElement(DashboardCard, @props)
    @component = TestUtils.renderIntoDocument(DashCard)
    $html = $(ReactDOM.findDOMNode(@component))
    ok $html.attr('class').match(/DashboardCard/)

    renderSpy = @spy(@component, 'render')
    ok !renderSpy.called, 'precondition'
    CourseActivitySummaryStore.setState({
      streams: {
        1: {
          stream: @stream
        }
      }
    })
    ok renderSpy.called, 'should re-render on state update'

  test 'it should be accessible', (assert) ->
    DashCard = React.createElement(DashboardCard, @props)

    @wrapper = $('<div>').appendTo('body')[0]

    @component = ReactDOM.render(DashCard, @wrapper)

    $html = $(ReactDOM.findDOMNode(@component))

    done = assert.async()
    assertions.isAccessible $html, done

  test 'unreadCount', ->
    DashCard = React.createElement(DashboardCard, @props)
    @component = TestUtils.renderIntoDocument(DashCard)
    ok !@component.unreadCount('icon-discussion', []),
      'should not blow up without a stream'
    equal @component.unreadCount('icon-discussion', @stream), 2,
      'should pass down unread count if stream item corresponding to icon has unread count'

  test 'does not have image attribute when a url is not provided', ->
    @props.imagesEnabled = true
    DashCard = React.createElement(DashboardCard, @props)
    @component = TestUtils.renderIntoDocument(DashCard)
    ok TestUtils.scryRenderedDOMComponentsWithClass(@component, 'ic-DashboardCard__header_image').length == 0,
      'image attribute should not be present'

  test 'has image attribute when url is provided', ->
    @props.imagesEnabled = true
    @props.image = 'http://coolUrl'
    DashCard = React.createElement(DashboardCard, @props)
    @component = TestUtils.renderIntoDocument(DashCard)
    $html = TestUtils.findRenderedDOMComponentWithClass(@component, 'ic-DashboardCard__header_image')
    ok $html, 'image showing'

