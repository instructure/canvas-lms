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

/**
 * Adds the correlationId to the current page URL as a query parameter (cid).
 * This ensures the browser's Referer header includes the correlationId
 * in all subsequent API requests for observability tracking.
 *
 * @param correlationId - The unique correlation identifier to add to the URL
 */
export function addCorrelationIdToUrl(correlationId: string): void {
  const searchParams = new URLSearchParams(window.location.search)
  const existingCorrelationId = searchParams.get('cid')

  // Only update if not present or if it doesn't match the current correlationId
  if (existingCorrelationId !== correlationId) {
    searchParams.set('cid', correlationId)

    // Construct the new URL with updated query parameters
    const newUrl = `${window.location.pathname}?${searchParams.toString()}${window.location.hash}`

    // Use replaceState to avoid creating a new history entry
    window.history.replaceState({}, '', newUrl)
  }
}
