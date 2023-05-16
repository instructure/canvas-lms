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

export type AssignmentConnectionResponse = {
  id: string
  name: string
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
    assignmentsConnection: {
      nodes: AssignmentConnectionResponse[]
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
