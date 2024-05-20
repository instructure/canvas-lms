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

import {captureException} from '@sentry/browser'

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
  type: 'prefix' | 'suffix' = 'suffix'
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
      // eslint-disable-next-line no-console
      console.warn(`Stored value for ${storageKey} is not an object.`)
      return
    }
  } catch (error) {
    // eslint-disable-next-line no-console
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
    // eslint-disable-next-line no-console
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
  newValues: Partial<T>
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
  property: string
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
