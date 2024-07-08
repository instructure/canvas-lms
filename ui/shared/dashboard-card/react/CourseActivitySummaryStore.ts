/*
 * Copyright (C) 2015 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {defaultFetchOptions, asJson} from '@canvas/util/xhr'
import createStore, {type CanvasStore} from '@canvas/backbone/createStore'
import {fetchActivityStreamSummariesAsync} from '../dashboardCardQueries'
import {mapActivityStreamSummaries} from '../util/dashboardUtils'
import type {ActivityStreamSummary} from '../types'

type Stream = unknown[]

type Streams = Record<string, {stream?: Stream}>

const CourseActivitySummaryStore: CanvasStore<{
  streams: Streams
  isFetching?: boolean
}> & {
  _fetchForCourse?: (courseId: string) => Promise<void>
  getStateForCourse?: (courseId: string) => {streams: Streams} | {stream?: Stream} | undefined
  _batchLoadSummaries?: (userID: string) => void
  _fetchActivityStreamSummaries?: (userID: string) => Promise<void>
} = createStore({streams: {}})

CourseActivitySummaryStore.getStateForCourse = function (courseId?: string) {
  if (typeof courseId === 'undefined') return CourseActivitySummaryStore.getState()

  const {streams, isFetching} = CourseActivitySummaryStore.getState()
  if (!(courseId in streams)) {
    streams[courseId] = {}

    if (ENV.FEATURES?.dashboard_graphql_integration && ENV?.current_user_id) {
      if (!isFetching) {
        CourseActivitySummaryStore._batchLoadSummaries?.(ENV.current_user_id)
      }
    } else {
      CourseActivitySummaryStore._fetchForCourse?.(courseId)
    }
  }
  return streams[courseId]
}

CourseActivitySummaryStore._fetchForCourse = function (courseId: string) {
  // @ts-expect-error
  return asJson(
    window.fetch(`/api/v1/courses/${courseId}/activity_stream/summary`, defaultFetchOptions())
  ).then((stream: Stream) => {
    const state = CourseActivitySummaryStore.getState()
    state.streams[courseId] = {stream}
    CourseActivitySummaryStore.setState(state)
  })
}

CourseActivitySummaryStore._batchLoadSummaries = function (userID: string) {
  const state = CourseActivitySummaryStore.getState()
  state.isFetching = true
  CourseActivitySummaryStore.setState(state)
  CourseActivitySummaryStore._fetchActivityStreamSummaries?.(userID).then((response: any) => {
    const newStreams: Streams = {}
    mapActivityStreamSummaries(response).forEach((courseSummary: ActivityStreamSummary) => {
      newStreams[courseSummary.id] = {stream: courseSummary.summary}
    })
    CourseActivitySummaryStore.setState({
      streams: newStreams,
      isFetching: false,
    })
  })
}

// for spy purposes
CourseActivitySummaryStore._fetchActivityStreamSummaries = function (userID: string) {
  return fetchActivityStreamSummariesAsync({userID})
}

export default CourseActivitySummaryStore
