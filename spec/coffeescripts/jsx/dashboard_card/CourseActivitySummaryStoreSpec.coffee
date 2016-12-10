define [
  'react-addons-test-utils'
  'underscore'
  'jsx/dashboard_card/CourseActivitySummaryStore'
], (TestUtils, _, CourseActivitySummaryStore) ->

  module 'CourseActivitySummaryStore',
    setup: ->
      CourseActivitySummaryStore.setState(streams: {})
      @server = sinon.fakeServer.create()
      @stream = [{
        "type": "DiscussionTopic",
        "unread_count": 2,
        "count": 7
      }, {
        "type": "Conversation",
        "unread_count": 0,
        "count": 3
      }]

    teardown: ->
      @server.restore()

  test 'getStateForCourse', ->
    ok _.has(CourseActivitySummaryStore.getStateForCourse(), 'streams'),
      'should return root state object when no courseId is provided'

    spy = @stub(CourseActivitySummaryStore, '_fetchForCourse', -> true)
    ok _.isEmpty(CourseActivitySummaryStore.getStateForCourse(1)),
      'should return empty object for course id not already in state'
    ok spy.called, 'should call _fetchForCourse to fetch stream info for course'

    CourseActivitySummaryStore.setState({
      streams: {
        1: {stream: @stream}
      }
    })
    deepEqual CourseActivitySummaryStore.getStateForCourse(1), {stream: @stream},
      'should return stream if present'

  test '_fetchForCourse', ->
    ok _.isEmpty(CourseActivitySummaryStore.getState()['streams'][1]),
      'precondition'

    @server.respondWith('GET', '/api/v1/courses/1/activity_stream/summary', [
      200, { "Content-Type": "application/json" }, JSON.stringify(@stream)])

    CourseActivitySummaryStore._fetchForCourse(1)
    @server.respond()

    deepEqual CourseActivitySummaryStore.getState()['streams'][1]['stream'], @stream,
      'should populate state based on API response'

