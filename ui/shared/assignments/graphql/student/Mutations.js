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

import {Error} from './Error'
import {Submission} from './Submission'
import {SubmissionComment} from './SubmissionComment'
import {SubmissionDraft} from './SubmissionDraft'

export const DefaultMocks = {
  CreateSubmissionCommentPayload: () => ({errors: null}),
  CreateSubmissionDraftPayload: () => ({errors: null}),
  CreateSubmissionPayload: () => ({errors: null}),
  DeleteSubmissionDraftPayload: () => ({errors: null}),
  MarkSubmissionCommentsReadPayload: () => ({errors: null}),
}

export const CREATE_SUBMISSION = gql`
  mutation CreateSubmission(
    $assignmentLid: ID!
    $submissionID: ID!
    $type: OnlineSubmissionType!
    $body: String
    $fileIds: [ID!]
    $mediaId: ID
    $resourceLinkLookupUuid: String
    $url: String
    $studentId: ID
  ) {
    createSubmission(
      input: {
        assignmentId: $assignmentLid
        submissionType: $type
        body: $body
        fileIds: $fileIds
        mediaId: $mediaId
        resourceLinkLookupUuid: $resourceLinkLookupUuid
        url: $url
        studentId: $studentId
      }
    ) {
      submission {
        ...Submission
      }
      errors {
        ...Error
      }
    }
  }
  ${Error.fragment}
  ${Submission.fragment}
`

export const CREATE_SUBMISSION_COMMENT = gql`
  mutation CreateSubmissionComment(
    $id: ID!
    $submissionAttempt: Int!
    $comment: String!
    $fileIds: [ID!]
    $mediaObjectId: ID
    $mediaObjectType: String
    $reviewerSubmissionId: ID
  ) {
    createSubmissionComment(
      input: {
        submissionId: $id
        attempt: $submissionAttempt
        comment: $comment
        fileIds: $fileIds
        mediaObjectId: $mediaObjectId
        mediaObjectType: $mediaObjectType
        reviewerSubmissionId: $reviewerSubmissionId
      }
    ) {
      submissionComment {
        ...SubmissionComment
      }
      errors {
        ...Error
      }
    }
  }
  ${Error.fragment}
  ${SubmissionComment.fragment}
`

export const CREATE_SUBMISSION_DRAFT = gql`
  mutation CreateSubmissionDraft(
    $id: ID!
    $activeSubmissionType: DraftableSubmissionType!
    $attempt: Int!
    $body: String
    $externalToolId: ID
    $fileIds: [ID!]
    $ltiLaunchUrl: String
    $mediaId: ID
    $resourceLinkLookupUuid: String
    $url: String
  ) {
    createSubmissionDraft(
      input: {
        submissionId: $id
        activeSubmissionType: $activeSubmissionType
        attempt: $attempt
        body: $body
        externalToolId: $externalToolId
        fileIds: $fileIds
        ltiLaunchUrl: $ltiLaunchUrl
        mediaId: $mediaId
        resourceLinkLookupUuid: $resourceLinkLookupUuid
        url: $url
      }
    ) {
      submissionDraft {
        ...SubmissionDraft
      }
      errors {
        ...Error
      }
    }
  }
  ${Error.fragment}
  ${SubmissionDraft.fragment}
`

export const MARK_SUBMISSION_COMMENT_READ = gql`
  mutation MarkSubmissionCommentsRead($commentIds: [ID!]!, $submissionId: ID!) {
    markSubmissionCommentsRead(
      input: {submissionCommentIds: $commentIds, submissionId: $submissionId}
    ) {
      submissionComments {
        _id
      }
      errors {
        ...Error
      }
    }
  }
  ${Error.fragment}
`

export const SET_MODULE_ITEM_COMPLETION = gql`
  mutation SetModuleItemCompletion($moduleId: ID!, $itemId: ID!, $done: Boolean!) {
    setModuleItemCompletion(input: {moduleId: $moduleId, itemId: $itemId, done: $done}) {
      moduleItem {
        _id
      }
      errors {
        ...Error
      }
    }
  }
  ${Error.fragment}
`

export const DELETE_SUBMISSION_DRAFT = gql`
  mutation DeleteSubmissionDraft($submissionId: ID!) {
    deleteSubmissionDraft(input: {submissionId: $submissionId}) {
      submissionDraftIds
      errors {
        ...Error
      }
    }
  }
  ${Error.fragment}
`
