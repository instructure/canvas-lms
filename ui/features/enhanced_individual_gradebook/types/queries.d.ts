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

import {WorkflowState} from '../../../api'

export type UserConnection = {
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

export type EnrollmentConnection = {
  user: UserConnection
  courseSectionId: string
}

export type AssignmentConnection = {
  id: string
  name: string
  pointsPossible: number
  submissionTypes: string[]
  anonymizeStudents: boolean
  omitFromFinalGrade: boolean
  workflowState: WorkflowState
  gradingType: string
  dueAt?: string
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

export type SectionConnection = {
  id: string
  name: string
}

export type SubmissionConnection = {
  assignmentId: string
  id: string
  score?: number | null
  grade?: string | null
}

export type GradebookQueryResponse = {
  course: {
    enrollmentsConnection: {
      nodes: EnrollmentConnection[]
    }
    sectionsConnection: {
      nodes: SectionConnection[]
    }
    submissionsConnection: {
      nodes: SubmissionConnection[]
    }
    assignmentGroupsConnection: {
      nodes: AssignmentGroupConnection[]
    }
  }
}

export type GradebookStudentDetails = {
  enrollments: {
    id: string
    section: {
      id: string
      name: string
    }
  }[]
  loginId: string
  name: string
}

export type GradebookUserSubmissionDetails = {
  grade: string | null
  id: string
  score: number | null
  enteredScore?: number | null
  assignmentId: string
  submissionType?: string | null
  proxySubmitter?: string | null
  submittedAt?: Date | null
  state: string
  excused: boolean
  late: boolean
  latePolicyStatus?: string
  missing: boolean
  userId: string
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
