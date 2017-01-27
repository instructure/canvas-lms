import React from 'react'
import _ from 'underscore'
import createStore from 'jsx/shared/helpers/createStore'
import $ from 'jquery'
import DefaultUrlMixin from 'compiled/backbone-ext/DefaultUrlMixin'
import 'compiled/fn/parseLinkHeader'

  var CourseActivitySummaryStore = createStore({streams: {}})

  CourseActivitySummaryStore.getStateForCourse = function(courseId) {
    if (_.isUndefined(courseId)) return CourseActivitySummaryStore.getState()

    if (_.has(CourseActivitySummaryStore.getState()['streams'], courseId)) {
      return CourseActivitySummaryStore.getState()['streams'][courseId]
    } else {
      CourseActivitySummaryStore.getState()['streams'][courseId] = {}
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

export default CourseActivitySummaryStore
