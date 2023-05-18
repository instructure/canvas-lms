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

import {WorkflowState} from '../../../api.d'

/**
 * Temporarily generate types for GraphQL queries until we have automated generation setup
 */

export type UserConnectionResponse = {
  enrollments: {
    section: {
      name: string
      id: string
    }
  }
  email: string
  id: string
  loginId: string
  name: string
  sortableName: string
}

export type AssignmentConnection = {
  id: string
  name: string
  pointsPossible: number
  submissionTypes: string[]
  anonymizeStudents: boolean
  omitFromFinalGrade: boolean
  workflowState: WorkflowState
}

export type AssignmentGroupConnection = {
  id: string
  name: string
  groupWeight: number
  rules: {
    drop_lowest?: number
    drop_highest?: number
    never_drop?: string[]
  }
  state: string
  position: number
  assignmentsConnection: {
    nodes: AssignmentConnection[]
  }
}

export type SubmissionConnectionResponse = {
  assignment: {
    id: string
  }
  user: UserConnectionResponse
  id: string
  score: number
  grade: string
}

export type EnrollmentGrades = {
  unpostedCurrentGrade: number
  unpostedCurrentScore: number
  unpostedFinalGrade: number
  unpostedFinalScore: number
}

export type GradebookQueryResponse = {
  course: {
    enrollmentsConnection: {
      nodes: {
        user: UserConnectionResponse
      }[]
    }
    submissionsConnection: {
      nodes: SubmissionConnectionResponse[]
    }
    assignmentGroupsConnection: {
      nodes: AssignmentGroupConnection[]
    }
  }
}

export type GradebookStudentDetails = {
  enrollments: {
    id: string
    grades: EnrollmentGrades
    section: {
      id: string
      name: string
    }
  }[]
  loginId: string
  name: string
}

export type GradebookUserSubmissionDetails = {
  grade: string
  id: string
  score: number
  assignmentId: string
  workflowState: string
}

export type GradebookStudentQueryResponse = {
  course: {
    usersConnection: {
      nodes: GradebookStudentDetails[]
    }
    submissionsConnection: {
      nodes: GradebookUserSubmissionDetails[]
    }
  }
}

export type UserSubmissionMap = {
  [userId: string]: {
    email: string
    submissions: {
      [assignmentId: string]: {
        score: number
        grade: string
      }
    }
  }
}

// TODO: next commit will clean up types and move types to different files
export type GradebookOptions = {
  includeUngradedAssignments?: boolean
}
