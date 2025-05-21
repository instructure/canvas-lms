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
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useMutation} from '@tanstack/react-query'

const I18n = createI18nScope('differentiation_tags')

interface DeleteDifferentiationTagCategoryResponse {
  deleted?: boolean
  id?: number
}

interface UseDeleteDifferentiationTagCategoryVariables {
  differentiationTagCategoryId: number
}

/**
 * A custom hook that deletes a Differentiation Tag Category by ID.
 *
 * A Differentiation Tag Category is a GroupCategory where non_collaborative is true.
 * After a successful mutation, this hook invalidates any queries for differentiation tag categories.
 */
export const useDeleteDifferentiationTagCategory = () => {
  return useMutation<
    DeleteDifferentiationTagCategoryResponse,
    Error,
    UseDeleteDifferentiationTagCategoryVariables
  >({
    mutationFn: async ({differentiationTagCategoryId}) => {
      const result = await doFetchApi<DeleteDifferentiationTagCategoryResponse>({
        path: `/api/v1/group_categories/${differentiationTagCategoryId}`,
        method: 'DELETE',
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
        },
      })

      if (!result.response.ok) {
        throw new Error(I18n.t('Failed to delete Differentiation Tag Category'))
      }

      if (!result.json) {
        throw new Error(I18n.t('No data returned from the server'))
      }

      return result.json
    },

    onSuccess: async () => {
      // Invalidate queries related to differentiation tag categories so the UI can refresh
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
      console.error(I18n.t('Error deleting Differentiation Tag Category:'), error)
    },
  })
}
