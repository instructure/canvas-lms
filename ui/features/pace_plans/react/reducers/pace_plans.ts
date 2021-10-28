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

import {createSelector, createSelectorCreator, defaultMemoize} from 'reselect'
import {deepEqual} from '@instructure/ui-utils'

import {Constants as PacePlanConstants, PacePlanAction} from '../actions/pace_plans'
import pacePlanItemsReducer from './pace_plan_items'
import * as DateHelpers from '../utils/date_stuff/date_helpers'
import * as PlanDueDatesCalculator from '../utils/date_stuff/plan_due_dates_calculator'
import {
  PacePlansState,
  PacePlan,
  PlanContextTypes,
  StoreState,
  PacePlanItem,
  PacePlanItemDueDates,
  Enrollment,
  Sections,
  Enrollments,
  Section,
  Module
} from '../types'
import {BlackoutDate, Course} from '../shared/types'
import {Constants as UIConstants, SetSelectedPlanType} from '../actions/ui'
import {getCourse} from './course'
import {getEnrollments} from './enrollments'
import {getSections} from './sections'
import {getBlackoutDates} from '../shared/reducers/blackout_dates'
import {Change, summarizeChanges} from '../utils/change_tracking'

export const initialState: PacePlansState = ({
  ...window.ENV.PACE_PLAN,
  originalPlan: window.ENV.PACE_PLAN
} || {}) as PacePlansState

const getModuleItems = (modules: Module[]) =>
  ([] as PacePlanItem[]).concat(...modules.map(m => m.items))

/* Selectors */

// Uses the lodash isEqual function to do a deep comparison for selectors created with
// this selector creator. This allows values to still be memoized when one of the arguments
// is some sort of nexted object, where the default memoization function will return a false
// equality check. See: https://github.com/reduxjs/reselect#createselectorinputselectors--inputselectors-resultfunc
// The memoization equality check is potentially slower, but if the selector itself is computing
// some complex data, it will ultimately be better to use this, otherwise you'll get unnecessary
// calculations.
const createDeepEqualSelector = createSelectorCreator(defaultMemoize, deepEqual)

export const getExcludeWeekends = (state: StoreState): boolean => state.pacePlan.exclude_weekends
export const getOriginalPlan = (state: StoreState) => state.pacePlan.originalPlan
export const getPacePlan = (state: StoreState): PacePlansState => state.pacePlan
export const getPacePlanModules = (state: StoreState) => state.pacePlan.modules
export const getPacePlanType = (state: StoreState): PlanContextTypes => state.pacePlan.context_type
export const getStartDate = (state: StoreState): string | undefined => state.pacePlan.start_date

export const getPacePlanItems = createSelector(getPacePlanModules, getModuleItems)

export const getSettingChanges = createDeepEqualSelector(
  getExcludeWeekends,
  getOriginalPlan,
  (excludeWeekends, originalPlan) => {
    const changes: Change[] = []

    if (excludeWeekends !== originalPlan.exclude_weekends)
      changes.push({
        id: 'exclude_weekends',
        oldValue: originalPlan.exclude_weekends,
        newValue: excludeWeekends
      })

    return changes
  }
)

export const getPacePlanItemChanges = createDeepEqualSelector(
  getPacePlanItems,
  getOriginalPlan,
  (pacePlanItems, originalPlan) => {
    const originalItems = getModuleItems(originalPlan.modules)
    const changes: Change<PacePlanItem>[] = []

    for (const i in pacePlanItems) {
      const originalItem = originalItems[i]
      const currentItem = pacePlanItems[i]

      if (originalItem.duration !== currentItem.duration) {
        changes.push({id: originalItem.id, oldValue: originalItem, newValue: currentItem})
      }
    }

    return changes
  }
)

export const getUnpublishedChangeCount = createSelector(
  getSettingChanges,
  getPacePlanItemChanges,
  (settingChanges, pacePlanItemChanges) => settingChanges.length + pacePlanItemChanges.length
)

export const getSummarizedChanges = createSelector(
  getSettingChanges,
  getPacePlanItemChanges,
  summarizeChanges
)

export const getPacePlanItemPosition = createDeepEqualSelector(
  getPacePlanItems,
  (_, props): PacePlanItem => props.pacePlanItem,
  (pacePlanItems: PacePlanItem[], pacePlanItem: PacePlanItem): number => {
    let position = 0

    for (let i = 0; i < pacePlanItems.length; i++) {
      position = i
      if (pacePlanItems[i].id === pacePlanItem.id) {
        break
      }
    }

    return position
  }
)

export const getPacePlanDurationTotal = createDeepEqualSelector(
  getPacePlanItems,
  (pacePlanItems: PacePlanItem[]): number =>
    pacePlanItems.reduce((total, item) => total + item.duration, 0)
)

// Wrapping this in a selector makes sure the result is memoized
export const getDueDates = createDeepEqualSelector(
  getPacePlanItems,
  getExcludeWeekends,
  getBlackoutDates,
  getStartDate,
  (
    items: PacePlanItem[],
    excludeWeekends: boolean,
    blackoutDates: BlackoutDate[],
    startDate?: string
  ): PacePlanItemDueDates => {
    return PlanDueDatesCalculator.getDueDates(items, excludeWeekends, blackoutDates, startDate)
  }
)

export const getDueDate = createSelector(
  getDueDates,
  (_, props): PacePlanItem => props.pacePlanItem,
  (dueDates: PacePlanItemDueDates, pacePlanItem: PacePlanItem): string => {
    return dueDates[pacePlanItem.module_item_id]
  }
)

export const getProjectedEndDate = createDeepEqualSelector(
  getDueDates,
  getPacePlanItems,
  getStartDate,
  (
    dueDates: PacePlanItemDueDates,
    items: PacePlanItem[],
    startDate?: string
  ): string | undefined => {
    if (!startDate || !Object.keys(dueDates) || !items.length) return startDate

    // Get the due date associated with the last module item
    const lastDueDate = dueDates[items[items.length - 1].module_item_id]
    return lastDueDate && DateHelpers.formatDate(lastDueDate)
  }
)

export const getPlanDays = createDeepEqualSelector(
  getPacePlan,
  getExcludeWeekends,
  getBlackoutDates,
  getProjectedEndDate,
  (
    pacePlan: PacePlan,
    excludeWeekends: boolean,
    blackoutDates: BlackoutDate[],
    projectedEndDate?: string
  ): number => {
    if (!pacePlan.start_date) return 0

    const endDate = pacePlan.end_date || projectedEndDate || pacePlan.start_date
    return DateHelpers.daysBetween(pacePlan.start_date, endDate, excludeWeekends, blackoutDates)
  }
)

export const getPlanWeeks = createSelector(
  getPlanDays,
  getExcludeWeekends,
  (planDays: number, excludeWeekends: boolean): number => {
    const weekLength = excludeWeekends ? 5 : 7
    return Math.floor(planDays / weekLength)
  }
)

export const getWeekLength = createSelector(
  getExcludeWeekends,
  (excludeWeekends: boolean): number => {
    return excludeWeekends ? 5 : 7
  }
)

export const getActivePlanContext = createSelector(
  getPacePlan,
  getCourse,
  getEnrollments,
  getSections,
  (
    activePacePlan: PacePlan,
    course: Course,
    enrollments: Enrollments,
    sections: Sections
  ): Course | Section | Enrollment => {
    switch (activePacePlan.context_type) {
      case 'Section':
        return sections[activePacePlan.context_id]
      case 'Enrollment':
        return enrollments[activePacePlan.context_id]
      default:
        return course
    }
  }
)

/* Reducers */

export default (
  state = initialState,
  action: PacePlanAction | SetSelectedPlanType
): PacePlansState => {
  switch (action.type) {
    case PacePlanConstants.SET_PACE_PLAN:
      return {...state, ...action.payload}
    case PacePlanConstants.SET_START_DATE:
      return {...state, start_date: DateHelpers.formatDate(action.payload)}
    case PacePlanConstants.SET_END_DATE:
      return {...state, end_date: DateHelpers.formatDate(action.payload)}
    case PacePlanConstants.PLAN_CREATED:
      // Could use a *REFACTOR* to better handle new plans and updating the ui properly
      return {
        ...state,
        id: action.payload.id,
        modules: action.payload.modules,
        published_at: action.payload.published_at
      }
    case UIConstants.SET_SELECTED_PLAN_CONTEXT:
      return {...action.payload.newSelectedPlan, originalPlan: action.payload.newSelectedPlan}
    case PacePlanConstants.TOGGLE_EXCLUDE_WEEKENDS:
      if (state.exclude_weekends) {
        return {...state, exclude_weekends: false}
      } else {
        return {...state, exclude_weekends: true}
      }
    case PacePlanConstants.TOGGLE_HARD_END_DATES:
      return {...state, hard_end_dates: !state.hard_end_dates}
    case PacePlanConstants.RESET_PLAN:
      return {...state.originalPlan, originalPlan: state.originalPlan}
    default:
      return {...state, modules: pacePlanItemsReducer(state.modules, action)}
  }
}
