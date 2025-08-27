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

import manifest from './persistedQueries/manifest.json'
import GetCourseStudentQuery from './persistedQueries/GetCourseStudentQuery.graphql'
import GetModulesStudentQuery from './persistedQueries/GetModulesStudentQuery.graphql'
import GetModulesQuery from './persistedQueries/GetModulesQuery.graphql'
import GetModuleItemsQuery from './persistedQueries/GetModuleItemsQuery.graphql'
import GetModuleItemsStudentQuery from './persistedQueries/GetModuleItemsStudentQuery.graphql'

interface PersistedQuery {
  anonymous_access_allowed: boolean
  query: string
}

const queries: Record<string, string> = {
  GetCourseStudentQuery,
  GetModulesStudentQuery,
  GetModuleItemsStudentQuery,
  GetModulesQuery,
  GetModuleItemsQuery,
}

const persistedQueries: Record<string, PersistedQuery> = {}

Object.entries(manifest).forEach(([queryName, metadata]) => {
  persistedQueries[queryName] = {
    ...metadata,
    query: queries[queryName],
  }
})

export default persistedQueries
