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

import {PAGE_SIZE} from './constants'
import {dispatchPageNavigationEvent} from '../handlers/dispatchPageNavigationEvent'

/**
 * Navigates to the last page of a module's items
 * @param moduleId - The ID of the module
 * @param totalItemCount - The total count of items in the module
 * @returns The last page number
 */
export function navigateToLastPage(moduleId: string, totalItemCount: number): number {
  const lastPage = Math.ceil(totalItemCount / PAGE_SIZE) || 1

  // Dispatch event to trigger UI navigation
  dispatchPageNavigationEvent(moduleId, lastPage)

  return lastPage
}
