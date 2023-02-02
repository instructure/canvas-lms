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
  OptionalDate,
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
  publishingProgress: initialProgress,
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
export const getOriginalEndDate = (state: StoreState): OptionalDate =>
  state.original.coursePace.end_date
export const isStudentPace = (state: StoreState) => state.coursePace.context_type === 'Enrollment'
export const isSectionPace = (state: StoreState) => state.coursePace.context_type === 'Section'
export const isNewPace = (state: StoreState) =>
  !(state.coursePace.id || (isStudentPace(state) && !window.ENV.FEATURES.course_paces_for_students)) // for now, there are no "new" student paces
export const getIsUnpublishedNewPace = (state: StoreState) => !state.original.coursePace.id
export const getIsPaceCompressed = (state: StoreState): boolean =>
  !!state.coursePace.compressed_due_dates
export const getPaceCompressedDates = (state: StoreState): CoursePaceItemDueDates | undefined =>
  state.coursePace.compressed_due_dates
export const getSearchTerm = (state: StoreState): string => state.paceContexts.searchTerm
export const getCoursePaceItems = createSelector(getCoursePaceModules, getModuleItems)

export const getPaceName = (state: StoreState): string => {
  switch (state.coursePace.context_type) {
    case 'Course':
      return state.course.name
    case 'Section':
      return state.sections[state.coursePace.context_id].name
    case 'Enrollment':
      return Object.values(state.enrollments).find(
        enrollment => enrollment.user_id === state.coursePace.context_id
      ).full_name
    default:
      throw new Error('Unknown context type')
  }
}

export const getSettingChanges = createDeepEqualSelector(
  getExcludeWeekends,
  getOriginalPace,
  getOriginalBlackoutDates,
  getBlackoutDates,
  (excludeWeekends, originalPace, originalBlackoutDates, blackoutDates) => {
    const changes: Change[] = []

    if (excludeWeekends !== originalPace.exclude_weekends)
      changes.push({
        id: 'exclude_weekends',
        oldValue: originalPace.exclude_weekends,
        newValue: excludeWeekends,
      })

    const blackoutChanges = getBlackoutDateChanges(originalBlackoutDates, blackoutDates)
    if (blackoutChanges.length) {
      changes.splice(0, 0, ...blackoutChanges)
    }

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
          newValue: bod,
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
          newValue: null,
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

export const getUnpublishedChangeCount = createDeepEqualSelector(
  getSettingChanges,
  getCoursePaceItemChanges,
  (settingChanges, coursePaceItemChanges) => settingChanges.length + coursePaceItemChanges.length
)

export const getSummarizedChanges = createDeepEqualSelector(
  getSettingChanges,
  getCoursePaceItemChanges,
  summarizeChanges
)

export const getUnappliedChangesExist = createDeepEqualSelector(
  getPacePublishing,
  getUnpublishedChangeCount,
  (pacePublishing, unpublishedChangeCount) => unpublishedChangeCount > 0 && !pacePublishing
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

// sort module items by position or date
// (blackout date type items don't have a position)
function compareModuleItemOrder(a, b) {
  if ('position' in a && 'position' in b) {
    return a.position - b.position
  }
  if (!a.date && !!b.date) return -1
  if (!!a.date && !b.date) return 1
  if (!a.date && !b.date) return 0
  if (a.date.isBefore(b.date)) return -1
  if (a.date.isAfter(b.date)) return 1
  return 0
}

// merge due dates into the module items,
// then add blackout dates,
// then sort so ordered for display
export const mergeAssignmentsAndBlackoutDates = (
  coursePace: CoursePace,
  dueDates: CoursePaceItemDueDates,
  blackoutDates: BlackoutDate[]
) => {
  // throw out any blackout dates before or after the pace start and end
  // then strip down blackout dates and assign "start_date" to "date"
  // for merging with assignment due dates
  const paceStart = moment(coursePace.start_date)
  const dueDateKeys = Object.keys(dueDates)
  let veryLastDueDate = moment('3000-01-01T00:00:00Z')
  if (dueDateKeys.length) {
    let lastDueDate = moment(dueDates[dueDateKeys[0]])
    dueDateKeys.forEach(key => {
      if (moment(dueDates[key]).isAfter(lastDueDate)) lastDueDate = moment(dueDates[key])
    })
    veryLastDueDate = lastDueDate
  }
  const paceEnd = coursePace.end_date ? moment(coursePace.end_date) : veryLastDueDate
  const boDates: Array<any> = blackoutDates
    .filter(bd => {
      if (bd.end_date.isBefore(paceStart)) return false
      if (bd.start_date.isAfter(paceEnd)) return false
      return true
    })
    // because due dates will never fall w/in a blackout period
    // we can just deal with one end or the other when sorting into place.
    // I chose blackout's start_date
    .map(bd => ({
      ...bd,
      date: bd.start_date,
      type: 'blackout_date',
    }))

  // merge due dates into module items
  const modules = coursePace.modules
  const modulesWithDueDates = modules.reduce(
    (runningValue: Array<any>, module: Module): Array<any> => {
      const assignmentDueDates: CoursePaceItemDueDates = dueDates

      const assignmentsWithDueDate = module.items.map(item => {
        const item_due = assignmentDueDates[item.module_item_id]
        const due_at = item_due ? moment(item_due).endOf('day') : undefined
        return {...item, date: due_at, type: 'assignment'}
      })

      runningValue.push({
        ...module,
        itemsWithDates: assignmentsWithDueDate,
        moduleKey: `${module.id}-${Date.now()}`,
      })
      return runningValue
    },
    []
  )

  // merge the blackout dates into each module's items
  const modulesWithBlackoutDates = modulesWithDueDates.reduce(
    (runningValue: Array<any>, module: any, index: number): Array<any> => {
      const items = module.itemsWithDates

      if (index === modulesWithDueDates.length - 1) {
        // the last module gets the rest of the blackout dates
        module.itemsWithDates.splice(module.itemsWithDates.length, 0, ...boDates)
        module.itemsWithDates.sort(compareModuleItemOrder)
      } else if (items.length) {
        // find the blackout dates that occur before or during
        // the item due dates
        const lastDueDate = items[items.length - 1].date
        let firstBoDateAfterModule = boDates.length
        for (let i = 0; i < boDates.length; ++i) {
          if (boDates[i].date.isAfter(lastDueDate)) {
            firstBoDateAfterModule = i
            break
          }
        }
        // merge those blackout dates into the module items
        // and remove them from the working list of blackout dates
        const boDatesWithinModule = boDates.slice(0, firstBoDateAfterModule)
        boDates.splice(0, firstBoDateAfterModule)
        module.itemsWithDates.splice(module.itemsWithDates.length, 0, ...boDatesWithinModule)
        module.itemsWithDates.sort(compareModuleItemOrder)
      }
      return runningValue.concat(module)
    },
    []
  )
  return modulesWithBlackoutDates
}

export const getModulesWithItemsMergedWithDueDatesAndBlackoutDates = createDeepEqualSelector(
  getCoursePace,
  getDueDates,
  getBlackoutDates,
  mergeAssignmentsAndBlackoutDates
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
        end_date: action.payload ? DateHelpers.formatDate(action.payload) : undefined,
      }
    case CoursePaceConstants.PACE_CREATED:
      // Could use a *REFACTOR* to better handle new paces and updating the ui properly
      return {
        ...state,
        id: action.payload.id,
        modules: action.payload.modules,
        published_at: action.payload.published_at,
      }
    case UIConstants.SET_SELECTED_PACE_CONTEXT:
      return {...action.payload.newSelectedPace}
    case CoursePaceConstants.TOGGLE_EXCLUDE_WEEKENDS:
      if (state.exclude_weekends) {
        return {...state, exclude_weekends: false}
      } else {
        return {...state, exclude_weekends: true}
      }
    case CoursePaceConstants.RESET_PACE:
      return {
        ...(action.payload as CoursePace),
        updated_at: new Date().toISOString(), // kicks react into re-rendering the assignment_rows
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
        modules: coursePaceItemsReducer(state.modules, action as CoursePaceItemAction),
      }
  }
}
