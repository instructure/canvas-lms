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
import {arrayOf, bool, number, oneOf, shape, string} from 'prop-types'
import gql from 'graphql-tag'
import {MediaObject} from './MediaObject'
import {SubmissionDraft} from './SubmissionDraft'
import {SubmissionFile} from './File'

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
      extraAttempts
      grade
      gradeHidden
      gradingStatus
      latePolicyStatus
      mediaObject {
        ...MediaObject
      }
      state
      submissionDraft {
        ...SubmissionDraft
      }
      submissionStatus
      submittedAt
      unreadCommentCount
      url
    }
    ${MediaObject.fragment}
    ${SubmissionFile.fragment}
    ${SubmissionDraft.fragment}
  `,

  shape: shape({
    attachment: SubmissionFile.shape,
    attachments: arrayOf(SubmissionFile.shape),
    attempt: number.isRequired,
    body: string,
    deductedPoints: number,
    enteredGrade: string,
    extraAttempts: number,
    grade: string,
    gradeHidden: bool.isRequired,
    gradingStatus: oneOf(['needs_grading', 'excused', 'needs_review', 'graded']),
    latePolicyStatus: string,
    mediaObject: MediaObject.shape,
    state: string.isRequired,
    submissionDraft: SubmissionDraft.shape,
    submissionStatus: string,
    submittedAt: string,
    unreadCommentCount: number.isRequired,
    url: string
  })
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
    latePolicyStatus: null,
    mediaObject: null,
    state: 'unsubmitted',
    submissionDraft: null,
    submissionStatus: 'unsubmitted',
    submittedAt: null,
    unreadCommentCount: 0,
    url: null
  })
}
