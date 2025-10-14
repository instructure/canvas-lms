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

// Session storage key for storing Ignite Agent state
const SESSION_STORAGE_KEY = 'igniteAgent'

/**
 * Session storage utility functions for Ignite Agent
 */
export const IgniteAgentSessionStorage = {
  /**
   * Get the current session state
   * @returns {object|null} The session state object or null if not found/invalid
   */
  getState() {
    try {
      const sessionState = sessionStorage.getItem(SESSION_STORAGE_KEY)
      return sessionState ? JSON.parse(sessionState) : null
    } catch (e) {
      console.error('[Ignite Agent] Could not read from sessionStorage:', e)
      return null
    }
  },

  /**
   * Set the agent state to open or closed
   */
  setAgentState(open) {
    try {
      const sessionState = JSON.parse(sessionStorage.getItem(SESSION_STORAGE_KEY))
      sessionState['isOpen'] = open
      sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(sessionState))
    } catch (e) {
      console.error('[Ignite Agent] Could not write to sessionStorage:', e)
    }
  },
}
