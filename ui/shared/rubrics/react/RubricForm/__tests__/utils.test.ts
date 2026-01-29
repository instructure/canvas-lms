/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {translateRubricQueryResponse, translateRubricData} from '../utils'
import type {RubricQueryResponse} from '../queries/RubricFormQueries'
import type {Rubric, RubricAssociation} from '@canvas/rubrics/react/types/rubric'

describe('RubricForm utils', () => {
  describe('translateRubricQueryResponse', () => {
    it('sets associationTypeId from rubricAssociationForContext', () => {
      const queryResponse: RubricQueryResponse = {
        id: '123',
        title: 'Test Rubric',
        criteria: [],
        pointsPossible: 10,
        buttonDisplay: 'numeric',
        ratingOrder: 'descending',
        workflowState: 'active',
        freeFormCriterionComments: false,
        canUpdateRubric: true,
        unassessed: true,
        hasRubricAssociations: false,
        rubricAssociationForContext: {
          id: '456',
          associationType: 'Assignment',
          associationId: '789',
          useForGrading: true,
          hidePoints: false,
          hideOutcomeResults: false,
          hideScoreTotal: false,
        },
      }

      const result = translateRubricQueryResponse(queryResponse)

      expect(result.associationTypeId).toBe('789')
      expect(result.associationType).toBe('Assignment')
    })

    it('sets associationTypeId to undefined when rubricAssociationForContext is missing', () => {
      const queryResponse: RubricQueryResponse = {
        id: '123',
        title: 'Test Rubric',
        criteria: [],
        pointsPossible: 10,
        buttonDisplay: 'numeric',
        ratingOrder: 'descending',
        workflowState: 'active',
        freeFormCriterionComments: false,
        canUpdateRubric: true,
        unassessed: true,
        hasRubricAssociations: false,
      }

      const result = translateRubricQueryResponse(queryResponse)

      expect(result.associationTypeId).toBeUndefined()
      expect(result.associationType).toBe('Assignment') // Default value
    })

    it('handles different association types correctly', () => {
      const queryResponse: RubricQueryResponse = {
        id: '123',
        title: 'Test Rubric',
        criteria: [],
        pointsPossible: 10,
        buttonDisplay: 'numeric',
        ratingOrder: 'descending',
        workflowState: 'active',
        freeFormCriterionComments: false,
        canUpdateRubric: true,
        unassessed: true,
        hasRubricAssociations: false,
        rubricAssociationForContext: {
          id: '456',
          associationType: 'Account',
          associationId: '999',
          useForGrading: false,
          hidePoints: false,
          hideOutcomeResults: false,
          hideScoreTotal: false,
        },
      }

      const result = translateRubricQueryResponse(queryResponse)

      expect(result.associationTypeId).toBe('999')
      expect(result.associationType).toBe('Account')
    })
  })

  describe('translateRubricData', () => {
    it('sets associationTypeId from rubricAssociation', () => {
      const rubric: Rubric = {
        id: '123',
        title: 'Test Rubric',
        criteriaCount: 0,
        criteria: [],
        pointsPossible: 10,
        buttonDisplay: 'numeric',
        ratingOrder: 'descending',
        workflowState: 'active',
        freeFormCriterionComments: false,
        canUpdateRubric: true,
      }

      const rubricAssociation: RubricAssociation = {
        id: '456',
        associationType: 'Assignment',
        associationId: '789',
        useForGrading: true,
        hidePoints: false,
        hideOutcomeResults: false,
        hideScoreTotal: false,
      }

      const result = translateRubricData(rubric, rubricAssociation)

      expect(result.associationTypeId).toBe('789')
      expect(result.associationType).toBe('Assignment')
      expect(result.rubricAssociationId).toBe('456')
    })

    it('handles Course association type', () => {
      const rubric: Rubric = {
        id: '123',
        title: 'Course Rubric',
        criteriaCount: 0,
        criteria: [],
        pointsPossible: 15,
        buttonDisplay: 'numeric',
        ratingOrder: 'ascending',
        workflowState: 'active',
        freeFormCriterionComments: true,
        canUpdateRubric: true,
      }

      const rubricAssociation: RubricAssociation = {
        id: '111',
        associationType: 'Course',
        associationId: '222',
        useForGrading: false,
        hidePoints: true,
        hideOutcomeResults: true,
        hideScoreTotal: true,
      }

      const result = translateRubricData(rubric, rubricAssociation)

      expect(result.associationTypeId).toBe('222')
      expect(result.associationType).toBe('Course')
      expect(result.hidePoints).toBe(true)
      expect(result.hideOutcomeResults).toBe(true)
      expect(result.hideScoreTotal).toBe(true)
    })

    it('handles Account association type', () => {
      const rubric: Rubric = {
        id: '555',
        title: 'Account Rubric',
        criteriaCount: 0,
        criteria: [],
        pointsPossible: 20,
        buttonDisplay: 'points',
        ratingOrder: 'descending',
        workflowState: 'active',
        freeFormCriterionComments: false,
        canUpdateRubric: false,
      }

      const rubricAssociation: RubricAssociation = {
        id: '666',
        associationType: 'Account',
        associationId: '777',
        useForGrading: false,
        hidePoints: false,
        hideOutcomeResults: false,
        hideScoreTotal: false,
      }

      const result = translateRubricData(rubric, rubricAssociation)

      expect(result.associationTypeId).toBe('777')
      expect(result.associationType).toBe('Account')
    })

    it('preserves all other rubric properties', () => {
      const rubric: Rubric = {
        id: '123',
        title: 'Test Rubric',
        criteriaCount: 1,
        criteria: [
          {
            id: '1',
            description: 'Criterion 1',
            longDescription: 'Long desc',
            points: 10,
            ratings: [],
            ignoreForScoring: false,
            masteryPoints: 5,
            criterionUseRange: false,
          },
        ],
        pointsPossible: 10,
        buttonDisplay: 'points',
        ratingOrder: 'ascending',
        workflowState: 'active',
        freeFormCriterionComments: true,
        canUpdateRubric: true,
        hasRubricAssociations: true,
        unassessed: false,
      }

      const rubricAssociation: RubricAssociation = {
        id: '456',
        associationType: 'Assignment',
        associationId: '789',
        useForGrading: true,
        hidePoints: true,
        hideOutcomeResults: true,
        hideScoreTotal: true,
      }

      const result = translateRubricData(rubric, rubricAssociation)

      expect(result.id).toBe('123')
      expect(result.title).toBe('Test Rubric')
      expect(result.criteria).toEqual(rubric.criteria)
      expect(result.pointsPossible).toBe(10)
      expect(result.buttonDisplay).toBe('points')
      expect(result.ratingOrder).toBe('ascending')
      expect(result.freeFormCriterionComments).toBe(true)
      expect(result.canUpdateRubric).toBe(true)
      expect(result.hasRubricAssociations).toBe(true)
      expect(result.unassessed).toBe(false)
    })
  })
})
