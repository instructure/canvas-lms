/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import axios from '@canvas/axios'

export const loadRollups = (courseId, gradebookFilters, needDefaults = false, page = 1) => {
  const params = {
    params: {
      rating_percents: true,
      per_page: 20,
      exclude: gradebookFilters,
      include: ['outcomes', 'users', 'outcome_paths', 'alignments'],
      sort_by: 'student',
      page,
      ...(needDefaults && {add_defaults: true}),
    },
  }
  return axios.get(`/api/v1/courses/${courseId}/outcome_rollups`, params)
}

export const exportCSV = (courseId, gradebookFilters) => {
  const params = {
    params: {
      exclude: gradebookFilters,
    },
  }

  return axios.get(`/courses/${courseId}/outcome_rollups.csv`, params)
}
