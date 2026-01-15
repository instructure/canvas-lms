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

import {DisplayFilter, GradebookSettings} from './constants'

export const mapSettingsToFilters = (settings?: GradebookSettings | null): string[] => {
  const filters: string[] = []
  if (settings && !settings.displayFilters.includes(DisplayFilter.SHOW_STUDENTS_WITH_NO_RESULTS)) {
    filters.push('missing_user_rollups')
  }
  if (settings && !settings.displayFilters.includes(DisplayFilter.SHOW_OUTCOMES_WITH_NO_RESULTS)) {
    filters.push('missing_outcome_results')
  }
  return filters
}
