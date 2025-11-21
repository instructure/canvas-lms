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

import {useMutation, useQueryClient} from '@tanstack/react-query'
import {createPlannerOverride, updatePlannerOverride} from '../api'
import type {PlannerItem, PlannerOverride} from '../types'
import {PLANNER_ITEMS_QUERY_KEY} from './usePlannerItems'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('widget_dashboard')

interface ToggleCompleteParams {
  item: PlannerItem
  markedComplete: boolean
}

export function usePlannerOverride() {
  const queryClient = useQueryClient()

  const mutation = useMutation({
    mutationFn: async ({item, markedComplete}: ToggleCompleteParams) => {
      if (item.planner_override) {
        return updatePlannerOverride(item.planner_override.id, {
          marked_complete: markedComplete,
        })
      } else {
        return createPlannerOverride({
          plannable_type: item.plannable_type,
          plannable_id: item.plannable_id,
          marked_complete: markedComplete,
        })
      }
    },
    onMutate: async ({item, markedComplete}: ToggleCompleteParams) => {
      await queryClient.cancelQueries({queryKey: [PLANNER_ITEMS_QUERY_KEY]})

      const previousData = queryClient.getQueriesData({queryKey: [PLANNER_ITEMS_QUERY_KEY]})

      queryClient.setQueriesData({queryKey: [PLANNER_ITEMS_QUERY_KEY]}, (old: any) => {
        if (!old) return old

        return {
          ...old,
          items: old.items?.map((plannerItem: PlannerItem) => {
            if (
              plannerItem.plannable_id === item.plannable_id &&
              plannerItem.plannable_type === item.plannable_type
            ) {
              return {
                ...plannerItem,
                planner_override: item.planner_override
                  ? {...item.planner_override, marked_complete: markedComplete}
                  : {
                      id: -1,
                      plannable_type: item.plannable_type,
                      plannable_id: item.plannable_id,
                      user_id: -1,
                      workflow_state: 'active',
                      marked_complete: markedComplete,
                      dismissed: false,
                      deleted_at: null,
                      created_at: new Date().toISOString(),
                      updated_at: new Date().toISOString(),
                    },
              }
            }
            return plannerItem
          }),
        }
      })

      return {previousData}
    },
    onError: (error, variables, context) => {
      if (context?.previousData) {
        context.previousData.forEach(([queryKey, data]) => {
          queryClient.setQueryData(queryKey, data)
        })
      }

      showFlashError(I18n.t('Failed to update item. Please try again.'))()
    },
    onSuccess: (updatedOverride: PlannerOverride, {item}: ToggleCompleteParams) => {
      queryClient.setQueriesData({queryKey: [PLANNER_ITEMS_QUERY_KEY]}, (old: any) => {
        if (!old) return old

        return {
          ...old,
          items: old.items?.map((plannerItem: PlannerItem) => {
            if (
              plannerItem.plannable_id === item.plannable_id &&
              plannerItem.plannable_type === item.plannable_type
            ) {
              return {
                ...plannerItem,
                planner_override: updatedOverride,
              }
            }
            return plannerItem
          }),
        }
      })
    },
  })

  return {
    toggleComplete: mutation.mutate,
    isLoading: mutation.isPending,
  }
}
