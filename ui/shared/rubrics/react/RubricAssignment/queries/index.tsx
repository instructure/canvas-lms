/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import getCookie from '@instructure/get-cookie'
import qs from 'qs'
import type {GradingRubricContext} from '../types/rubricAssignment'
import type {Rubric} from '../../types/rubric'
import {mapRubricUnderscoredKeysToCamelCase} from '../../utils'

export const removeRubricFromAssignment = async (courseId: string, rubricAssociationId: string) => {
  return fetch(`/courses/${courseId}/rubric_associations/${rubricAssociationId}`, {
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    },
    method: 'POST',
    body: qs.stringify({
      _method: 'DELETE',
    }),
  })
}

export const addRubricToAssignment = async (
  courseId: string,
  assignmentId: string,
  rubricId: string
) => {
  const response = await fetch(`/courses/${courseId}/rubric_associations`, {
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    },
    method: 'POST',
    body: qs.stringify({
      _method: 'POST',
      rubric_association: {
        association_type: 'Assignment',
        association_id: assignmentId,
        rubric_id: rubricId,
        purpose: 'grading',
      },
    }),
  })

  if (!response.ok) {
    throw new Error('Failed to add rubric to assignment')
  }

  const result = await response.json()

  return {
    rubricAssociation: result.rubric_association,
    rubric: mapRubricUnderscoredKeysToCamelCase(result.rubric),
  }
}

export const getGradingRubricContexts = async (
  courseId: string
): Promise<GradingRubricContext[]> => {
  const contexts = await fetch(`/courses/${courseId}/grading_rubrics`, {
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
    },
  })

  if (!contexts.ok) {
    throw new Error('Failed to get grading rubric contexts')
  }

  return (await contexts.json()) as GradingRubricContext[]
}

type GradingRubricForContextResponse = {
  rubricAssociationId: string
  rubric: Rubric
}
export const getGradingRubricsForContext = async (
  courseId: string,
  contextCode?: string
): Promise<GradingRubricForContextResponse[]> => {
  if (!contextCode) {
    throw Error('Context code is required')
  }

  const contexts = await fetch(`/courses/${courseId}/grading_rubrics?context_code=${contextCode}`, {
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
    },
  })

  if (!contexts.ok) {
    throw new Error('Failed to get grading rubric contexts')
  }

  const results = await contexts.json()

  return results.map((result: {rubric_association: any}) => {
    return {
      rubricAssociationId: result.rubric_association?.id,
      rubric: mapRubricUnderscoredKeysToCamelCase(result.rubric_association?.rubric),
    }
  })
}
