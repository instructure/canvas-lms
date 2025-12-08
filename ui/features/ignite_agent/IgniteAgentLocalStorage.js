/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

const LOCAL_STORAGE_KEY = 'igniteAgentLocal'

const DEFAULT_AGENT_LOCAL_STATE = {
  buttonRelativeVerticalPosition: 0, // Default to 0% from bottom
}

/**
 * Reads a specific value from the local storage object.
 * @param {string} key The key of the property to read from the local state.
 * @returns {*} The value of the property, or undefined if not found or on error.
 */
export function readFromLocal(key) {
  const localData = localStorage.getItem(LOCAL_STORAGE_KEY)
  if (localData) {
    try {
      const parsedData = JSON.parse(localData)
      if (parsedData && typeof parsedData === 'object' && !Array.isArray(parsedData)) {
        return parsedData[key]
      }
      return undefined
    } catch (e) {
      console.error('[Ignite Agent] Error parsing local storage data. Returning undefined.', e)
      return undefined
    }
  }
  return undefined
}

/**
 * Writes a specific value to the local storage object.
 * @param {string} key The key of the property to write.
 * @param {*} value The value to set for the property.
 */
export function writeToLocal(key, value) {
  let localState
  const existingData = localStorage.getItem(LOCAL_STORAGE_KEY)

  if (existingData) {
    try {
      localState = JSON.parse(existingData)
    } catch (e) {
      console.error('[Ignite Agent] Error parsing existing local storage data. Starting fresh.', e)
      localState = {...DEFAULT_AGENT_LOCAL_STATE}
    }
  } else {
    localState = {...DEFAULT_AGENT_LOCAL_STATE}
  }

  localState[key] = value

  try {
    localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(localState))
  } catch (e) {
    console.error('[Ignite Agent] Error writing to local storage:', e)
  }
}
