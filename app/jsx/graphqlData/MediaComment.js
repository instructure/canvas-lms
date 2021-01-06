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
import {shape, string, bool} from 'prop-types'
import {MediaSource} from './MediaSource'
import {MediaTrack} from './MediaTrack'

export const MediaComment = {
  fragment: gql`
    fragment MediaComment on MediaObject {
      _id
      id
      title
      canAddCaptions
      mediaSources {
        ...MediaSource
      }
      mediaTracks {
        ...MediaTrack
      }
    }
    ${MediaSource.fragment}
    ${MediaTrack.fragment}
  `,

  shape: shape({
    _id: string,
    id: string,
    title: string,
    canAddCaptions: bool,
    mediaSources: MediaSource.shape,
    mediaTracks: MediaTrack.shape
  })
}

export const DefaultMocks = {
  MediaComment: () => ({
    title: 'Test Media Comment Video',
    canAddCaptions: true
  })
}
