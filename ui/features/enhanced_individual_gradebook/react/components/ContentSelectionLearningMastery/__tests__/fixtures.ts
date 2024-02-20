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
  students: [],
  outcomes: [],
  selectedStudentId: null,
  selectedOutcomeId: null,
  gradebookOptions: defaultGradebookOptions,
  onStudentChange: () => {},
  onOutcomeChange: () => {},
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

export const defaultOutcomes = [
  {
    id: '1',
    assessd: false,
    calculationInt: 65,
    calculationMethod: 'decaying_average',
    description: 'This is a test outcome',
    displayName: 'Test Outcome',
    masteryPoints: 3,
    pointsPossible: 5,
    title: 'JPLO',
    ratings: [
      {
        color: null,
        description: 'Excellent',
        mastery: false,
        points: 5,
      },
      {
        color: null,
        description: 'Very good',
        mastery: false,
        points: 4,
      },
      {
        color: null,
        description: 'Meets Expectations',
        mastery: false,
        points: 3,
      },
      {
        color: null,
        description: 'Does Not Meet Expectations',
        mastery: false,
        points: 0,
      },
    ],
  },
  {
    id: '2',
    calculationMethod: 'decaying_average',
    calculationInt: 65,
    assessed: false,
    canEdit: true,
    contextId: '1',
    contextType: 'Course',
    createdAt: '2024-02-26T15:46:19-07:00',
    displayName: 'Algorithm',
    masteryPoints: 8,
    pointsPossible: 15,
    title: 'MATH.ALGO',
    ratings: [
      {
        color: null,
        description: 'Know everything',
        mastery: false,
        points: 15,
      },
      {
        color: null,
        description: 'Knows almost everything',
        mastery: false,
        points: 10,
      },
      {
        color: null,
        description: 'Knows things',
        mastery: false,
        points: 8,
      },
      {
        color: null,
        description: 'Knows something',
        mastery: false,
        points: 4,
      },
      {
        color: null,
        description: 'Does Not Meet Expectations',
        mastery: false,
        points: 0,
      },
    ],
  },
]

export function makeContentSelectionProps(
  props: Partial<ContentSelectionComponentProps> = {}
): ContentSelectionComponentProps {
  return {...defaultContentSelectionProps, ...props}
}
