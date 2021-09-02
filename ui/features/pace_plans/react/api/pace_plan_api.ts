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

import axios, {AxiosPromise} from '@canvas/axios'

import {PacePlan, PlanContextTypes, WorkflowStates, PublishOptions} from '../types'

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

export const update = (pacePlan: PacePlan, extraSaveParams = {}): AxiosPromise => {
  return axios.put(`/api/v1/pace_plans/${pacePlan.id}`, {
    ...extraSaveParams,
    pace_plan: transformPacePlanForApi(pacePlan)
  })
}

export const create = (pacePlan: PacePlan, extraSaveParams = {}): AxiosPromise => {
  return axios.post(`/api/v1/pace_plans`, {
    ...extraSaveParams,
    pace_plan: transformPacePlanForApi(pacePlan)
  })
}

export const publish = (
  plan: PacePlan,
  publishForOption: PublishOptions,
  publishForSectionIds: Array<string>,
  publishForEnrollmentIds: Array<string>
): AxiosPromise => {
  return axios.post(`/api/v1/pace_plans/publish`, {
    context_type: plan.context_type,
    context_id: plan.context_id,
    publish_for_option: publishForOption,
    publish_for_section_ids: publishForSectionIds,
    publish_for_enrollment_ids: publishForEnrollmentIds
  })
}

export const resetToLastPublished = (
  contextType: PlanContextTypes,
  contextId: string
): AxiosPromise => {
  return axios.post(`/api/v1/pace_plans/reset_to_last_published`, {
    context_type: contextType,
    context_id: contextId
  })
}

export const load = (pacePlanId: string) => {
  return axios.get(`/api/v1/pace_plans/${pacePlanId}`)
}

export const getLatestDraftFor = (context: PlanContextTypes, contextId: string) => {
  return axios.get(
    `/api/v1/pace_plans/latest_draft_for?context_type=${context}&context_id=${contextId}`
  )
}

export const republishAllPlansForCourse = (courseId: string) => {
  return axios.post(`/api/v1/pace_plans/republish_all_plans`, {course_id: courseId})
}

export const republishAllPlans = () => {
  return axios.post(`/api/v1/pace_plans/republish_all_plans`)
}

export const relinkToParentPlan = (planId: string) => {
  return axios.post(`/api/v1/pace_plans/${planId}/relink_to_parent_plan`)
}

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
  readonly start_date: string
  readonly end_date: string
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

  const apiFormattedPacePlan: ApiFormattedPacePlan = {
    start_date: pacePlan.start_date,
    end_date: pacePlan.end_date,
    workflow_state: pacePlan.workflow_state,
    exclude_weekends: pacePlan.exclude_weekends,
    context_type: pacePlan.context_type,
    context_id: pacePlan.context_id,
    hard_end_dates: !!pacePlan.hard_end_dates,
    pace_plan_module_items_attributes: pacePlanItems
  }

  return apiFormattedPacePlan
}
