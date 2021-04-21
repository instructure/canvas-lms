/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

export const Attachment = {
  fragment: gql`
    fragment Attachment on File {
      _id
      displayName
      id
      mimeClass
      url
      thumbnailUrl
    }
  `,

  shape: shape({
    _id: string,
    displayName: string,
    id: string,
    mimeClass: string,
    url: string,
    thumbnailUrl: string
  })
}

export const DefaultMocks = {
  File: () => ({
    displayName: 'testing.csv',
    mimeClass: 'file'
  })
}
