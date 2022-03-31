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
import moment from 'moment-timezone'

import {Constants as CoursePaceConstants, CoursePaceAction} from '../actions/course_paces'
import coursePaceItemsReducer from './course_pace_items'
import * as DateHelpers from '../utils/date_stuff/date_helpers'
import * as PaceDueDatesCalculator from '../utils/date_stuff/pace_due_dates_calculator'
import {
  CoursePacesState,
  CoursePace,
  PaceContextTypes,
  PaceDuration,
  StoreState,
  CoursePaceItem,
  CoursePaceItemDueDates,
  Enrollment,
  Sections,
  Enrollments,
  Section,
  Module,
  OptionalDate
} from '../types'
import {BlackoutDate, Course} from '../shared/types'
import {Constants as UIConstants, SetSelectedPaceType} from '../actions/ui'
import {getCourse} from './course'
import {getEnrollments} from './enrollments'
import {getSections} from './sections'
import {getBlackoutDates} from '../shared/reducers/blackout_dates'
import {Change, summarizeChanges} from '../utils/change_tracking'

const initialProgress = window.ENV.COURSE_PACE_PROGRESS

export const initialState: CoursePacesState = ({
  ...window.ENV.COURSE_PACE,
  course: window.ENV.COURSE,
  originalPace: window.ENV.COURSE_PACE,
  publishingProgress: initialProgress
} || {}) as CoursePacesState

const getModuleItems = (modules: Module[]) =>
  ([] as CoursePaceItem[]).concat(...modules.map(m => m.items))

/* Selectors */

// Uses the lodash isEqual function to do a deep comparison for selectors created with
// this selector creator. This allows values to still be memoized when one of the arguments
// is some sort of nexted object, where the default memoization function will return a false
// equality check. See: https://github.com/reduxjs/reselect#createselectorinputselectors--inputselectors-resultfunc
// The memoization equality check is potentially slower, but if the selector itself is computing
// some complex data, it will ultimately be better to use this, otherwise you'll get unnecessary
// calculations.
const createDeepEqualSelector = createSelectorCreator(defaultMemoize, deepEqual)

export const getExcludeWeekends = (state: StoreState): boolean => state.coursePace.exclude_weekends
export const getOriginalPace = (state: StoreState) => state.coursePace.originalPace
export const getCoursePace = (state: StoreState): CoursePacesState => state.coursePace
export const getCoursePaceModules = (state: StoreState) => state.coursePace.modules
export const getCoursePaceType = (state: StoreState): PaceContextTypes =>
  state.coursePace.context_type
export const getHardEndDates = (state: StoreState): boolean => state.coursePace.hard_end_dates
export const getPacePublishing = (state: StoreState): boolean => {
  const progress = state.coursePace.publishingProgress
  if (!progress) return false
  return !!progress.id && ['queued', 'running'].includes(progress.workflow_state)
}
export const getPublishingError = (state: StoreState): string | undefined => {
  const progress = state.coursePace.publishingProgress
  if (!progress || progress.workflow_state !== 'failed') return undefined
  return progress.message
}
export const getEndDate = (state: StoreState): OptionalDate => state.coursePace.end_date
export const isStudentPace = (state: StoreState) => state.coursePace.context_type === 'Enrollment'
export const getIsPaceCompressed = (state: StoreState): boolean =>
  !!state.coursePace.compressed_due_dates
export const getPaceCompressedDates = (state: StoreState): CoursePaceItemDueDates | undefined =>
  state.coursePace.compressed_due_dates

export const getCoursePaceItems = createSelector(getCoursePaceModules, getModuleItems)

export const getSettingChanges = createDeepEqualSelector(
  getExcludeWeekends,
  getHardEndDates,
  getOriginalPace,
  getEndDate,
  (excludeWeekends, hardEndDates, originalPace, endDate) => {
    const changes: Change[] = []

    if (excludeWeekends !== originalPace.exclude_weekends)
      changes.push({
        id: 'exclude_weekends',
        oldValue: originalPace.exclude_weekends,
        newValue: excludeWeekends
      })

    // we want to validate that if hardEndDates is true that the endDate is a valid date
    if (
      hardEndDates !== originalPace.hard_end_dates &&
      (!hardEndDates || (hardEndDates && endDate))
    )
      changes.push({
        id: 'hard_end_dates',
        oldValue: originalPace.hard_end_dates,
        newValue: hardEndDates
      })

    if (endDate && endDate !== originalPace.end_date)
      changes.push({
        id: 'end_date',
        oldValue: originalPace.end_date,
        newValue: endDate
      })

    return changes
  }
)

export const getCoursePaceItemChanges = createDeepEqualSelector(
  getCoursePaceItems,
  getOriginalPace,
  (coursePaceItems, originalPace) => {
    const originalItems = getModuleItems(originalPace.modules)
    const changes: Change<CoursePaceItem>[] = []

    for (const i in coursePaceItems) {
      const originalItem = originalItems[i]
      const currentItem = coursePaceItems[i]

      if (originalItem.duration !== currentItem.duration) {
        changes.push({id: originalItem.id, oldValue: originalItem, newValue: currentItem})
      }
    }

    return changes
  }
)

export const getUnpublishedChangeCount = createSelector(
  getSettingChanges,
  getCoursePaceItemChanges,
  (settingChanges, coursePaceItemChanges) => settingChanges.length + coursePaceItemChanges.length
)

export const getSummarizedChanges = createSelector(
  getSettingChanges,
  getCoursePaceItemChanges,
  summarizeChanges
)

export const getCoursePaceItemPosition = createDeepEqualSelector(
  getCoursePaceItems,
  (_, props): CoursePaceItem => props.coursePaceItem,
  (coursePaceItems: CoursePaceItem[], coursePaceItem: CoursePaceItem): number => {
    let position = 0

    for (let i = 0; i < coursePaceItems.length; i++) {
      position = i
      if (coursePaceItems[i].id === coursePaceItem.id) {
        break
      }
    }

    return position
  }
)

export const getCoursePaceDurationTotal = createDeepEqualSelector(
  getCoursePaceItems,
  (coursePaceItems: CoursePaceItem[]): number =>
    coursePaceItems.reduce((total, item) => total + item.duration, 0)
)

export const getStartDate = createDeepEqualSelector(
  getCoursePace,
  getOriginalPace,
  (coursePace: CoursePace): string | undefined => {
    return coursePace.start_date
  }
)

// Wrapping this in a selector makes sure the result is memoized
export const getDueDates = createDeepEqualSelector(
  getCoursePaceItems,
  getExcludeWeekends,
  getBlackoutDates,
  getStartDate,
  getPaceCompressedDates,
  (
    items: CoursePaceItem[],
    excludeWeekends: boolean,
    blackoutDates: BlackoutDate[],
    startDate?: string,
    compressedDueDates?: CoursePaceItemDueDates
  ): CoursePaceItemDueDates => {
    if (compressedDueDates) {
      return compressedDueDates
    }
    return PaceDueDatesCalculator.getDueDates(items, excludeWeekends, blackoutDates, startDate)
  }
)

export const getUncompressedDueDates = createDeepEqualSelector(
  getCoursePaceItems,
  getExcludeWeekends,
  getBlackoutDates,
  getStartDate,
  (
    items: CoursePaceItem[],
    excludeWeekends: boolean,
    blackoutDates: BlackoutDate[],
    startDate?: string
  ): CoursePaceItemDueDates => {
    return PaceDueDatesCalculator.getDueDates(items, excludeWeekends, blackoutDates, startDate)
  }
)

export const getDueDate = createSelector(
  getDueDates,
  (_, props): CoursePaceItem => props.coursePaceItem,
  (dueDates: CoursePaceItemDueDates, coursePaceItem: CoursePaceItem): string => {
    return dueDates[coursePaceItem.module_item_id]
  }
)

export const getProjectedEndDate = createDeepEqualSelector(
  getUncompressedDueDates,
  getCoursePaceItems,
  getStartDate,
  (
    dueDates: CoursePaceItemDueDates,
    items: CoursePaceItem[],
    startDate?: string
  ): string | undefined => {
    if (!startDate || !Object.keys(dueDates) || !items.length) return startDate

    // Get the due date associated with the last module item
    const lastDueDate = dueDates[items[items.length - 1].module_item_id]
    return lastDueDate && DateHelpers.formatDate(lastDueDate)
  }
)

/**
 * These 3 functions support the original projected_dates.tsx
 * which is not used but is being kept around as a reference
 * for when start and end date editing returns
 *
 * Computing pace duration is now in getPaceDuration
 */
// export const getPaceDays = createDeepEqualSelector(
//   getCoursePace,
//   getExcludeWeekends,
//   getBlackoutDates,
//   getProjectedEndDate,
//   (
//     coursePace: CoursePace,
//     excludeWeekends: boolean,
//     blackoutDates: BlackoutDate[],
//     projectedEndDate?: string
//   ): number => {
//     if (!coursePace.start_date) return 0

//     const endDate = projectedEndDate || coursePace.end_date || coursePace.start_date
//     return DateHelpers.daysBetween(coursePace.start_date, endDate, excludeWeekends, blackoutDates)
//   }
// )

// export const getWeekLength = createSelector(
//   getExcludeWeekends,
//   (excludeWeekends: boolean): number => {
//     return excludeWeekends ? 5 : 7
//   }
// )

// export const getPaceWeeks = createSelector(
//   getPaceDays,
//   getWeekLength,
//   (paceDays: number, weekLength: number): number => {
//     return Math.floor(paceDays / weekLength)
//   }
// )

// returns the weeks and days in calendar time
// between the pace's start and end dates
export const getPaceDuration = createSelector(
  getCoursePace,
  getProjectedEndDate,
  (coursePace: CoursePace, projectedEndDate?: string): PaceDuration => {
    let planDays = 0
    if (coursePace.start_date) {
      const endDate = projectedEndDate || coursePace.end_date || coursePace.start_date
      planDays = DateHelpers.rawDaysBetweenInclusive(coursePace.start_date, endDate)
    }
    return {weeks: Math.floor(planDays / 7), days: planDays % 7}
  }
)

export const getActivePaceContext = createSelector(
  getCoursePace,
  getCourse,
  getEnrollments,
  getSections,
  (
    activeCoursePace: CoursePace,
    course: Course,
    enrollments: Enrollments,
    sections: Sections
  ): Course | Section | Enrollment => {
    switch (activeCoursePace.context_type) {
      case 'Section':
        return sections[activeCoursePace.context_id]
      case 'Enrollment':
        return enrollments[activeCoursePace.context_id]
      default:
        return course
    }
  }
)

export const getIsCompressing = createSelector(
  getCoursePace,
  getHardEndDates,
  getProjectedEndDate,
  (
    coursePace: CoursePacesState,
    hardEndDates: boolean,
    projectedEndDate: string | undefined
  ): boolean => {
    const realEnd = hardEndDates ? coursePace.end_date : ENV.VALID_DATE_RANGE.end_at.date
    return !!projectedEndDate && projectedEndDate > realEnd
  }
)

/* Reducers */

export default (
  state = initialState,
  action: CoursePaceAction | SetSelectedPaceType
): CoursePacesState => {
  switch (action.type) {
    case CoursePaceConstants.SET_COURSE_PACE:
      return {...state, ...action.payload}
    case CoursePaceConstants.SET_START_DATE:
      return {...state, start_date: DateHelpers.formatDate(action.payload)}
    case CoursePaceConstants.SET_END_DATE:
      return {
        ...state,
        end_date: action.payload ? DateHelpers.formatDate(action.payload) : undefined
      }
    case CoursePaceConstants.PACE_CREATED:
      // Could use a *REFACTOR* to better handle new paces and updating the ui properly
      return {
        ...state,
        id: action.payload.id,
        modules: action.payload.modules,
        published_at: action.payload.published_at
      }
    case UIConstants.SET_SELECTED_PACE_CONTEXT:
      return {...action.payload.newSelectedPace, originalPace: action.payload.newSelectedPace}
    case CoursePaceConstants.TOGGLE_EXCLUDE_WEEKENDS:
      if (state.exclude_weekends) {
        return {...state, exclude_weekends: false}
      } else {
        return {...state, exclude_weekends: true}
      }
    case CoursePaceConstants.TOGGLE_HARD_END_DATES:
      if (state.hard_end_dates) {
        return {...state, hard_end_dates: false, end_date: ''}
      } else {
        let endDate = state.originalPace.end_date
        if (!endDate) {
          if (state.course.end_at) {
            endDate = state.course.end_at
          } else {
            endDate = moment(state.start_date).add(30, 'd').format('YYYY-MM-DD')
          }
        }
        return {...state, hard_end_dates: true, end_date: endDate}
      }

    case CoursePaceConstants.RESET_PACE:
      return {
        ...state.originalPace,
        originalPace: state.originalPace,
        updated_at: new Date().toISOString() // kicks react into re-rendering the assignment_rows
      }
    case CoursePaceConstants.SET_PROGRESS:
      return {...state, publishingProgress: action.payload}
    case CoursePaceConstants.SET_COMPRESSED_ITEM_DATES: {
      const newState = {...state}
      newState.compressed_due_dates = action.payload
      return newState
    }
    case CoursePaceConstants.UNCOMPRESS_DATES:
      return {...state, compressed_due_dates: undefined}
    default:
      return {...state, modules: coursePaceItemsReducer(state.modules, action)}
  }
}
