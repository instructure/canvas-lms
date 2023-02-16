// @ts-nocheck
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

import {CoursePace, OptionalDate, PaceContextTypes, Progress, WorkflowStates} from '../types'
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
      innerResolve,
      innerReject
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
  contextId: string
) => {
  let url = `/api/v1/courses/${courseId}/course_pacing/new`
  if (context === 'Section') {
    url = `/api/v1/courses/${courseId}/course_pacing/new?course_section_id=${contextId}`
  } else if (context === 'Enrollment') {
    url = `/api/v1/courses/${courseId}/course_pacing/new?enrollment_id=${contextId}`
  }
  return doFetchApi<{
    course_pace: CoursePace
    progress: Progress
  }>({path: url}).then(({json}) => json)
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
  readonly exclude_weekends: boolean
  readonly course_pace_module_items_attributes: ApiCoursePaceModuleItemsAttributes[]
}
interface PublishApiFormattedCoursePace extends CompressApiFormattedCoursePace {
  readonly workflow_state: WorkflowStates
  readonly context_type: PaceContextTypes
  readonly context_id: string
}

const transformCoursePaceForApi = (
  coursePace: CoursePace,
  mode: ApiMode = ApiMode.PUBLISH
): PublishApiFormattedCoursePace | CompressApiFormattedCoursePace => {
  const coursePaceItems: ApiCoursePaceModuleItemsAttributes[] = []
  coursePace.modules.forEach(module => {
    module.items.forEach(item => {
      coursePaceItems.push({
        id: item.id,
        duration: item.duration,
        module_item_id: item.module_item_id,
      })
    })
  })

  return mode === ApiMode.COMPRESS
    ? {
        start_date: coursePace.start_date,
        end_date: coursePace.end_date,
        exclude_weekends: coursePace.exclude_weekends,
        course_pace_module_items_attributes: coursePaceItems,
      }
    : {
        start_date: coursePace.start_date,
        end_date: coursePace.end_date,
        workflow_state: coursePace.workflow_state,
        exclude_weekends: coursePace.exclude_weekends,
        context_type: coursePace.context_type,
        context_id: coursePace.context_id,
        course_pace_module_items_attributes: coursePaceItems,
      }
}
