/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {gql} from '@apollo/client'
import {executeQuery} from '@canvas/graphql'
import type {
  RubricQueryResponse,
  DeleteRubricQueryResponse,
  DuplicateRubricQueryResponse,
  archiveRubricResponse,
  // @ts-expect-error
  RubricImport,
} from '../types/Rubric'
import getCookie from '@instructure/get-cookie'
import qs from 'qs'
import type {Rubric, RubricCriterion} from '@canvas/rubrics/react/types/rubric'
import type {UsedLocation} from '@canvas/grading_scheme/gradingSchemeApiModel'
import doFetchApi from '@canvas/do-fetch-api-effect'

const rubricsPerPage = 100
const COURSE_RUBRICS_QUERY = gql`
  query CourseRubricsQuery($courseId: ID!, $after: String) {
    course(id: $courseId) {
      rubricsConnection(first: ${rubricsPerPage}, after: $after) {
        nodes {
          id: _id
          buttonDisplay
          criteriaCount
          criteria {
            id: _id
            ratings {
              description
              longDescription
              points
              id: _id
            }
            points
            longDescription
            description
            ignoreForScoring
            learningOutcomeId
            criterionUseRange
          }
          hasRubricAssociations
          hidePoints
          freeFormCriterionComments
          pointsPossible
          ratingOrder
          title
          workflowState
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
`

const ACCOUNT_RUBRICS_QUERY = gql`
  query AccountRubricsQuery($accountId: ID!, $after: String) {
    account(id: $accountId) {
      rubricsConnection(first: ${rubricsPerPage}, after: $after) {
        nodes {
          id: _id
          buttonDisplay
          criteriaCount
          criteria {
            id: _id
            ratings {
              description
              longDescription
              points
            }
            points
            longDescription
            description
            ignoreForScoring
            learningOutcomeId
            criterionUseRange
          }
          hasRubricAssociations
          hidePoints
          freeFormCriterionComments
          pointsPossible
          ratingOrder
          title
          workflowState
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
`

const RUBRIC_PREVIEW_QUERY = gql`
  query RubricQuery($id: ID!) {
    rubric(id: $id) {
      criteria {
        id: _id
        ratings {
          description
          longDescription
          points
          id: _id
        }
        points
        longDescription
        description
        criterionUseRange
        learningOutcomeId
        ignoreForScoring
        masteryPoints
        outcome {
          displayName
          title
        }
      }
      title
      ratingOrder
      freeFormCriterionComments
    }
  }
`

const UPDATE_RUBRIC_ARCHIVE_STATE = gql`
  mutation UpdateRubricArchivedState($id: ID!, $archived: Boolean!) {
    updateRubricArchivedState(input: {id: $id, archived: $archived}) {
      rubric {
        _id
        workflowState
      }
      errors {
        attribute
        message
      }
    }
  }
`

type AccountRubricsQueryVariables = {
  accountId: string
  courseId?: never
}

type CourseRubricsQueryVariables = {
  accountId?: never
  courseId: string
}

type CourseRubricQueryResponse = {
  course: RubricQueryResponse
}

type RubricPreviewQueryResponse = {
  rubric: Pick<
    Rubric,
    'criteria' | 'title' | 'ratingOrder' | 'freeFormCriterionComments' | 'pointsPossible'
  >
}

type AccountRubricQueryResponse = {
  account: RubricQueryResponse
}

type DeleteRubricProps = {
  id?: string
  accountId?: string
  courseId?: string
}

type DuplicateRubricProps = {
  id?: string
  accountId?: string
  courseId?: string
  title: string
  hidePoints?: boolean
  freeFormCriterionComments?: boolean
  criteria?: RubricCriterion[]
  pointsPossible: number
  buttonDisplay?: string
  ratingOrder?: string
  workflowState?: string
}

type RubricArchiveResponse = {
  rubric: {
    _id: string
    workflowState: string
  }

  errors: {
    attribute: string
    message: string
  }
}

export type FetchRubricVariables = AccountRubricsQueryVariables | CourseRubricsQueryVariables

export const fetchCourseRubrics = async (
  pageParam: string | null,
  queryVariables: FetchRubricVariables,
) => {
  const {course} = await executeQuery<CourseRubricQueryResponse>(COURSE_RUBRICS_QUERY, {
    ...queryVariables,
    after: pageParam,
  })

  return course
}

export const fetchAccountRubrics = async (
  pageParam: string | null,
  queryVariables: FetchRubricVariables,
) => {
  const {account} = await executeQuery<AccountRubricQueryResponse>(ACCOUNT_RUBRICS_QUERY, {
    ...queryVariables,
    after: pageParam,
  })

  return account
}

export const fetchRubricCriterion = async (id?: string) => {
  if (!id) return

  const {rubric} = await executeQuery<RubricPreviewQueryResponse>(RUBRIC_PREVIEW_QUERY, {id})
  return rubric
}

type FetchRubricUsedLocationsParams = {
  accountId?: string
  courseId?: string
  id?: string
  nextPagePath?: string
}
export const fetchRubricUsedLocations = async ({
  accountId,
  courseId,
  id,
  nextPagePath,
}: FetchRubricUsedLocationsParams) => {
  if (!id) {
    return {
      usedLocations: [],
      isLastPage: true,
      nextPage: '',
    }
  }

  const urlPrefix = accountId ? `accounts/${accountId}` : `courses/${courseId}`
  const path = nextPagePath ?? `/api/v1/${urlPrefix}/rubrics/${id}/used_locations`

  const result = await doFetchApi({
    path,
    method: 'GET',
  })

  if (!result.response.ok) {
    throw new Error(`Failed to fetch rubric locations: ${result.response.statusText}`)
  }

  const usedLocations = (result.json as UsedLocation[]) ?? []

  return {
    usedLocations,
    isLastPage: result.link?.next === undefined,
    nextPage: result.link?.next?.url,
  }
}

export const deleteRubric = async ({
  id,
  accountId,
  courseId,
}: DeleteRubricProps): Promise<DeleteRubricQueryResponse> => {
  const urlPrefix = accountId ? `/accounts/${accountId}` : `/courses/${courseId}`
  const url = `${urlPrefix}/rubrics/${id ?? ''}`
  const method = 'DELETE'

  const response = await fetch(url, {
    method,
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    },
    body: qs.stringify({
      _method: method,
      rubric: {
        id,
      },
    }),
  })

  if (!response.ok) {
    throw new Error(`Failed to delete rubric: ${response.statusText}`)
  }

  const {rubric: deletedRubric, error} = await response.json()

  if (error) {
    throw new Error(`Failed to delete rubric`)
  }

  return deletedRubric
}

export const duplicateRubric = async ({
  title,
  hidePoints,
  freeFormCriterionComments,
  accountId,
  courseId,
  criteria,
  ratingOrder,
  buttonDisplay,
  workflowState,
}: DuplicateRubricProps): Promise<DuplicateRubricQueryResponse> => {
  const urlPrefix = accountId ? `/accounts/${accountId}` : `/courses/${courseId}`
  const url = `${urlPrefix}/rubrics/`
  const method = 'POST'

  const duplicateCriteria = criteria?.map(criterion => {
    return {
      id: criterion.id,
      description: criterion.description,
      long_description: criterion.longDescription,
      points: criterion.points,
      learning_outcome_id: criterion.learningOutcomeId,
      criterion_use_range: criterion.criterionUseRange,
      ratings: criterion.ratings.map(rating => ({
        description: rating.description,
        long_description: rating.longDescription,
        points: rating.points,
        id: rating.id,
      })),
    }
  })

  const response = await fetch(url, {
    method,
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    },
    body: qs.stringify({
      _method: method,
      rubric: {
        title: title + ' Copy',
        hide_points: hidePoints,
        free_form_criterion_comments: freeFormCriterionComments,
        criteria: duplicateCriteria,
        button_display: buttonDisplay,
        rating_order: ratingOrder,
        is_duplicate: true,
        workflow_state: workflowState,
      },
      rubric_association: {
        association_id: accountId ?? courseId,
        association_type: accountId ? 'Account' : 'Course',
      },
    }),
  })

  if (!response.ok) {
    throw new Error(`Failed to duplicate rubric: ${response.statusText}`)
  }

  const {rubric: duplicatedRubric, error} = await response.json()

  if (error) {
    throw new Error(`Failed to duplicate rubric`)
  }

  return duplicatedRubric
}

export const archiveRubric = async (rubricId: string): Promise<archiveRubricResponse> => {
  const {rubric} = await executeQuery<RubricArchiveResponse>(UPDATE_RUBRIC_ARCHIVE_STATE, {
    id: rubricId,
    archived: true,
  })

  return rubric
}

export const unarchiveRubric = async (rubricId: string): Promise<archiveRubricResponse> => {
  const {rubric} = await executeQuery<RubricArchiveResponse>(UPDATE_RUBRIC_ARCHIVE_STATE, {
    id: rubricId,
    archived: false,
  })

  return rubric
}

export const importRubric = async (
  file?: File,
  accountId?: string,
  courseId?: string,
): Promise<RubricImport> => {
  if (!file) {
    throw new Error('No file to import')
  }

  const urlPrefix = accountId ? `/accounts/${accountId}` : `/courses/${courseId}`
  const url = `/api/v1/${urlPrefix}/rubrics/upload`

  const formData = new FormData()
  formData.append('attachment', file)

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
    },
    body: formData,
  })

  if (!response.ok) {
    throw new Error(`Failed to import rubric: ${response.statusText}`)
  }

  return mapImport(await response.json())
}

export const fetchRubricImport = async (
  importId?: string,
  accountId?: string,
  courseId?: string,
): Promise<RubricImport> => {
  const urlPrefix = accountId ? `/accounts/${accountId}` : `/courses/${courseId}`
  const url = `/api/v1/${urlPrefix}/rubrics/upload/${importId ?? 'latest'}`

  const response = await fetch(url, {
    method: 'GET',
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
    },
  })

  if (!response.ok) {
    throw new Error(`Failed to find the rubric import: ${response.statusText}`)
  }

  return mapImport(await response.json())
}

export const downloadRubrics = async (
  courseId: string | undefined,
  accountId: string | undefined,
  selectedRubricIds: string[],
) => {
  let postUrl = ''

  if (courseId) {
    postUrl = `/api/v1/courses/${courseId}/rubrics/download_rubrics`
  } else if (accountId) {
    postUrl = `/api/v1/accounts/${accountId}/rubrics/download_rubrics`
  } else {
    return
  }

  const response = await fetch(postUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': getCookie('_csrf_token'),
    },
    body: JSON.stringify({
      rubric_ids: selectedRubricIds,
    }),
  })

  if (!response.ok) {
    throw new Error(`Failed to download rubrics: ${response.statusText}`)
  }

  const blob = await response.blob()
  const url = window.URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.setAttribute('download', 'rubrics_export.csv')
  document.body.appendChild(link)
  link.click()
  link?.parentNode?.removeChild(link)
  window.URL.revokeObjectURL(url)
}

export const getImportedRubrics = async (
  importId: string,
  accountId?: string,
  courseId?: string,
): Promise<Rubric[]> => {
  const urlPrefix = accountId ? `/accounts/${accountId}` : `/courses/${courseId}`
  const url = `/api/v1/${urlPrefix}/rubrics/upload/${importId}/rubrics`

  const response = await fetch(url, {
    method: 'GET',
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
    },
  })

  if (!response.ok) {
    throw new Error(`Failed to get rubrics for import: ${response.statusText}`)
  }

  const jsonResponse = await response.json()
  const rubrics: Rubric[] = jsonResponse.map((rubric: any) => {
    return {
      id: rubric.id.toString(),
      title: rubric.title,
      workflowState: 'draft',
      pointsPossible: rubric.points_possible,
      hasRubricAssociations: false,
      criteriaCount: rubric.data.length,
      criteria: rubric.data.map((criterion: any) => {
        return {
          id: criterion.id,
          description: criterion.description,
          longDescription: criterion.long_description,
          points: criterion.points,
          criterionUseRange: criterion.criterion_use_range,
          ratings: criterion.ratings.map((rating: any) => {
            return {
              description: rating.description,
              longDescription: rating.long_description,
              points: rating.points,
            }
          }),
        }
      }),
    }
  })
  return rubrics
}

// private functions

const mapImport = (importData: any): RubricImport => {
  return {
    attachment: {
      id: importData.attachment.id,
      filename: importData.attachment.filename,
      size: importData.attachment.size,
    },
    id: importData.id,
    createdAt: importData.created_at,
    errorCount: importData.error_count,
    errorData: importData.error_data,
    progress: importData.progress,
    workflowState: importData.workflow_state,
  }
}
