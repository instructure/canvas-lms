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

const SESSION_STORAGE_KEY = 'igniteAgent'

const DEFAULT_AGENT_SESSION_STATE = {
  isOpen: false,
  sessionId: null,
  buttonRelativeVerticalPosition: 0, // Default to 0% from bottom
}

/**
 * Reads a specific value from the session storage object.
 * @param {string} key The key of the property to read from the session state.
 * @returns {*} The value of the property, or undefined if not found or on error.
 */
export function readFromSession(key) {
  const sessionData = sessionStorage.getItem(SESSION_STORAGE_KEY)
  if (sessionData) {
    try {
      const parsedData = JSON.parse(sessionData)
      if (parsedData && typeof parsedData === 'object' && !Array.isArray(parsedData)) {
        return parsedData[key]
      }
      return undefined
    } catch (e) {
      console.error('[Ignite Agent] Error parsing session data. Returning undefined.', e)
      return undefined
    }
  }
  return undefined
}

/**
 * Writes a specific value to the session storage object.
 * @param {string} key The key of the property to write.
 * @param {*} value The value to set for the property.
 */
export function writeToSession(key, value) {
  let sessionState
  const existingData = sessionStorage.getItem(SESSION_STORAGE_KEY)

  if (existingData) {
    try {
      sessionState = JSON.parse(existingData)
    } catch (e) {
      console.error('[Ignite Agent] Error parsing existing session data. Starting fresh.', e)
      sessionState = {...DEFAULT_AGENT_SESSION_STATE}
    }
  } else {
    sessionState = {...DEFAULT_AGENT_SESSION_STATE}
  }

  sessionState[key] = value

  try {
    sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(sessionState))
  } catch (e) {
    console.error('[Ignite Agent] Error writing to session storage:', e)
  }
}
