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
    @component = TestUtils.renderIntoDocument(DashboardCard(@props))
    $html = $(@component.getDOMNode())
    ok $html.attr('class').match(/DashboardCard/)

    renderSpy = sinon.spy(@component, 'render')
    ok !renderSpy.called, 'precondition'
    CourseActivitySummaryStore.setState({
      streams: {
        1: {
          stream: @stream
        }
      }
    })
    ok renderSpy.called, 'should re-render on state update'
    @component.render.restore()

  test 'backgroundColor', ->
    ok _.isUndefined(localStorage['canvas.dashboard.color.1']),
      'precondition'
    @component = TestUtils.renderIntoDocument(DashboardCard(@props))
    ok !_.isUndefined(localStorage['canvas.dashboard.color.1']),
      'should store color in localStorage'

  test 'hasActivity', ->
    @component = TestUtils.renderIntoDocument(DashboardCard(@props))
    ok !@component.hasActivity('icon-discussion', @component.props.id),
      'should not blow up without a stream'

    @component.state = {
      stream: @stream
    }
    ok @component.hasActivity('icon-discussion', @component.props.id),
      'should be active if stream item corresponding to icon has unread count'
    ok !@component.hasActivity('icon-announcement', @component.props.id),
      'should not be active if stream item corresponding to icon has no unread count'
