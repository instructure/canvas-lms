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

import type {GradingType, WorkflowState} from '../../../api.d'

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
  state: string
}

export type AssignmentConnection = {
  id: string
  assignmentGroupId: string
  name: string
  pointsPossible: number
  submissionTypes: string[]
  anonymizeStudents: boolean
  omitFromFinalGrade: boolean
  workflowState: WorkflowState
  gradingType: GradingType
  dueAt: string | null
  groupCategoryId?: string
  gradeGroupStudentsIndividually: boolean
  allowedAttempts: number
  anonymousGrading: boolean
  courseId: string
  gradesPublished: boolean
  htmlUrl: string
  moderatedGrading: boolean
  postManually: boolean
  published: boolean
  gradingPeriodId?: string | null
  hasSubmittedSubmissions: boolean
  inClosedGradingPeriod: boolean | null
}

export type AssignmentGroupConnection = {
  id: string
  name: string
  groupWeight: number
  rules: {
    dropLowest?: number
    dropHighest?: number
    neverDrop?: string[]
  }
  sisId: string | null
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
  redoRequest: boolean
  submittedAt: Date | null
  userId: string
  gradingPeriodId?: string
  excused?: boolean
}

export type Attachment = {
  id: string
  displayName: string
  mimeClass: string
  url: string
}

export type CommentConnection = {
  id: string
  comment: string
  mediaObject?: {
    id: string
    mediaDownloadUrl: string
  }
  attachments: Attachment[]
  author: {
    avatarUrl: string
    id: string
    name: string
    htmlUrl: string
  }
  updatedAt: string
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
  id: string
  loginId: string
  name: string
  hiddenName: string
  sortableName: string
}

export type GradebookUserSubmissionDetails = {
  assignmentId: string
  cachedDueDate: string | null
  customGradeStatus?: string | null
  deductedPoints: null | string | number
  enteredGrade: string | null
  enteredScore?: number | null
  excused: boolean
  grade: string | null
  gradeMatchesCurrentSubmission: boolean | null
  gradingPeriodId?: string
  id: string
  late: boolean
  latePolicyStatus?: string
  missing: boolean
  proxySubmitter?: string | null
  redoRequest: boolean
  score: null | number
  state: string
  submissionType?: string | null
  submittedAt: Date | null
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

export type GradebookSubmissionCommentsResponse = {
  submission: {
    commentsConnection: {
      nodes: CommentConnection[]
    }
  }
}
