/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React from 'react'
import SubmissionTray from './SubmissionTray'

export default {
  title: 'Examples/Evaluate/Gradebook/SubmissionTray',
  component: SubmissionTray,
  args: {
    colors: {
      late: '#FEF7E5',
      missing: '#F99',
      excused: '#E5F3FC',
    },
    editedCommentId: null,
    editSubmissionComment() {},
    enterGradesAs: 'points',
    gradingDisabled: false,
    gradingScheme: [
      ['A', 0.9],
      ['B+', 0.85],
      ['B', 0.8],
      ['B-', 0.75],
    ],
    locale: 'en',
    onAnonymousSpeedGraderClick() {},
    onGradeSubmission() {},
    onRequestClose() {},
    onClose() {},
    showSimilarityScore: true,
    submissionUpdating: false,
    isOpen: true,
    courseId: '1',
    currentUserId: '2',
    speedGraderEnabled: true,
    student: {
      id: '27',
      name: 'Jane Doe',
      gradesUrl: '',
      isConcluded: false,
    },
    submission: {
      assignmentId: '30',
      enteredGrade: '10',
      enteredScore: 10,
      excused: false,
      grade: '7',
      gradedAt: new Date().toISOString(),
      hasPostableComments: false,
      id: '2501',
      late: true,
      missing: false,
      pointsDeducted: 3,
      postedAt: new Date().toISOString(),
      score: 7,
      secondsLate: 50000,
      submissionType: 'online_text_entry',
      userId: '27',
      workflowState: 'graded',
    },
    updateSubmission() {},
    updateSubmissionComment() {},
    assignment: {
      anonymizeStudents: false,
      courseId: '1',
      name: 'Book Report',
      gradingType: 'points',
      htmlUrl: '',
      id: '30',
      moderatedGrading: false,
      muted: false,
      pointsPossible: 10,
      postManually: false,
      published: true,
    },
    isFirstAssignment: false,
    isLastAssignment: false,
    selectNextAssignment() {},
    selectPreviousAssignment() {},
    isFirstStudent: false,
    isLastStudent: false,
    selectNextStudent() {},
    selectPreviousStudent() {},
    submissionCommentsLoaded: true,
    createSubmissionComment() {},
    deleteSubmissionComment() {},
    processing: false,
    setProcessing() {},
    submissionComments: [],
    isInOtherGradingPeriod: false,
    isInClosedGradingPeriod: false,
    isInNoGradingPeriod: false,
    isNotCountedForScore: false,
  },
}

const Template = args => <SubmissionTray {...args} />

export const Default = Template.bind({})
