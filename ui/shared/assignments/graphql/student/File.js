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

// TODO - rename everything in student view from attachment (database name) to
//        file (name exposed through graphql)

export const SubmissionDraftFile = {
  fragment: gql`
    fragment SubmissionDraftFile on File {
      _id
      displayName
      mimeClass
      thumbnailUrl
    }
  `,

  shape: shape({
    _id: string,
    displayName: string,
    mimeClass: string,
    thumbnailUrl: string,
  }),
}

export const SubmissionFile = {
  fragment: gql`
    fragment SubmissionFile on File {
      _id
      displayName
      id
      mimeClass
      submissionPreviewUrl(submissionId: $submissionID)
      size
      thumbnailUrl
      url
    }
  `,

  shape: shape({
    _id: string,
    displayName: string,
    id: string,
    mimeClass: string,
    submissionPreviewUrl: string,
    size: string,
    thumbnailUrl: string,
    url: string,
  }),
}

export const SubmissionCommentFile = {
  fragment: gql`
    fragment SubmissionCommentFile on File {
      _id
      displayName
      id
      mimeClass
      url
    }
  `,

  shape: shape({
    _id: string,
    displayName: string,
    id: string,
    mimeClass: string,
    url: string,
  }),
}

export const DefaultMocks = {
  File: () => ({
    mimeClass: 'image',
  }),
}
