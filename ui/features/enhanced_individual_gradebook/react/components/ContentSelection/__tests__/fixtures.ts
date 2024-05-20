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
import type {SortableAssignment} from 'features/enhanced_individual_gradebook/types'
import type {ContentSelectionComponentProps} from '..'
import {defaultGradebookOptions} from '../../__tests__/fixtures'

export const defaultContentSelectionProps: ContentSelectionComponentProps = {
  courseId: '1',
  assignments: [],
  selectedStudentId: null,
  selectedAssignmentId: null,
  gradebookOptions: defaultGradebookOptions,
  onStudentChange: () => {},
  onAssignmentChange: () => {},
}

export const defaultSortableAssignments: SortableAssignment[] = [
  {
    id: '1',
    assignmentGroupId: '1',
    allowedAttempts: 1,
    anonymousGrading: false,
    anonymizeStudents: false,
    courseId: '1',
    dueAt: null,
    gradeGroupStudentsIndividually: false,
    gradesPublished: false,
    gradingType: 'points',
    htmlUrl: '/courses/1/assignments/1',
    moderatedGrading: false,
    hasSubmittedSubmissions: false,
    name: 'Missing Assignment 1',
    omitFromFinalGrade: false,
    pointsPossible: 10,
    postManually: false,
    submissionTypes: ['online_text_entry', 'online_upload'],
    published: true,
    workflowState: 'published',
    gradingPeriodId: '1',
    assignmentGroupPosition: 1,
    sortableName: 'assignment 1',
    sortableDueDate: 20230704,
    inClosedGradingPeriod: false,
  },
  {
    id: '2',
    assignmentGroupId: '2',
    allowedAttempts: 2,
    anonymousGrading: false,
    anonymizeStudents: false,
    courseId: '2',
    dueAt: null,
    gradeGroupStudentsIndividually: false,
    gradesPublished: false,
    gradingType: 'points',
    htmlUrl: '/courses/1/assignments/2',
    moderatedGrading: false,
    hasSubmittedSubmissions: false,
    name: 'Assignment 2',
    omitFromFinalGrade: false,
    pointsPossible: 10,
    postManually: false,
    submissionTypes: ['online_text_entry', 'online_upload'],
    published: true,
    workflowState: 'published',
    gradingPeriodId: '2',
    assignmentGroupPosition: 2,
    sortableName: 'assignment 2',
    sortableDueDate: 20230705,
    inClosedGradingPeriod: false,
  },
  {
    id: '3',
    assignmentGroupId: '3',
    allowedAttempts: 3,
    anonymousGrading: false,
    anonymizeStudents: false,
    courseId: '3',
    dueAt: null,
    gradeGroupStudentsIndividually: false,
    gradesPublished: false,
    gradingType: 'points',
    htmlUrl: '/courses/1/assignments/3',
    moderatedGrading: false,
    hasSubmittedSubmissions: false,
    name: 'Assignment 3',
    omitFromFinalGrade: false,
    pointsPossible: 10,
    postManually: false,
    submissionTypes: ['online_text_entry', 'online_upload'],
    published: true,
    workflowState: 'published',
    gradingPeriodId: '3',
    assignmentGroupPosition: 3,
    sortableName: 'assignment 3',
    sortableDueDate: 20230705,
    inClosedGradingPeriod: false,
  },
]

export const defaultSortableStudents = [
  {
    id: '1',
    name: 'First Last',
    sortableName: 'Last, First',
    enrollments: {
      section: {
        name: '',
        id: '',
      },
    },
    email: '',
    loginId: '',
    sections: [],
    state: 'active',
  },
  {
    id: '2',
    name: 'First2 Last2',
    sortableName: 'Last2, First2',
    enrollments: {
      section: {
        name: '',
        id: '',
      },
    },
    email: '',
    loginId: '',
    sections: [],
    state: 'active',
  },
  {
    id: '3',
    name: 'First3 Last3',
    sortableName: 'Last3, First3',
    enrollments: {
      section: {
        name: '',
        id: '',
      },
    },
    email: '',
    loginId: '',
    sections: [],
    state: 'active',
  },
]

export function makeContentSelectionProps(
  props: Partial<ContentSelectionComponentProps> = {}
): ContentSelectionComponentProps {
  return {...defaultContentSelectionProps, ...props}
}
