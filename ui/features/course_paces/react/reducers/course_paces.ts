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
import {CoursePaceItemAction} from '../actions/course_pace_items'
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
import {getInitialCoursePace, getOriginalBlackoutDates, getOriginalPace} from './original'
import {getBlackoutDates} from '../shared/reducers/blackout_dates'
import {Change, summarizeChanges} from '../utils/change_tracking'

const initialProgress = window.ENV.COURSE_PACE_PROGRESS

export const initialState: CoursePacesState = ({
  ...getInitialCoursePace(),
  course: window.ENV.COURSE,
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
export const getOriginalEndDate = (state: StoreState): OptionalDate =>
  state.original.coursePace.end_date
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
  getOriginalBlackoutDates,
  getBlackoutDates,
  (excludeWeekends, hardEndDates, originalPace, endDate, originalBlackoutDates, blackoutDates) => {
    const changes: Change[] = []

    if (excludeWeekends !== originalPace.exclude_weekends)
      changes.push({
        id: 'exclude_weekends',
        oldValue: originalPace.exclude_weekends,
        newValue: excludeWeekends
      })

    const blackoutChanges = getBlackoutDateChanges(originalBlackoutDates, blackoutDates)
    if (blackoutChanges.length) {
      changes.splice(0, 0, ...blackoutChanges)
    }

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

export function getBlackoutDateChanges(
  originalBlackoutDates: BlackoutDate[],
  blackoutDates: BlackoutDate[]
): Change[] {
  const changes: Change[] = []

  if (deepEqual(originalBlackoutDates, blackoutDates)) return changes

  // if I don't find the new one in the orig, it was added
  if (blackoutDates.length) {
    blackoutDates.forEach(bod => {
      const targetId: string = (bod.id || bod.temp_id) as string
      if (
        originalBlackoutDates.findIndex(elem => {
          return (elem.id || elem.temp_id) === targetId
        }) < 0
      ) {
        changes.push({
          id: 'blackout_date',
          oldValue: null,
          newValue: bod
        })
      }
    })
  }

  if (originalBlackoutDates.length) {
    // if I don't find the orig one in new, it was deleted
    originalBlackoutDates.forEach(bod => {
      const targetId = (bod.id || bod.temp_id) as string
      if (
        blackoutDates.findIndex(elem => {
          return (elem.id || elem.temp_id) === targetId
        }) < 0
      ) {
        changes.push({
          id: 'blackout_date',
          oldValue: bod,
          newValue: null
        })
      }
    })

    // todo: it exists in both => it was edited (if/when the UI supports it)
  }
  return changes
}

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

export const getSummarizedChanges = createDeepEqualSelector(
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

// return the due date of the last module item
export const getPlannedEndDate = createDeepEqualSelector(
  getCoursePaceItems,
  getDueDates,
  (items: CoursePaceItem[], dueDates: CoursePaceItemDueDates): OptionalDate => {
    return items.length ? dueDates[items[items.length - 1].module_item_id] : undefined
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
    if (!coursePace.start_date) return {weeks: 0, days: 0}

    const paceStart = moment(coursePace.start_date).endOf('day')
    const paceEnd = moment(coursePace.end_date).endOf('day')
    const projectedEnd = moment(projectedEndDate).endOf('day')
    const endDate = projectedEnd.isAfter(paceEnd) ? paceEnd : projectedEnd
    const planDays = DateHelpers.rawDaysBetweenInclusive(paceStart, endDate)
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

// return ms between projectedEndDate and the pace end_date
// if > 0, we are compressing
// need this rather than a boolean so the value changes and will
// trigger a rerender to update due dates.
export const getCompression = createSelector(
  getCoursePace,
  getProjectedEndDate,
  (coursePace: CoursePacesState, projectedEndDate: string | undefined): number => {
    if (!projectedEndDate || !coursePace.end_date) return 0
    return moment(projectedEndDate).endOf('day').diff(moment(coursePace.end_date).endOf('day'))
  }
)

/* Reducers */

export default (
  state = initialState,
  action: CoursePaceAction | SetSelectedPaceType
): CoursePacesState => {
  switch (action.type) {
    case CoursePaceConstants.SAVE_COURSE_PACE:
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
      return {...action.payload.newSelectedPace}
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
        let endDate = action.payload as OptionalDate
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
        ...(action.payload as CoursePace),
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
      return {
        ...state,
        modules: coursePaceItemsReducer(state.modules, action as CoursePaceItemAction)
      }
  }
}
