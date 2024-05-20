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

type Stream = unknown[]

type Streams = Record<string, {stream?: Stream}>

const CourseActivitySummaryStore: CanvasStore<{
  streams: Streams
}> & {
  _fetchForCourse?: (courseId: string) => Promise<void>
  getStateForCourse?: (courseId: string) => {streams: Streams} | {stream?: Stream} | undefined
} = createStore({streams: {}})

CourseActivitySummaryStore.getStateForCourse = function (courseId?: string) {
  if (typeof courseId === 'undefined') return CourseActivitySummaryStore.getState()

  const {streams} = CourseActivitySummaryStore.getState()
  if (!(courseId in streams)) {
    streams[courseId] = {}
    CourseActivitySummaryStore._fetchForCourse?.(courseId)
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

export default CourseActivitySummaryStore
