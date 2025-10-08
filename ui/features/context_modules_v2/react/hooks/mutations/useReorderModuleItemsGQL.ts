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

import {gql} from 'graphql-tag'
import {executeQuery} from '@canvas/graphql'
import {useMutation, useQueryClient} from '@tanstack/react-query'
import {MODULE_ITEMS, MODULE_ITEMS_ALL, MODULES} from '../../utils/constants'

interface ReorderModuleItemsParams {
  courseId: string
  moduleId: string
  itemIds: string[]
  oldModuleId?: string
  targetPosition?: number
}

interface ReorderModuleItemsResult {
  module: {
    id: string
    name: string
    moduleItems: Array<{
      id: string
      title: string
      position: number
    }>
  }
  oldModule?: {
    id: string
    name: string
    moduleItems: Array<{
      id: string
      title: string
      position: number
    }>
  }
  errors?: Array<{
    attribute: string
    message: string
  }>
}

const REORDER_MODULE_ITEMS_MUTATION = gql`
  mutation ReorderModuleItems($input: ReorderModuleItemsInput!) {
    reorderModuleItems(input: $input) {
      module {
        id
        name
        moduleItems {
          id
          title
          position
        }
      }
      oldModule {
        id
        name
        moduleItems {
          id
          title
          position
        }
      }
      errors {
        attribute
        message
      }
    }
  }
`

const reorderModuleItems = async (
  params: ReorderModuleItemsParams,
): Promise<ReorderModuleItemsResult> => {
  const result: any = await executeQuery(REORDER_MODULE_ITEMS_MUTATION, {
    input: {
      courseId: params.courseId,
      moduleId: params.moduleId,
      itemIds: params.itemIds,
      oldModuleId: params.oldModuleId,
      targetPosition: params.targetPosition,
    },
  })

  if (result.errors?.length > 0) {
    throw new Error(result.errors[0].message)
  }

  const mutationResult = result.reorderModuleItems || result.data?.reorderModuleItems

  if (mutationResult?.errors?.length > 0) {
    throw new Error(mutationResult.errors[0].message)
  }

  return mutationResult
}

export const useReorderModuleItemsGQL = () => {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: reorderModuleItems,
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({queryKey: [MODULE_ITEMS, variables.oldModuleId], exact: false})
      queryClient.invalidateQueries({queryKey: [MODULE_ITEMS, variables.moduleId], exact: false})
      queryClient.invalidateQueries({queryKey: [MODULE_ITEMS_ALL, variables.oldModuleId]})
      queryClient.invalidateQueries({queryKey: [MODULE_ITEMS_ALL, variables.moduleId]})
      queryClient.invalidateQueries({queryKey: [MODULES, variables.courseId], exact: false})
    },
  })
}
