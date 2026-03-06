/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

/**
 * Fires a Pendo track event using the global Pendo agent.
 *
 * canvas-media is a standalone package that cannot import @canvas/pendo.
 * The Pendo agent is initialized by Canvas and exposed as window.canvasUsageMetrics.
 */
export function trackPendoEvent(eventName: string, props?: Record<string, unknown>): void {
  try {
    const pendo = (window as any).canvasUsageMetrics
    if (!pendo?.track) return
    pendo.track(eventName, {type: 'track', ...props})
  } catch {
    // Analytics tracking should never break functionality
  }
}
