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

import {saveRubric} from '../queries/RubricFormQueries'
import type {RubricFormProps} from '../types/RubricForm'
import qs from 'qs'

describe('saveRubric API', () => {
  let fetchMock: any

  beforeEach(() => {
    fetchMock = vi.fn()
    global.fetch = fetchMock

    // Mock getCookie for CSRF token
    vi.mock('@canvas/util/getCookie', () => ({
      getCookie: () => 'mock-csrf-token',
    }))
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  const mockSuccessResponse = {
    rubric: {
      id: '123',
      title: 'Test Rubric',
      criteria: [],
      pointsPossible: 10,
      buttonDisplay: 'numeric',
      ratingOrder: 'descending',
      workflowState: 'active',
      freeFormCriterionComments: false,
      canUpdateRubric: true,
    },
    rubric_association: {
      id: '456',
      association_id: '789',
      association_type: 'Assignment',
      use_for_grading: true,
      hide_points: false,
      hide_outcome_results: false,
      hide_score_total: false,
    },
  }

  it('uses associationTypeId when provided in rubric for Assignment', async () => {
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: async () => mockSuccessResponse,
    })

    const rubric: RubricFormProps = {
      id: '123',
      title: 'Test Rubric',
      criteria: [],
      pointsPossible: 10,
      buttonDisplay: 'numeric',
      ratingOrder: 'descending',
      workflowState: 'active',
      freeFormCriterionComments: false,
      canUpdateRubric: true,
      hasRubricAssociations: false,
      unassessed: true,
      associationType: 'Assignment',
      associationTypeId: '999', // This should be used
      courseId: '111',
      hidePoints: false,
      hideOutcomeResults: false,
      hideScoreTotal: false,
      useForGrading: true,
      rubricAssociationId: '456',
    }

    await saveRubric(rubric, '888') // assignmentId

    expect(fetchMock).toHaveBeenCalledTimes(1)

    const callArgs = fetchMock.mock.calls[0]
    const requestBody = qs.parse(callArgs[1].body) as any

    // Should use associationTypeId (999) instead of assignmentId (888)
    expect(requestBody.rubric_association.association_id).toBe('999')
  })

  it('uses assignmentId for Assignment type when associationTypeId is not provided', async () => {
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: async () => mockSuccessResponse,
    })

    const rubric: RubricFormProps = {
      id: '123',
      title: 'Test Rubric',
      criteria: [],
      pointsPossible: 10,
      buttonDisplay: 'numeric',
      ratingOrder: 'descending',
      workflowState: 'active',
      freeFormCriterionComments: false,
      canUpdateRubric: true,
      hasRubricAssociations: false,
      unassessed: true,
      associationType: 'Assignment',
      // associationTypeId is not provided
      hidePoints: false,
      hideOutcomeResults: false,
      hideScoreTotal: false,
      useForGrading: true,
      rubricAssociationId: '456',
    }

    await saveRubric(rubric, '888') // assignmentId

    expect(fetchMock).toHaveBeenCalledTimes(1)

    const callArgs = fetchMock.mock.calls[0]
    const requestBody = qs.parse(callArgs[1].body) as any

    // Should use assignmentId (888) based on associationType
    expect(requestBody.rubric_association.association_id).toBe('888')
  })

  it('uses accountId for Account type when associationTypeId is not provided', async () => {
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: async () => mockSuccessResponse,
    })

    const rubric: RubricFormProps = {
      id: '123',
      title: 'Test Rubric',
      criteria: [],
      pointsPossible: 10,
      buttonDisplay: 'numeric',
      ratingOrder: 'descending',
      workflowState: 'active',
      freeFormCriterionComments: false,
      canUpdateRubric: true,
      hasRubricAssociations: false,
      unassessed: true,
      associationType: 'Account',
      // associationTypeId is not provided
      accountId: '777',
      hidePoints: false,
      hideOutcomeResults: false,
      hideScoreTotal: false,
      useForGrading: false,
      rubricAssociationId: '456',
    }

    await saveRubric(rubric) // No assignmentId

    expect(fetchMock).toHaveBeenCalledTimes(1)

    const callArgs = fetchMock.mock.calls[0]
    const requestBody = qs.parse(callArgs[1].body) as any

    // Should use accountId (777) based on associationType
    expect(requestBody.rubric_association.association_id).toBe('777')
  })

  it('uses courseId for Course type when associationTypeId is not provided', async () => {
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: async () => mockSuccessResponse,
    })

    const rubric: RubricFormProps = {
      id: '123',
      title: 'Test Rubric',
      criteria: [],
      pointsPossible: 10,
      buttonDisplay: 'numeric',
      ratingOrder: 'descending',
      workflowState: 'active',
      freeFormCriterionComments: false,
      canUpdateRubric: true,
      hasRubricAssociations: false,
      unassessed: true,
      associationType: 'Course',
      // associationTypeId is not provided
      courseId: '666',
      hidePoints: false,
      hideOutcomeResults: false,
      hideScoreTotal: false,
      useForGrading: false,
      rubricAssociationId: '456',
    }

    await saveRubric(rubric) // No assignmentId

    expect(fetchMock).toHaveBeenCalledTimes(1)

    const callArgs = fetchMock.mock.calls[0]
    const requestBody = qs.parse(callArgs[1].body) as any

    // Should use courseId (666) based on associationType
    expect(requestBody.rubric_association.association_id).toBe('666')
  })

  it('prioritizes associationTypeId over context-specific IDs', async () => {
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: async () => mockSuccessResponse,
    })

    const rubric: RubricFormProps = {
      id: '123',
      title: 'Test Rubric',
      criteria: [],
      pointsPossible: 10,
      buttonDisplay: 'numeric',
      ratingOrder: 'descending',
      workflowState: 'active',
      freeFormCriterionComments: false,
      canUpdateRubric: true,
      hasRubricAssociations: false,
      unassessed: true,
      associationType: 'Assignment',
      associationTypeId: '999', // This should take priority
      accountId: '777',
      courseId: '666',
      hidePoints: false,
      hideOutcomeResults: false,
      hideScoreTotal: false,
      useForGrading: true,
      rubricAssociationId: '456',
    }

    await saveRubric(rubric, '888') // assignmentId also provided

    expect(fetchMock).toHaveBeenCalledTimes(1)

    const callArgs = fetchMock.mock.calls[0]
    const requestBody = qs.parse(callArgs[1].body) as any

    // Should use associationTypeId (999) even though assignmentId is provided
    expect(requestBody.rubric_association.association_id).toBe('999')
  })

  it('throws error when no association ID is available', async () => {
    const rubric: RubricFormProps = {
      id: '123',
      title: 'Test Rubric',
      criteria: [],
      pointsPossible: 10,
      buttonDisplay: 'numeric',
      ratingOrder: 'descending',
      workflowState: 'active',
      freeFormCriterionComments: false,
      canUpdateRubric: true,
      hasRubricAssociations: false,
      unassessed: true,
      associationType: 'Assignment',
      // No associationTypeId provided
      hidePoints: false,
      hideOutcomeResults: false,
      hideScoreTotal: false,
      useForGrading: true,
      rubricAssociationId: '456',
    }

    // No assignmentId, accountId, or courseId
    await expect(saveRubric(rubric)).rejects.toThrow('Missing rubric association type ID')
  })

  it('throws error when wrong association type ID is provided', async () => {
    const rubric: RubricFormProps = {
      id: '123',
      title: 'Test Rubric',
      criteria: [],
      pointsPossible: 10,
      buttonDisplay: 'numeric',
      ratingOrder: 'descending',
      workflowState: 'active',
      freeFormCriterionComments: false,
      canUpdateRubric: true,
      hasRubricAssociations: false,
      unassessed: true,
      associationType: 'Assignment',
      // No associationTypeId provided
      // Providing courseId and accountId but not assignmentId
      courseId: '666',
      accountId: '777',
      hidePoints: false,
      hideOutcomeResults: false,
      hideScoreTotal: false,
      useForGrading: true,
      rubricAssociationId: '456',
    }

    // Assignment type requires assignmentId, but only courseId and accountId are provided
    await expect(saveRubric(rubric)).rejects.toThrow('Missing rubric association type ID')
  })

  it('throws error when Course type has no courseId', async () => {
    const rubric: RubricFormProps = {
      id: '123',
      title: 'Test Rubric',
      criteria: [],
      pointsPossible: 10,
      buttonDisplay: 'numeric',
      ratingOrder: 'descending',
      workflowState: 'active',
      freeFormCriterionComments: false,
      canUpdateRubric: true,
      hasRubricAssociations: false,
      unassessed: true,
      associationType: 'Course',
      // No associationTypeId or courseId provided
      // Only assignmentId and accountId available
      accountId: '777',
      hidePoints: false,
      hideOutcomeResults: false,
      hideScoreTotal: false,
      useForGrading: false,
      rubricAssociationId: '456',
    }

    // Course type requires courseId
    await expect(saveRubric(rubric, '888')).rejects.toThrow('Missing rubric association type ID')
  })

  it('throws error when Account type has no accountId', async () => {
    const rubric: RubricFormProps = {
      id: '123',
      title: 'Test Rubric',
      criteria: [],
      pointsPossible: 10,
      buttonDisplay: 'numeric',
      ratingOrder: 'descending',
      workflowState: 'active',
      freeFormCriterionComments: false,
      canUpdateRubric: true,
      hasRubricAssociations: false,
      unassessed: true,
      associationType: 'Account',
      // No associationTypeId or accountId provided
      // Only courseId available
      courseId: '666',
      hidePoints: false,
      hideOutcomeResults: false,
      hideScoreTotal: false,
      useForGrading: false,
      rubricAssociationId: '456',
    }

    // Account type requires accountId
    await expect(saveRubric(rubric, '888')).rejects.toThrow('Missing rubric association type ID')
  })
})
