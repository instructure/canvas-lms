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
import gql from 'graphql-tag'
import {shape, string} from 'prop-types'
import {
  SubmissionInterface,
  DefaultMocks as SubmissionInterfaceDefaultMocks
} from './SubmissionInterface'

export const Submission = {
  fragment: gql`
    fragment Submission on Submission {
      ...SubmissionInterface
      _id
      id
    }
    ${SubmissionInterface.fragment}
  `,

  shape: shape({
    ...SubmissionInterface.shape.propTypes,
    _id: string.isRequired,
    id: string.isRequired
  })
}

export const DefaultMocks = {
  Submission: () => ({
    ...SubmissionInterfaceDefaultMocks.SubmissionInterface(),
    _id: '1',
    id: '1'
  })
}

export const SubmissionMocks = {
  onlineUploadReadyToSubmit: {
    submissionDraft: {
      activeSubmissionType: 'online_upload',
      attachments: [{_id: '1'}],
      meetsAssignmentCriteria: true,
      meetsUploadCriteria: true
    }
  },

  graded: {
    attempt: 1,
    deductedPoints: 0,
    enteredGrade: '8',
    grade: '8',
    gradingStatus: 'graded',
    state: 'graded',
    submissionStatus: 'submitted',
    submittedAt: new Date().toISOString()
  },

  submitted: {
    attempt: 1,
    gradingStatus: 'needs_grading',
    state: 'submitted',
    submissionStatus: 'submitted',
    submittedAt: new Date().toISOString()
  }
}
