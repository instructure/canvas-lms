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
 * Parses and validates the force_gql query parameter
 * @returns true if force_gql=true, false if force_gql=false, null otherwise (including invalid values)
 */
export function getForceGqlParam(): boolean | null {
  const params = new URLSearchParams(window.location.search)
  const forceGql = params.get('force_gql')

  if (forceGql === 'true') return true
  if (forceGql === 'false') return false

  // Invalid or missing - return null
  return null
}

/**
 * Determines whether to use GraphQL based on force_gql param and backend setting
 * @param backendSetting - The backend's performance_improvements_for_gradebook setting
 * @returns true to use GraphQL, false to use REST
 */
export function shouldUseGraphQL(backendSetting: boolean): boolean {
  const forceGql = getForceGqlParam()

  // If force_gql is set to a valid value, use it
  if (forceGql !== null) return forceGql

  // Otherwise, use the backend setting
  return backendSetting
}
