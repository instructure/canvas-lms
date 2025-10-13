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
import {executeQuery} from '@canvas/graphql'
import {UPDATE_ALLOCATION_RULE_MUTATION} from '../teacher/Mutations'
import {
  UpdateAllocationRuleInput,
  UpdateAllocationRuleResponse,
} from '../teacher/AssignmentTeacherTypes'

export const useEditAllocationRule = (
  onEditRuleSuccess?: (data: UpdateAllocationRuleResponse) => void,
  onEditRuleError?: (errors: any[]) => void,
) => {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (input: UpdateAllocationRuleInput) => {
      const response = await executeQuery<
        UpdateAllocationRuleResponse,
        {input: UpdateAllocationRuleInput}
      >(UPDATE_ALLOCATION_RULE_MUTATION, {input})

      return response
    },
    onSuccess: data => {
      if (data.updateAllocationRule?.allocationErrors?.length > 0) {
        onEditRuleError?.(data.updateAllocationRule.allocationErrors)
      } else {
        // Remove cache for the assignedStudents data so a student's peerReviewStatus is up to date
        queryClient.removeQueries({queryKey: ['assignedStudents']})
        onEditRuleSuccess?.(data)
      }
    },
    onError: (error, _variables, _context) => {
      onEditRuleError?.([error])
    },
    networkMode: 'always',
  })
}
