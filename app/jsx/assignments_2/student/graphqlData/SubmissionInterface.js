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
import {arrayOf, bool, number, shape, string} from 'prop-types'
import gql from 'graphql-tag'
import {SubmissionDraft} from './SubmissionDraft'
import {SubmissionFile} from './File'

export const SubmissionInterface = {
  fragment: gql`
    fragment SubmissionInterface on SubmissionInterface {
      attachments {
        ...SubmissionFile
      }
      attempt
      body
      deductedPoints
      enteredGrade
      grade
      gradeHidden
      gradingStatus
      latePolicyStatus
      state
      submissionDraft {
        ...SubmissionDraft
      }
      submissionStatus
      submittedAt
      unreadCommentCount
      url
    }
    ${SubmissionFile.fragment}
    ${SubmissionDraft.fragment}
  `,

  shape: shape({
    attachments: arrayOf(SubmissionFile.shape),
    attempt: number.isRequired,
    body: string,
    deductedPoints: number,
    enteredGrade: string,
    grade: string,
    gradeHidden: bool.isRequired,
    gradingStatus: string,
    latePolicyStatus: string,
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
    attachments: () => [],
    attempt: 0,
    body: null,
    deductedPoints: null,
    enteredGrade: null,
    gradeHidden: false,
    grade: null,
    gradingStatus: null,
    latePolicyStatus: null,
    state: 'unsubmitted',
    submissionDraft: null,
    submissionStatus: 'unsubmitted',
    submittedAt: null,
    unreadCommentCount: 0,
    url: null
  })
}
