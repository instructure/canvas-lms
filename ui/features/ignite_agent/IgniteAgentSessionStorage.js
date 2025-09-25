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
   * Set the agent state to open
   */
  setAgentOpen() {
    try {
      sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify({isOpen: true}))
      console.log('[Ignite Agent] Session state set to "open".')
    } catch (e) {
      console.error('[Ignite Agent] Could not write to sessionStorage:', e)
    }
  },

  /**
   * Set the agent state to closed
   */
  setAgentClosed() {
    try {
      sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify({isOpen: false}))
      console.log('[Ignite Agent] Session state set to "closed".')
    } catch (e) {
      console.error('[Ignite Agent] Could not write to sessionStorage:', e)
    }
  },
}
