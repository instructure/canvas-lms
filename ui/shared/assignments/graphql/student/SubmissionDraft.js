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
import {arrayOf, bool, shape, string} from 'prop-types'
import gql from 'graphql-tag'
import {MediaObject} from './MediaObject'
import {SubmissionDraftFile} from './File'

export const SubmissionDraft = {
  fragment: gql`
    fragment SubmissionDraft on SubmissionDraft {
      _id
      activeSubmissionType
      attachments {
        ...SubmissionDraftFile
      }
      body
      mediaObject {
        ...MediaObject
      }
      meetsMediaRecordingCriteria
      meetsAssignmentCriteria
      meetsTextEntryCriteria
      meetsUploadCriteria
      meetsUrlCriteria
      url
    }
    ${MediaObject.fragment}
    ${SubmissionDraftFile.fragment}
  `,

  shape: shape({
    _id: string,
    activeSubmissionType: string,
    attachments: arrayOf(SubmissionDraftFile.shape),
    body: string,
    mediaObject: MediaObject.shape,
    meetsMediaRecordingCriteria: bool.isRequired,
    meetsAssignmentCriteria: bool.isRequired,
    meetsTextEntryCriteria: bool.isRequired,
    meetsUploadCriteria: bool.isRequired,
    meetsUrlCriteria: bool.isRequired,
    url: string
  })
}

export const DefaultMocks = {
  SubmissionDraft: () => ({
    activeSubmissionType: null,
    attachments: () => [],
    body: null,
    mediaObject: null,
    meetsMediaRecordingCriteria: false,
    meetsAssignmentCriteria: false,
    meetsTextEntryCriteria: false,
    meetsUploadCriteria: false,
    meetsUrlCriteria: false,
    url: null
  })
}
