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
import {CREATE_ALLOCATION_RULE_MUTATION} from '../teacher/Mutations'
import {
  CreateAllocationRuleInput,
  CreateAllocationRuleResponse,
} from '../teacher/AssignmentTeacherTypes'

export const useCreateAllocationRule = (
  onCreateRuleSuccess?: (data: CreateAllocationRuleResponse) => void,
  onCreateRuleError?: (errors: any[]) => void,
) => {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (input: CreateAllocationRuleInput) => {
      const response = await executeQuery<
        CreateAllocationRuleResponse,
        {input: CreateAllocationRuleInput}
      >(CREATE_ALLOCATION_RULE_MUTATION, {input})

      return response
    },
    onSuccess: data => {
      if (data.createAllocationRule?.allocationErrors?.length > 0) {
        onCreateRuleError?.(data.createAllocationRule.allocationErrors)
      } else {
        // Remove cache for the assignedStudents data so a student's peerReviewStatus is up to date
        queryClient.removeQueries({queryKey: ['assignedStudents']})
        onCreateRuleSuccess?.(data)
      }
    },
    onError: (error, _variables, _context) => {
      onCreateRuleError?.([error])
    },
    networkMode: 'always',
  })
}
