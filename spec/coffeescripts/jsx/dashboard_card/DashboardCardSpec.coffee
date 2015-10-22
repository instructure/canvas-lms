define [
  'react'
  'underscore'
  'jsx/dashboard_card/DashboardCard'
  'jsx/dashboard_card/CourseActivitySummaryStore'
], (React, _, DashboardCard, CourseActivitySummaryStore) ->

  TestUtils = React.addons.TestUtils

  module 'DashboardCard',
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
        href: '/courses/1',
        courseCode: '101',
        id: 1
      }
      @stub(CourseActivitySummaryStore, 'getStateForCourse', -> {})

    teardown: ->
      localStorage.clear()
      React.unmountComponentAtNode(@component.getDOMNode().parentNode)

  test 'render', ->
    DashCard = React.createElement(DashboardCard, @props)
    @component = TestUtils.renderIntoDocument(DashCard)
    $html = $(@component.getDOMNode())
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

  test 'unreadCount', ->
    DashCard = React.createElement(DashboardCard, @props)
    @component = TestUtils.renderIntoDocument(DashCard)
    ok !@component.unreadCount('icon-discussion', []),
      'should not blow up without a stream'
    equal @component.unreadCount('icon-discussion', @stream), 2,
      'should pass down unread count if stream item corresponding to icon has unread count'
