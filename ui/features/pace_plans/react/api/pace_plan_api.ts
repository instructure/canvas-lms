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

import {PacePlan, PlanContextTypes, WorkflowStates} from '../types'
import doFetchApi from '@canvas/do-fetch-api-effect'

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

export const update = (pacePlan: PacePlan, extraSaveParams = {}) =>
  doFetchApi<{pace_plan: PacePlan}>({
    path: `/api/v1/courses/${pacePlan.course_id}/pace_plans/${pacePlan.id}`,
    method: 'PUT',
    body: {
      ...extraSaveParams,
      pace_plan: transformPacePlanForApi(pacePlan)
    }
  }).then(({json}) => json?.pace_plan)

export const create = (pacePlan: PacePlan, extraSaveParams = {}) =>
  doFetchApi<{pace_plan: PacePlan}>({
    path: `/api/v1/courses/${pacePlan.course_id}/pace_plans`,
    method: 'POST',
    body: {
      ...extraSaveParams,
      pace_plan: transformPacePlanForApi(pacePlan)
    }
  }).then(({json}) => json?.pace_plan)

// This is now just a convenience function for creating/update depending on the
// state of the plan
export const publish = (plan: PacePlan) => (plan?.id ? update(plan) : create(plan))

export const resetToLastPublished = (contextType: PlanContextTypes, contextId: string) =>
  doFetchApi<{pace_plan: PacePlan}>({
    path: `/api/v1/pace_plans/reset_to_last_published`,
    method: 'POST',
    body: {
      context_type: contextType,
      context_id: contextId
    }
  }).then(({json}) => json?.pace_plan)

export const load = (pacePlanId: string) =>
  doFetchApi<PacePlan>({path: `/api/v1/pace_plans/${pacePlanId}`}).then(({json}) => json)

export const getNewPacePlanFor = (
  courseId: string,
  context: PlanContextTypes,
  contextId: string
) => {
  let url = `/api/v1/courses/${courseId}/pace_plans/new`
  if (context === 'Section') {
    url = `/api/v1/courses/${courseId}/pace_plans/new?course_section_id=${contextId}`
  } else if (context === 'Enrollment') {
    url = `/api/v1/courses/${courseId}/pace_plans/new?enrollment_id=${contextId}`
  }
  return doFetchApi<{pace_plan: PacePlan}>({path: url}).then(({json}) => json?.pace_plan)
}

export const republishAllPlansForCourse = (courseId: string) =>
  doFetchApi({
    path: `/api/v1/pace_plans/republish_all_plans`,
    method: 'POST',
    body: {course_id: courseId}
  }).then(({json}) => json)

export const republishAllPlans = () =>
  doFetchApi({
    path: `/api/v1/pace_plans/republish_all_plans`,
    method: 'POST'
  }).then(({json}) => json)

export const relinkToParentPlan = (planId: string) =>
  doFetchApi<{pace_plan: PacePlan}>({
    path: `/api/v1/pace_plans/${planId}/relink_to_parent_plan`,
    method: 'POST'
  }).then(({json}) => json?.pace_plan)

/* API transformers
 * functions and interfaces to transform the frontend formatted objects
 * to the format required for backend consumption
 *
 * TODO: potential technical debt - having to transform between the frontend
 * and backend data structures like this seems a bit messy. Could use a *REFACTOR*
 * if more models are saved using the same pattern.
 */

interface ApiPacePlanModuleItemsAttributes {
  readonly id: string
  readonly duration: number
  readonly module_item_id: string
}

interface ApiFormattedPacePlan {
  readonly start_date?: string
  readonly end_date?: string
  readonly workflow_state: WorkflowStates
  readonly exclude_weekends: boolean
  readonly context_type: PlanContextTypes
  readonly context_id: string
  readonly hard_end_dates: boolean
  readonly pace_plan_module_items_attributes: ApiPacePlanModuleItemsAttributes[]
}

const transformPacePlanForApi = (pacePlan: PacePlan): ApiFormattedPacePlan => {
  const pacePlanItems: ApiPacePlanModuleItemsAttributes[] = []
  pacePlan.modules.forEach(module => {
    module.items.forEach(item => {
      pacePlanItems.push({
        id: item.id,
        duration: item.duration,
        module_item_id: item.module_item_id
      })
    })
  })

  return {
    start_date: pacePlan.start_date,
    end_date: pacePlan.end_date,
    workflow_state: pacePlan.workflow_state,
    exclude_weekends: pacePlan.exclude_weekends,
    context_type: pacePlan.context_type,
    context_id: pacePlan.context_id,
    hard_end_dates: !!pacePlan.hard_end_dates,
    pace_plan_module_items_attributes: pacePlanItems
  }
}
