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
 * WARRANTY without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {queryClient} from '@canvas/query'
import doFetchApi, {FetchApiError} from '@canvas/do-fetch-api-effect'
import type {DifferentiationTagCategory, DifferentiationTagGroup} from '../types'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useMutation} from '@tanstack/react-query'

const I18n = createI18nScope('differentiation_tags')

interface BulkOperations {
  create?: Array<{name: string}>
  update?: Array<{id: number; name: string}>
  delete?: Array<{id: number}>
}

/**
 * Variables needed by our useBulkManageDifferentiationTags hook.
 * - courseId is required for the endpoint.
 * - groupCategoryId is optional; if omitted, the API will create a new group category.
 * - groupCategoryName is optional; can be used to rename/update or create a new category.
 * - operations includes the arrays of create/update/delete instructions.
 */
interface UseBulkManageDifferentiationTagsVariables {
  courseId: number
  groupCategoryId?: number
  groupCategoryName?: string
  operations: BulkOperations
}

/**
 * The shape of the success response from the API.
 * The API will return the group category plus arrays of created, updated, and deleted groups.
 */
interface BulkManageDiffTagResponse {
  created: DifferentiationTagGroup[]
  updated: DifferentiationTagGroup[]
  deleted: DifferentiationTagGroup[]
  group_category: DifferentiationTagCategory
}

/**
 * A custom hook that calls the bulk_manage_differentiation_tag endpoint to:
 *  - Optionally create/update a GroupCategory (differentiation tag category)
 *  - Create, update, or delete groups (differentiation tags) in bulk
 *
 * After a successful mutation, this hook invalidates all queries for
 * useDifferentiationTagCategoriesIndex by using the key prefix 'differentiationTagCategories'.
 */
export const useBulkManageDifferentiationTags = () => {
  return useMutation<
    BulkManageDiffTagResponse | undefined,
    Error,
    UseBulkManageDifferentiationTagsVariables
  >({
    mutationFn: async ({courseId, groupCategoryId, groupCategoryName, operations}) => {
      try {
        // Prepare the body for the POST request
        const bodyPayload = {
          group_category: {
            ...(groupCategoryId ? {id: groupCategoryId} : {}),
            ...(groupCategoryName ? {name: groupCategoryName} : {}),
          },
          operations,
        }

        const result = await doFetchApi<BulkManageDiffTagResponse>({
          path: `/api/v1/courses/${courseId}/group_categories/bulk_manage_differentiation_tag`,
          method: 'POST',
          headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(bodyPayload),
        })
        return result.json
      } catch (unknownError) {
        let errorMsg = I18n.t('Bulk manage differentiation tags failed')

        // If doFetchApi threw a FetchApiError, try extracting server error details
        if (unknownError instanceof FetchApiError && unknownError.response) {
          try {
            const errorPayload = await unknownError.response.json()
            if (errorPayload?.errors) {
              errorMsg = errorPayload.errors
            }
          } catch {
            // Swallow parse errors; fallback to the default message
          }
        }
        throw new Error(errorMsg)
      }
    },
    onSuccess: async () => {
      // We are invalidating all queries that start with 'differentiationTagCategories'
      // undefined: we aren't using any other query filters to determine what to invalidate
      // cancelRefetch: tells the query client to cancel any ongoing refetch for the matching queries
      await queryClient.invalidateQueries(
        {
          queryKey: ['differentiationTagCategories'],
        },
        {
          cancelRefetch: true,
        },
      )
    },
    onError: error => {
      console.error(I18n.t('Error bulk-managing differentiation tags:'), error)
    },
  })
}
