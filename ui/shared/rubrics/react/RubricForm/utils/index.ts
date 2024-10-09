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

import type {Rubric, RubricAssociation, RubricCriterion} from '@canvas/rubrics/react/types/rubric'
import type {RubricQueryResponse} from '../queries/RubricFormQueries'
import type {RubricFormProps} from '../types/RubricForm'

export const translateRubricQueryResponse = (fields: RubricQueryResponse): RubricFormProps => {
  return {
    id: fields.id,
    title: fields.title ?? '',
    hasRubricAssociations: fields.hasRubricAssociations ?? false,
    hidePoints: fields.rubricAssociationForContext?.hidePoints ?? false,
    criteria: fields.criteria ?? [],
    pointsPossible: fields.pointsPossible ?? 0,
    buttonDisplay: fields.buttonDisplay ?? 'numeric',
    ratingOrder: fields.ratingOrder ?? 'descending',
    unassessed: fields.unassessed ?? true,
    workflowState: fields.workflowState ?? 'active',
    freeFormCriterionComments: fields.freeFormCriterionComments ?? false,
    hideOutcomeResults: fields.rubricAssociationForContext?.hideOutcomeResults ?? false,
    hideScoreTotal: fields.rubricAssociationForContext?.hideScoreTotal ?? false,
    useForGrading: fields.rubricAssociationForContext?.useForGrading ?? false,
  }
}

export const translateRubricData = (
  rubric: Rubric,
  rubricAssociation: RubricAssociation
): RubricFormProps => {
  return {
    id: rubric.id,
    title: rubric.title ?? '',
    hasRubricAssociations: rubric.hasRubricAssociations ?? false,
    hidePoints: rubricAssociation.hidePoints ?? false,
    criteria: rubric.criteria ?? [],
    pointsPossible: rubric.pointsPossible ?? 0,
    buttonDisplay: rubric.buttonDisplay ?? 'numeric',
    ratingOrder: rubric.ratingOrder ?? 'descending',
    unassessed: rubric.unassessed ?? true,
    workflowState: rubric.workflowState ?? 'active',
    freeFormCriterionComments: rubric.freeFormCriterionComments ?? false,
    hideOutcomeResults: rubricAssociation.hideOutcomeResults ?? false,
    hideScoreTotal: rubricAssociation.hideScoreTotal ?? false,
    useForGrading: rubricAssociation.useForGrading ?? false,
    rubricAssociationId: rubricAssociation.id,
  }
}

type ReorderProps = {
  list: RubricCriterion[]
  startIndex: number
  endIndex: number
}

export const reorder = ({list, startIndex, endIndex}: ReorderProps) => {
  const result = Array.from(list)
  const [removed] = result.splice(startIndex, 1)
  result.splice(endIndex, 0, removed)

  return result
}

export const stripPTags = (htmlString: string) => {
  return htmlString?.replace(/^<p>(.*)<\/p>$/, '$1')
}
