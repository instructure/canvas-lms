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
import {number, shape, string} from 'prop-types'

export const ExternalTool = {
  fragment: gql`
    fragment ExternalTool on ExternalTool {
      _id
      createdAt
      description
      name
      settings {
        homeworkSubmission {
          canvasIconClass
          iconUrl
          messageType
          text
          url
        }
        iconUrl
        selectionHeight
        selectionWidth
        text
      }
      state
      updatedAt
      url
    }
  `,

  shape: shape({
    _id: string,
    createdAt: string,
    description: string,
    name: string,
    settings: shape({
      homeworkSubmission: shape({
        canvasIconClass: string,
        iconUrl: string,
        messageType: string,
        text: string,
        url: string
      }),
      iconUrl: string,
      selectionHeight: number,
      selectionWidth: number,
      text: string
    }),
    state: string,
    updatedAt: string,
    url: string
  })
}

export const ExternalToolDefaultMocks = {
  ExternalTool: () => ({
    _id: '1',
    name: 'external tool',
    settings: {
      homeworkSubmission: {
        canvasIconClass: 'icon-lti',
        iconUrl: 'http://lti.com/icon.png',
        messageType: 'ContentItemSelectionRequest',
        text: 'homework_submission Text',
        url: 'http://lti.com/messages/content-item'
      }
    },
    state: 'public'
  })
}
