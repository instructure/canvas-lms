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

import {executeQuery} from '@canvas/graphql'

export interface BaseGraphQLResponse<T = any> {
  legacyNode?: {
    _id: string
    enrollments: T[]
  } | null
  errors?: {message: string}[]
}

export const getCurrentUserId = (): string => {
  const currentUserId = window.ENV?.current_user_id
  if (!currentUserId) {
    throw new Error('No current user ID found - please ensure you are logged in')
  }
  return currentUserId
}

export const executeGraphQLQuery = async <T>(
  query: any,
  variables: Record<string, any>,
): Promise<T> => {
  const result = await executeQuery<T>(query, variables)

  if (
    result &&
    typeof result === 'object' &&
    'errors' in result &&
    Array.isArray((result as any).errors)
  ) {
    const errors = (result as any).errors as {message: string}[]
    throw new Error(
      `GraphQL query failed: ${errors.map((err: {message: string}) => err.message).join(', ')}`,
    )
  }

  return result
}

export const createUserQueryConfig = (
  queryKey: (string | number | undefined)[],
  staleTimeMinutes: number = 5,
) => {
  const currentUserId = window.ENV?.current_user_id
  return {
    staleTime: staleTimeMinutes * 60 * 1000,
    refetchOnWindowFocus: false,
    enabled: !!currentUserId,
    queryKey: [...queryKey, currentUserId],
  }
}
