/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import type {AssignmentWeightening, CoursePace, OptionalDate, PaceContextTypes, Progress, WorkflowStates} from '../types'
import doFetchApi from '@canvas/do-fetch-api-effect'

enum ApiMode {
  PUBLISH,
  COMPRESS,
}

/* API helpers */

/*
  This helper is useful if you've got an async action that you don't want to execute until another
  is complete to avoid race consitions.

  Example: changing anything on the page will autosave, but the user might also hit the publish
  at the same time. If they publish while the autosave is still happening you can get race condition
  bugs. So when publishing we can this to wait until the autosave completes before we allow a publish.
*/
export const waitForActionCompletion = (actionInProgress: () => boolean, waitTime = 1000) => {
  return new Promise((resolve, reject) => {
    const staller = (
      actionInProgress: () => boolean,
      waitTime: number,
      // @ts-expect-error
      innerResolve,
      // @ts-expect-error
      innerReject,
    ) => {
      if (actionInProgress()) {
        setTimeout(() => staller(actionInProgress, waitTime, innerResolve, innerReject), waitTime)
      } else {
        innerResolve('done')
      }
    }

    staller(actionInProgress, waitTime, resolve, reject)
  })
}

/* API methods */

export const update = (coursePace: CoursePace, extraSaveParams = {}) =>
  doFetchApi<{course_pace: CoursePace; progress: Progress}>({
    path: `/api/v1/courses/${coursePace.course_id}/course_pacing/${coursePace.id}`,
    method: 'PUT',
    body: {
      ...extraSaveParams,
      course_pace: transformCoursePaceForApi(coursePace),
    },
  }).then(({json}) => json)

  export const create = (coursePace: CoursePace, extraSaveParams = {}) =>
  doFetchApi<{course_pace: CoursePace; progress: Progress}>({
    path: `/api/v1/courses/${coursePace.course_id}/course_pacing`,
    method: 'POST',
    body: {
      ...extraSaveParams,
      course_pace: transformCoursePaceForApi(coursePace),
    },
  }).then(({json}) => json)

export const createBulkPace = (coursePace: CoursePace, enrollmentIds: string[]) =>
  doFetchApi<{course_pace: CoursePace; progress: Progress}>({
    path: `/api/v1/courses/${coursePace.course_id}/course_pacing/bulk_create_enrollment_paces`,
    method: 'POST',
    body: {
      course_id: coursePace.course_id,
      course_section_id: null,
      user_id: null,
      hard_end_dates: null,
      course_pace: transformCoursePaceForApi(coursePace),
      enrollment_ids: enrollmentIds
    },
  }).then(({json}) => json)

// This is now just a convenience function for creating/update depending on the
// state of the pace
export const publish = (pace: CoursePace) => (pace?.id ? update(pace) : create(pace))

export const getPublishProgress = (progressId: string) =>
  doFetchApi<Progress>({
    path: `/api/v1/progress/${progressId}`,
  }).then(({json}) => json)

export const resetToLastPublished = (contextType: PaceContextTypes, contextId: string) =>
  doFetchApi<{course_pace: CoursePace}>({
    path: `/api/v1/course_pacing/reset_to_last_published`,
    method: 'POST',
    body: {
      context_type: contextType,
      context_id: contextId,
    },
  }).then(({json}) => json?.course_pace)

export const load = (coursePaceId: string) =>
  doFetchApi<CoursePace>({path: `/api/v1/course_pacing/${coursePaceId}`}).then(({json}) => json)

  export const getNewCoursePaceFor = (
    courseId: string,
    context: PaceContextTypes,
    contextId: string,
    isBulkEnrollment: boolean
  ) => {

    const baseUrl = `/api/v1/courses/${courseId}/course_pacing/new`
  
    const url = isBulkEnrollment || context === 'Enrollment'
      ?  `${baseUrl}?enrollment_id=${contextId}`
      : context === 'Section'
      ? `${baseUrl}?course_section_id=${contextId}`
      : baseUrl
  
    return doFetchApi<{ course_pace: CoursePace; progress: Progress }>({ path: url }).then(({ json }) => json)
  }

export const relinkToParentPace = (paceId: string) =>
  doFetchApi<{course_pace: CoursePace}>({
    path: `/api/v1/course_pacing/${paceId}/relink_to_parent_pace`,
    method: 'POST',
  }).then(({json}) => json?.course_pace)

export const compress = (coursePace: CoursePace, extraSaveParams = {}) =>
  doFetchApi<{course_pace: CoursePace; progress: Progress}>({
    path: `/api/v1/courses/${coursePace.course_id}/course_pacing/compress_dates`,
    method: 'POST',
    body: {
      ...extraSaveParams,
      course_pace: transformCoursePaceForApi(coursePace, ApiMode.COMPRESS),
    },
  }).then(({json}) => json)

export const removePace = (coursePace: CoursePace) =>
  doFetchApi<{course_pace: CoursePace}>({
    path: `/api/v1/courses/${coursePace.course_id}/course_pacing/${coursePace.id}`,
    method: 'DELETE',
  }).then(({json}) => json)

/* API transformers
 * functions and interfaces to transform the frontend formatted objects
 * to the format required for backend consumption
 *
 * TODO: potential technical debt - having to transform between the frontend
 * and backend data structures like this seems a bit messy. Could use a *REFACTOR*
 * if more models are saved using the same pattern.
 */

interface ApiCoursePaceModuleItemsAttributes {
  readonly id: string
  readonly duration: number
  readonly module_item_id: string
}

interface CompressApiFormattedCoursePace {
  readonly start_date?: string
  readonly end_date: OptionalDate
  readonly exclude_weekends?: boolean
  readonly selected_days_to_skip?: string[]
  readonly course_pace_module_items_attributes: ApiCoursePaceModuleItemsAttributes[]
}
interface PublishApiFormattedCoursePace extends CompressApiFormattedCoursePace {
  readonly workflow_state: WorkflowStates
  readonly context_type: PaceContextTypes
  readonly context_id: string
  readonly assignments_weighting: Array<{ resource_type: string; duration: number }>
  readonly time_to_complete_calendar_days: number
}

const transformCoursePaceForApi = (
  coursePace: CoursePace,
  mode: ApiMode = ApiMode.PUBLISH,
): PublishApiFormattedCoursePace | CompressApiFormattedCoursePace => {
  const coursePaceItems: ApiCoursePaceModuleItemsAttributes[] = coursePace.modules.flatMap(module =>
    module.items.map(item => ({
      id: item.id,
      duration: item.duration,
      module_item_id: item.module_item_id,
    })),
  )

  const selectedDaysToSkipValue = window.ENV.FEATURES.course_paces_skip_selected_days
    ? coursePace.selected_days_to_skip
    : coursePace.exclude_weekends
      ? ['sat', 'sun']
      : []

  const compressedCoursePace: CompressApiFormattedCoursePace = {
    start_date: coursePace.start_date,
    end_date: coursePace.end_date,
    course_pace_module_items_attributes: coursePaceItems,
    selected_days_to_skip: selectedDaysToSkipValue,
    exclude_weekends: coursePace.exclude_weekends,
  }
  const weightedAssignment: Array<{ resource_type: string; duration: number }> =
    window.ENV.FEATURES.course_pace_weighted_assignments && coursePace.assignments_weighting
      ? Object.entries(coursePace.assignments_weighting)
          .filter(([_, value]) => value !== undefined)
          .map(([key, value]) => ({
            resource_type: key,
            duration: value as number,
          }))
      : []

  return mode === ApiMode.COMPRESS
    ? compressedCoursePace
    : {
        ...compressedCoursePace,
        workflow_state: coursePace.workflow_state,
        context_type: coursePace.context_type,
        context_id: coursePace.context_id,
        assignments_weighting: weightedAssignment,
        time_to_complete_calendar_days: coursePace.time_to_complete_calendar_days,
      }
}
