/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import type {EnvCommon} from '@canvas/global/env/EnvCommon'
import moment from 'moment'
import type {FormMessage} from '@instructure/ui-form-field'
import {captureException} from '@sentry/browser'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {Course, NodeStructure, RoleChoice, SelectedEnrollment} from '../types'

declare const ENV: GlobalEnv & EnvCommon

const I18n = createI18nScope('temporary_enrollment')

/**
 * Remove prefix or suffix (default) from input string
 *
 * @param {string} inputString String to remove affix from
 * @param {string} affix Affix to remove
 * @param {string} type Type of affix to remove
 * @returns {string} String with affix removed
 * @returns {string} inputString if affix is empty
 */
export function removeStringAffix(
  inputString: string,
  affix: string,
  type: 'prefix' | 'suffix' = 'suffix',
): string {
  if (!affix) {
    return inputString
  }

  if (type === 'suffix' && inputString.endsWith(affix)) {
    return inputString.slice(0, -affix.length)
  } else if (type === 'prefix' && inputString.startsWith(affix)) {
    return inputString.slice(affix.length)
  }

  return inputString
}

/**
 * Get the start and end times of the day for a given date (or current date)
 *
 * @param {Date} date Date to get day boundaries for
 * @returns {[Date, Date]} Array of start and end dates for the day
 */
export function getDayBoundaries(date: Date = new Date()): [Date, Date] {
  // clone date to avoid mutating the original
  const start = new Date(date)
  const end = new Date(date)

  // set start date time to beginning of day
  start.setHours(0, 1, 0, 0)
  // set end date time to end of day
  end.setHours(23, 59, 59, 999)

  return [start, end]
}

/**
 * Display message with local and account datetime
 *
 * @param {string} value An ISO format of the datetime
 * @param {boolean} isInvalid True if the value cannot be parsed
 * @return {FormMessage[]} Array of messages to display in a DateTimeInput
 */
export function generateDateTimeMessage(dateTime: {
  value: string | null
  isInvalid: boolean
  wrongOrder: boolean
}): FormMessage[] {
  if (dateTime.isInvalid) {
    return [{type: 'newError', text: I18n.t('The chosen date and time is invalid.')}]
  } else if (dateTime.wrongOrder) {
    return [{type: 'newError', text: I18n.t('The start date must be before the end date')}]
  } else if (
    ENV.CONTEXT_TIMEZONE &&
    ENV.TIMEZONE !== ENV.CONTEXT_TIMEZONE &&
    ENV.context_asset_string.startsWith('account')
  ) {
    return [
      {
        type: 'success',
        text: I18n.t('Local: %{datetime}', {
          datetime: moment.tz(dateTime.value, ENV.TIMEZONE).format('ddd, MMM D, YYYY, h:mm A'),
        }),
      },
      {
        type: 'success',
        text: I18n.t('Account: %{datetime}', {
          datetime: moment
            .tz(dateTime.value, ENV.CONTEXT_TIMEZONE)
            .format('ddd, MMM D, YYYY, h:mm A'),
        }),
      },
    ]
  } else {
    // default to returning local datetime if local and account are the same timezone
    return [
      {
        type: 'success',
        text: moment.tz(dateTime.value, ENV.TIMEZONE).format('ddd, MMM D, YYYY, h:mm A'),
      },
    ]
  }
}

export const handleCollectSelectedEnrollments = (
  tree: NodeStructure[],
  enrollmentsByCourse: Course[],
  roleChoice: RoleChoice,
): SelectedEnrollment[] => {
  const selectedEnrolls: SelectedEnrollment[] = []
  for (const role in tree) {
    for (const course of tree[role].children) {
      for (const section of course.children) {
        if (section.isCheck || (course.children.length === 1 && course.isCheck)) {
          if (enrollmentsByCourse) {
            enrollmentsByCourse.forEach((c: Course) => {
              const courseId = course.id.slice(1) // remove leading 'c' prefix from course.id
              const sectionId = section.id.slice(1) // remove leading 's' prefix from section.id
              let enrollment
              if (c.id === courseId) {
                enrollment = c.enrollments.find(
                  matchedEnrollment =>
                    // covers base role types
                    matchedEnrollment.role_id === roleChoice.id ||
                    // covers custom role types if existing enrollment with same role type is present
                    matchedEnrollment.type === roleChoice.name.toLowerCase(),
                )
                if (enrollment === undefined) {
                  // covers custom role types if no matching enrollment role type is present
                  enrollment = c.enrollments[c.enrollments.length - 1]
                }
                if (enrollment) {
                  selectedEnrolls.push({
                    section: sectionId,
                    limit_privileges_to_course_section:
                      enrollment.limit_privileges_to_course_section,
                  })
                }
              }
            })
          }
        }
      }
    }
  }
  return selectedEnrolls
}

/**
 * Retrieve a serialized value from localStorage by its key
 *
 * @param {string} storageKey Key used to retrieve data from localStorage
 * @returns {T} Parsed value from localStorage
 * @returns {undefined} If the stored value is not an object
 * @template T Expected generic type of the retrieved data
 *             (assignable to, or derived from, Object)
 */
export function getFromLocalStorage<T extends object>(storageKey: string): T | undefined {
  try {
    const storedValue = localStorage.getItem(storageKey)
    if (storedValue === null) return

    const parsedValue = JSON.parse(storedValue)

    // Ensuring the parsed value is an object
    if (typeof parsedValue === 'object' && parsedValue !== null) {
      return parsedValue as T
    } else {
      console.warn(`Stored value for ${storageKey} is not an object.`)
      return
    }
  } catch (error) {
    console.error(`Error fetching/parsing ${storageKey} from localStorage:`, error)
    captureException(error)
  }
}

/**
 * Store a serialized value in localStorage by its key
 *
 * @param {string} storageKey Key used to store data in localStorage
 * @param {T} value Value to store in localStorage
 * @template T Expected generic type of the stored data
 *             (assignable to, or derived from, Object)
 * @returns {void}
 */
export function setToLocalStorage<T>(storageKey: string, value: T): void {
  try {
    const serializedValue = JSON.stringify(value)
    localStorage.setItem(storageKey, serializedValue)
  } catch (error) {
    console.error(`Error serializing/saving ${storageKey} to localStorage:`, error)
    captureException(error)
  }
}

/**
 * Update an object stored in localStorage by merging it with new properties
 *
 * @param {string} storageKey Key used to store data in localStorage
 * @param {Partial<T>} newValues An object containing new or updated properties
 * @template T Expected generic type of the stored data
 *             (assignable to, or derived from, Object)
 * @returns {void}
 */
export function updateLocalStorageObject<T extends object>(
  storageKey: string,
  // using partial to allow partial updates of object
  newValues: Partial<T>,
): void {
  const existingData = getFromLocalStorage<T>(storageKey) || {}

  // merge the existing data with new values
  const updatedData: T = {
    ...existingData,
    ...newValues,
  } as T

  setToLocalStorage<T>(storageKey, updatedData)
}

/**
 * Convert input to a valid Date object or return undefined if invalid
 *
 * @param {Date | string | undefined} date Date to convert
 * @returns {Date | undefined} Valid Date object
 * @returns {undefined} If input is undefined or invalid
 */
export function safeDateConversion(date: Date | string | undefined): Date | undefined {
  if (!date) return

  const parsedDate = typeof date === 'string' ? new Date(date) : date
  return Number.isNaN(parsedDate.getTime()) ? undefined : parsedDate
}

/**
 * Split an array of objects into grouped arrays based on property value
 *
 * @param {any[]} arr The array of objects to group
 * @param {string} property Name of the property by which to group the objects
 * @returns {{[propertyValue: string]: any[]}} An object with keys as unique
 *          property values from the input array, and values as arrays of
 *          objects sharing that property value
 */
export function splitArrayByProperty(
  arr: any[],
  property: string,
): {[propertyValue: string]: any[]} {
  return arr.reduce((result: {[x: string]: any[]}, obj: {[x: string]: any}) => {
    const index = obj[property]
    if (!result[index]) {
      result[index] = []
    }
    result[index].push(obj)
    return result
  }, {})
}
