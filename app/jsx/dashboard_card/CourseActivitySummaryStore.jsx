/** @jsx React.DOM */

define([
  'react',
  'underscore',
  'jsx/shared/helpers/createStore',
  'jquery',
  'compiled/backbone-ext/DefaultUrlMixin',
  'compiled/fn/parseLinkHeader',
], (React, _, createStore, $, DefaultUrlMixin) => {

  var CourseActivitySummaryStore = createStore({streams: {}})

  CourseActivitySummaryStore.getStateForCourse = function(courseId) {
    if (_.isUndefined(courseId)) return CourseActivitySummaryStore.getState()

    if (_.has(CourseActivitySummaryStore.getState()['streams'], courseId)) {
      return CourseActivitySummaryStore.getState()['streams'][courseId]
    } else {
      CourseActivitySummaryStore._fetchForCourse(courseId)
      return {}
    }
  }

  CourseActivitySummaryStore._fetchForCourse = function(courseId) {
    var state

    $.getJSON('/api/v1/courses/' + courseId + '/activity_stream/summary', function(stream) {
      state = CourseActivitySummaryStore.getState()
      state['streams'][courseId] = {
        stream: stream
      }
      CourseActivitySummaryStore.setState(state)
    })
  }

  return CourseActivitySummaryStore
});
