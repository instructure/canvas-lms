/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {arrayOf, bool, number, oneOf, shape, string, object} from 'prop-types'
import gql from 'graphql-tag'
import {MediaObject} from './MediaObject'
import {SubmissionDraft} from './SubmissionDraft'
import {SubmissionFile} from './File'
import {AssessmentRequest} from './AssessmentRequest'
import {TurnitinData} from './TurnitinData'

export const SubmissionInterface = {
  fragment: gql`
    fragment SubmissionInterface on SubmissionInterface {
      attachment {
        # this refers to the screenshot of the submission if it is a url submission
        ...SubmissionFile
      }
      attachments {
        ...SubmissionFile
      }
      attempt
      body
      deductedPoints
      enteredGrade
      gradedAnonymously
      hideGradeFromStudent
      extraAttempts
      grade
      gradeHidden
      gradingStatus
      customGradeStatus
      latePolicyStatus
      mediaObject {
        ...MediaObject
      }
      originalityData
      proxySubmitter
      resourceLinkLookupUuid
      score
      state
      sticker
      submissionDraft {
        ...SubmissionDraft
      }
      submissionStatus
      submissionType
      submittedAt
      turnitinData {
        ...TurnitinData
      }
      feedbackForCurrentAttempt
      unreadCommentCount
      url
      assignedAssessments {
        ...AssessmentRequest
      }
    }
    ${MediaObject.fragment}
    ${SubmissionFile.fragment}
    ${SubmissionDraft.fragment}
    ${AssessmentRequest.fragment}
    ${TurnitinData.fragment}
  `,

  shape: shape({
    attachment: SubmissionFile.shape,
    attachments: arrayOf(SubmissionFile.shape),
    attempt: number.isRequired,
    body: string,
    customGradeStatus: string,
    deductedPoints: number,
    enteredGrade: string,
    extraAttempts: number,
    grade: string,
    gradeHidden: bool.isRequired,
    gradingStatus: oneOf(['needs_grading', 'excused', 'needs_review', 'graded']),
    gradedAnonymously: bool,
    hideGradeFromStudent: bool,
    latePolicyStatus: string,
    mediaObject: MediaObject.shape,
    originalityData: object.shape,
    resourceLinkLookupUuid: string,
    state: string.isRequired,
    submissionDraft: SubmissionDraft.shape,
    submissionStatus: string,
    submissionType: string,
    submittedAt: string,
    turnitinData: arrayOf(TurnitinData.shape),
    feedbackForCurrentAttempt: bool.isRequired,
    unreadCommentCount: number.isRequired,
    url: string,
    assignedAssessments: arrayOf(AssessmentRequest.shape),
  }),
}

export const DefaultMocks = {
  SubmissionInterface: () => ({
    attachment: null,
    attachments: () => [],
    attempt: 0,
    body: null,
    deductedPoints: null,
    enteredGrade: null,
    extraAttempts: null,
    gradeHidden: false,
    grade: null,
    gradingStatus: null,
    gradedAnonymously: false,
    hideGradeFromStudent: false,
    latePolicyStatus: null,
    mediaObject: null,
    originalityData: null,
    resourceLinkLookupUuid: null,
    state: 'unsubmitted',
    customGradeStatus: null,
    sticker: null,
    submissionDraft: null,
    submissionStatus: 'unsubmitted',
    submissionType: null,
    submittedAt: null,
    turnitinData: null,
    feedbackForCurrentAttempt: false,
    unreadCommentCount: 0,
    url: null,
    assignedAssessments: () => [],
  }),
}
