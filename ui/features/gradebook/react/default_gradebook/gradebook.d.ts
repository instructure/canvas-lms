/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import StudentDatastore from './stores/StudentDatastore'

export type Course = {
  id: string
}

export type Enrollment = {
  course_section_id: string
  type: string
  grades: {
    html_url: string
  }
}

export type Student = {
  id: string
  name: string
  displayName: string
  avatar_url: string
  enrollments: Enrollment[]
  loaded: boolean
  initialized: boolean
  isConcluded: boolean
  total_grade: number
} & {
  // computed values
  computed_current_score: number
  computed_final_score: number
  isInactive: boolean
  cssClass: string
  sections: string[]
}

export type StudentMap = {
  [key: string]: Student
}

export type StudentGroup = {
  id: string
}

export type StudentGroupMap = {
  [key: string]: StudentGroup
}

export type StudentGroupCategory = {
  id: number
  groups: StudentGroup[]
}

export type StudentGroupCategoryMap = {
  [key: string]: StudentGroupCategory
}

export type Assignment = {
  id: string
  name: string
  assignment_id: string
  user_id: string
  hidden: boolean
  anonymize_students: boolean
  published: boolean
  submission_types: string
  assignment_group_id: string
  module_ids: string[]
  effectiveDueDates: EffectiveDueDateUserMap
  inClosedGradingPeriod: boolean
  grading_type: string
  points_possible: number
  omit_from_final_grade: boolean
  only_visible_to_overrides: boolean
  assignment_visibility: any
  grading_standard_id: string | null
  hasDownloadedSubmissions: boolean
  overrides: any
}

export type AssignmentMap = {
  [key: string]: Assignment
}

export type AssignmentGroup = {
  id: string
  name: string
  position: number
  group_weight: number
  assignments: Assignment[]
}

export type AssignmentGroupMap = {
  [key: string]: AssignmentGroup
}

export type Submission = {
  user_id: string
  assignment_id: string
  submitted_at: string
  gradingType: string
  excused: boolean
  hidden: boolean
  rawGrade: string | null
  grade: string | null
  posted_at: string
  assignment_visible: boolean
}

export type UserSubmissionGroup = {
  user_id: string
  submissions: Submission[]
}

export type CourseContent = {
  contextModules: any[]
  courseGradingScheme: {
    data: any
  } | null
  defaultGradingScheme: {
    data: any
  } | null
  gradingSchemes: any
  gradingPeriodAssignments: any
  assignmentStudentVisibility: {[key: string]: null | boolean}
  latePolicy: any
  students: StudentDatastore
  modulesById: any
}

export type ContentLoadStates = {
  assignmentGroupsLoaded: boolean
  contextModulesLoaded: boolean
  assignmentsLoaded: {
    all: boolean
    gradingPeriod: any
  }
  customColumnsLoaded: boolean
  gradingPeriodAssignmentsLoaded: boolean
  overridesColumnUpdating: boolean
  studentIdsLoaded: boolean
  studentsLoaded: boolean
  submissionsLoaded: boolean
  teacherNotesColumnUpdating: boolean
}

export type PendingGradeInfo = {
  userId: string
  assignmentId: string
  valid: boolean
}

export type InitialActionStates = {
  pendingGradeInfo: PendingGradeInfo[]
}

export type FlashAlertType = {
  key: string
  message: string
  variant: string
}

export type Module = {
  id: string
  name: string
  position: number
}

export type Section = {
  id: string
  name: string
}

export type SectionMap = {
  [key: string]: Section
}

export type FilterCondition = {
  id: string
  type?: string
  value?: string
  createdAt: string
}

export type Filter = {
  id: string
  label?: string
  conditions: FilterCondition[]
  isApplied: boolean
  createdAt: string
}

export type AssignmentDueDate = {
  due_at: string
  grading_period_id: string | null
  in_closed_grading_period: boolean
}

export type EffectiveDueDateUserMap = {
  [user_id: string]: AssignmentDueDate
}

export type EffectiveDueDateAssignmentUserMap = {
  [assignment_id: string]: EffectiveDueDateUserMap
}

export type GradingPeriod = {
  id: string
  startDate: number
}

export type GradingPeriodSet = {
  gradingPeriods: GradingPeriod[]
  displayTotalsForAllGradingPeriods: boolean
}

export type ColumnSizeSettings = {
  [key: string]: string
}
