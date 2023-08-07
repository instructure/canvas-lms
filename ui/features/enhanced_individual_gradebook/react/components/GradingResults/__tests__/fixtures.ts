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

import {GradingResultsComponentProps} from '..'
import {GradebookSortOrder} from '../../../../types'

export const gradingResultsDefaultProps: GradingResultsComponentProps = {
  assignment: {
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
  },
  courseId: '1',
  currentStudent: {
    enrollments: [],
    id: 'bob9977',
    loginId: 'bob_9977',
    name: 'Bob Lee',
    hiddenName: 'Bob',
    sortableName: 'Lee, Bob',
  },
  studentSubmissions: [
    {
      grade: '95',
      id: '1',
      score: 95,
      enteredScore: 95,
      assignmentId: '1',
      submissionType: 'Online',
      proxySubmitter: 'teacher1',
      submittedAt: new Date('2023-08-10T08:00:00Z'),
      state: 'Graded',
      excused: false,
      late: false,
      latePolicyStatus: '',
      missing: false,
      userId: 'bob9977',
      redoRequest: false,
      cachedDueDate: '2023-08-09T23:59:59Z',
      gradingPeriodId: '',
      deductedPoints: 0,
      enteredGrade: '95',
    },
  ],
  gradebookOptions: {
    sortOrder: GradebookSortOrder.Alphabetical,
    changeGradeUrl: 'testUrl',
    customOptions: {
      includeUngradedAssignments: false,
      hideStudentNames: false,
      showConcludedEnrollments: false,
      showNotesColumn: false,
      showTotalGradeAsPoints: false,
      allowFinalGradeOverride: false,
    },
    gradingStandardScalingFactor: 1,
    gradingStandardPointsBased: false,
    pointsBasedGradingSchemesFeatureEnabled: false,
  },
  loadingStudent: false,
  currentStudentHiddenName: '',
  onSubmissionSaved: () => {},
}
