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

import {gql} from '@apollo/client'
import {executeQuery} from '@canvas/graphql'
import getCookie from '@instructure/get-cookie'

export const ASSIGNMENT_RUBRIC_ASSESSMENTS_QUERY = gql`
  query GetAssignmentRubricAssessments($assignmentId: ID!) {
    assignment(id: $assignmentId) {
      _id
      rubricAssessment {
        assessmentsCount
      }
    }
  }
`

export type FetchRequestParams = {
  queryKey: (string | number)[]
}

export type RubricAssessmentsResponse = {
  assignment: {
    _id: string
    rubricAssessment: {
      assessmentsCount: number
    }
  }
}

const ASSIGNMENT_ID_INDEX = 1

export const fetchAssignmentRubricAssessments = async ({queryKey}: FetchRequestParams) =>
  executeQuery<RubricAssessmentsResponse>(ASSIGNMENT_RUBRIC_ASSESSMENTS_QUERY, {
    assignmentId: queryKey[ASSIGNMENT_ID_INDEX],
  })

type ErrorData = {
  message: string
}

export type RubricAssessmentImportResponse = {
  id: string
  rootAccountId: string
  workflowState: string
  userId: string
  assignmentId: string
  attachmentId: string
  courseId: string
  progress: number
  errorCount: number
  errorData: ErrorData[]
  createdAt: string
  updatedAt: string
  user: {
    id: string
    name: string
    createdAt: string
    sortableName: string
    shortName: string
    sisUserId: string | null
    integrationId: string | null
    sisImportId: string | null
    loginId: string
  }
  attachment: {
    id: string
    filename: string
    size: number
  }
}

export const importRubricAssessment = async (
  file?: File,
  courseId?: string,
  assignmentId?: string,
): Promise<RubricAssessmentImportResponse> => {
  if (!file || !courseId || !assignmentId) {
    throw new Error('No file to import')
  }

  const url = `/courses/${courseId}/assignments/${assignmentId}/rubric/assessments/imports`

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

export const fetchRubricAssessmentImport = async (
  importId?: string,
  courseId?: string,
  assignmentId?: string,
): Promise<RubricAssessmentImportResponse> => {
  const url = `/courses/${courseId}/assignments/${assignmentId}/rubric/assessments/imports/${importId}`

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

const mapImport = (importData: any): RubricAssessmentImportResponse => {
  return {
    id: importData.id,
    rootAccountId: importData.root_account_id,
    workflowState: importData.workflow_state,
    userId: importData.user_id,
    assignmentId: importData.assignment_id,
    attachmentId: importData.attachment_id,
    courseId: importData.course_id,
    progress: importData.progress,
    errorCount: importData.error_count,
    errorData: importData.error_data,
    createdAt: importData.created_at,
    updatedAt: importData.updated_at,
    user: {
      id: importData.user.id,
      name: importData.user.name,
      createdAt: importData.user.created_at,
      sortableName: importData.user.sortable_name,
      shortName: importData.user.short_name,
      sisUserId: importData.user.sis_user_id,
      integrationId: importData.user.integration_id,
      sisImportId: importData.user.sis_import_id,
      loginId: importData.user.login_id,
    },
    attachment: {
      id: importData.attachment.id,
      filename: importData.attachment.filename,
      size: importData.attachment.size,
    },
  }
}
